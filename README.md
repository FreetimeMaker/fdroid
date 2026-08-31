# fdroid
This repository hosts an [F-Droid](https://f-droid.org/) repo for my apps. This allows you to install and update apps very easily.

### Apps

<!-- This table is auto-generated. Do not edit -->
| Icon | Name | Description | Version |
| --- | --- | --- | --- |
| <a href="https://github.com/FreetimeMaker/Dualist"><img src="repo/icons/Dualist.png" alt="Dualist icon" width="36px" height="36px"></a> | [**Dualist**](https://github.com/FreetimeMaker/Dualist) | Modern, adaptive, and offline-first To-Do List app. | 1.1.7 (9) |
| <a href="https://github.com/FreetimeMaker/GeoWeather"><img src="repo/icons/GeoWeather.png" alt="GeoWeather icon" width="36px" height="36px"></a> | [**GeoWeather**](https://github.com/FreetimeMaker/GeoWeather) | Modern weather app with 16-day forecast for multiple cities | 2.3.0 (65) |
| <a href="https://github.com/FreetimeMaker/SuperSMP-Companion-App"><img src="repo/icons/SSMPC.png" alt="SuperSMP Companion icon" width="36px" height="36px"></a> | [**SuperSMP Companion**](https://github.com/FreetimeMaker/SuperSMP-Companion-App) | Vote, shop &amp; explore SuperSMP anywhere! Companion app for server features | 1.6.0 (20) |
<!-- end apps table -->

### How to use
1. At first, you should [install the F-Droid app](https://f-droid.org/), it's an alternative app store for Android.
2. Now you can copy the following [link](https://fdroid.free-time.me/repo), then add this repository to your F-Droid client:

    ```
    https://fdroid.free-time.me/repo
    ```

    Alternatively, you can also scan this QR code:

    <p align="center">
      <img src="/repo/index.png?raw=true" alt="F-Droid repo QR code"/>
    </p>

3. Open the link in F-Droid. It will ask you to add the repository. Everything should already be filled in correctly, so just press "OK".
4. You can now install my apps, e.g. start by searching for "Notality" in the F-Droid client.

Please note that some apps published here might contain [Anti-Features](https://f-droid.org/en/docs/Anti-Features/). If you can't find an app by searching for it, you can go to settings and enable "Include anti-feature apps".

### Website

The site is built with [Jekyll](https://jekyllrb.com/). The `index.html` generated
by `fdroidserver` (in `repo/`) is served **directly and unmodified** at `/repo/`,
together with its relative assets (`index.css`, `index.png`, `icons/`, ...). No
wrapper, layout or plugin is needed.

To run it locally:

```bash
bundle install
bundle exec jekyll serve --livereload
```

To build the static site into `_site/`:

```bash
bundle exec jekyll build
```

The site is deployed with **GitHub Pages** (custom domain via `CNAME`). A GitHub
Actions workflow (`.github/workflows/jekyll.yml`) builds Jekyll and publishes
`_site/` automatically on every push to `main`.

Note: This is a Jekyll project now. **Vercel** cannot build it (it expected the
previous Next.js setup with `package.json`/`pages/`), so Vercel should be disabled
for the domain; GitHub Pages is the host.

### [License](LICENSE)
The license is for the files in this repository, *except* those in the `fdroid` directory. These files *might* be licensed differently; you can use an F-Droid client to get the details for each app.
