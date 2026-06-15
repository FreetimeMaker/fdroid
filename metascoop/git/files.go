package git

import (
	"fmt"
	"os/exec"
	"strings"
)

func GetChangedFileNames(repoPath string) (paths []string, err error) {
	// Verwende 'git status --porcelain', um eine umfassende Liste der geänderten Dateien zu erhalten,
	// einschließlich untracked, modifizierter und gestagter Dateien.
	cmd := exec.Command("git", "status", "--porcelain")
	cmd.Dir = repoPath

	output, err := cmd.Output()
	if err != nil {
		// Wenn der Befehl fehlschlägt, könnte es daran liegen, dass das Verzeichnis kein Git-Repository ist
		// oder andere Git-Fehler vorliegen. Die Ausgabe sollte zur Fehlerbehebung protokolliert werden.
		err = fmt.Errorf("running 'git status --porcelain': %w\nOutput:\n%s", err, string(output))
		return
	}

	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	for _, line := range lines {
		// Eine gültige Zeile in 'git status --porcelain' ist mindestens 4 Zeichen lang
		// (2 Status-Zeichen, 1 Leerzeichen, mindestens 1 Zeichen für den Pfad).
		if len(line) < 4 {
			continue
		}
		paths = append(paths, line[3:])
	}
	return
}
