package fastlane

import (
    "fmt"
    "io/fs"
    "os"
    "path/filepath"
    "sort"
    "strings"
)

type ImportConfig struct {
    RepoDir   string
    Upstream  string
    ApkList   []string
    AAPTPath  string
}

func must(err error) {
    if err != nil {
        panic(err)
    }
}

func copyFile(src, dst string) error {
    data, err := os.ReadFile(src)
    if err != nil {
        return err
    }
    return os.WriteFile(dst, data, 0o644)
}

func copyDir(src, dst string) error {
    return filepath.Walk(src, func(path string, info fs.FileInfo, err error) error {
        if err != nil {
            return err
        }
        rel, _ := filepath.Rel(src, path)
        target := filepath.Join(dst, rel)

        if info.IsDir() {
            return os.MkdirAll(target, 0o755)
        }

        if _, err := os.Stat(target); err == nil {
            return nil
        }

        return copyFile(path, target)
    })
}

func runAAPT(aapt, apk string) (string, error) {
    out, err := exec.Command(aapt, "dump", "badging", apk).Output()
    if err != nil {
        return "", err
    }
    for _, line := range strings.Split(string(out), "\n") {
        if strings.HasPrefix(line, "package: name=") {
            parts := strings.Split(line, "'")
            if len(parts) >= 2 {
                return parts[1], nil
            }
        }
    }
    return "", fmt.Errorf("appid not found")
}

func ImportFastlane(cfg ImportConfig) error {
    for _, apk := range cfg.ApkList {
        appid, err := runAAPT(cfg.AAPTPath, apk)
        if err != nil {
            fmt.Println("ERROR extracting appid:", err)
            continue
        }

        metaDir := filepath.Join(cfg.RepoDir, "..", "metadata", appid)
        fastlaneSrc := filepath.Join(cfg.Upstream, appid, "fastlane")
        fastlaneAndroid := filepath.Join(metaDir, "fastlane/metadata/android")

        os.MkdirAll(metaDir, 0o755)

        // Copy Fastlane metadata
        if _, err := os.Stat(fastlaneSrc); err == nil {
            must(copyDir(fastlaneSrc, filepath.Join(metaDir, "fastlane")))
        }

        // Descriptions
        os.Remove(filepath.Join(metaDir, "summary.txt"))
        os.Remove(filepath.Join(metaDir, "description.txt"))

        locales := []string{"en-US", "en-GB", "en", "default"}

        for _, loc := range locales {
            p := filepath.Join(fastlaneAndroid, loc, "short_description.txt")
            if _, err := os.Stat(p); err == nil {
                must(copyFile(p, filepath.Join(metaDir, "summary.txt")))
                break
            }
        }

        for _, loc := range locales {
            p := filepath.Join(fastlaneAndroid, loc, "full_description.txt")
            if _, err := os.Stat(p); err == nil {
                must(copyFile(p, filepath.Join(metaDir, "description.txt")))
                break
            }
        }

        // Changelogs
        changelogDir := filepath.Join(metaDir, "changelogs")
        os.MkdirAll(changelogDir, 0o755)

        var chosen string
        for _, loc := range locales {
            p := filepath.Join(fastlaneAndroid, loc, "changelogs")
            if st, err := os.Stat(p); err == nil && st.IsDir() {
                chosen = p
                break
            }
        }

        if chosen != "" {
            files, _ := filepath.Glob(filepath.Join(chosen, "*.txt"))
            for _, f := range files {
                base := filepath.Base(f)
                must(copyFile(f, filepath.Join(changelogDir, base)))
            }

            sort.Strings(files)
            if len(files) > 0 {
                latest := files[len(files)-1]
                must(copyFile(latest, filepath.Join(changelogDir, "default.txt")))
            }
        }

        // Screenshots
        var screenshotSrc string
        for _, loc := range locales {
            p := filepath.Join(fastlaneAndroid, loc, "images/phoneScreenshots")
            if st, err := os.Stat(p); err == nil && st.IsDir() {
                screenshotSrc = p
                break
            }
        }

        if screenshotSrc != "" {
            target := filepath.Join(metaDir, "en-US/phoneScreenshots")
            os.RemoveAll(target)
            os.MkdirAll(target, 0o755)

            entries, _ := os.ReadDir(screenshotSrc)
            counter := 1
            for _, e := range entries {
                if e.IsDir() {
                    continue
                }
                name := e.Name()
                if !strings.HasSuffix(name, ".png") &&
                    !strings.HasSuffix(name, ".jpg") &&
                    !strings.HasSuffix(name, ".jpeg") {
                    continue
                }
                ext := filepath.Ext(name)
                dst := filepath.Join(target, fmt.Sprintf("%d%s", counter, ext))
                must(copyFile(filepath.Join(screenshotSrc, name), dst))
                counter++
            }
        }

        // Icons
        resBase := filepath.Join(cfg.Upstream, appid, "app/src/main/res")
        densities := []string{
            "mipmap-xxxhdpi",
            "mipmap-xxhdpi",
            "mipmap-xhdpi",
            "mipmap-hdpi",
            "mipmap-mdpi",
        }

        for _, d := range densities {
            icon := filepath.Join(resBase, d, "ic_launcher.png")
            if _, err := os.Stat(icon); err == nil {
                must(copyFile(icon, filepath.Join(metaDir, "icon.png")))
                break
            }
        }
    }

    return nil
}
