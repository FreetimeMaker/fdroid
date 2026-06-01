# F-Droid Automation Workflows

Dieses Verzeichnis enthält GitHub Actions Workflows zur automatischen Verwaltung und Aktualisierung des F-Droid-Repositories.

## Workflows

### 1. `update-fdroid-repo.yml` - README & Metadaten Update
**Zeitplan:** Täglich um 03:00 UTC (anpassbar)

Dieser Workflow:
- Liest die aktuelle `repo/index.xml`
- Aktualisiert die App-Tabelle im `README.md`
- Prüft Metadaten in `metadata/*.yml` auf Konsistenz
- Erstellt automatisch einen Pull Request bei Änderungen

### 2. `build-fdroid-repo.yml` - Repo Build & Signing
**Zeitplan:** Täglich um 04:00 UTC (anpassbar)

Dieser Workflow:
- Installiert `fdroid` und `apksigner`
- Führt `fdroid update` aus, um alle Repo-Indexe neu zu generieren und zu signieren
- Erstellt die signierten `index.xml`, `index-v1.json`, `index-v2.json`
- Committed die generierten Dateien ins Repository
- Aktualisiert anschließend das `README.md`

## Voraussetzungen

### GitHub Secrets konfigurieren

Beide Workflows benötigen Zugang zu den Keystore-Passwörtern. Diese müssen als **GitHub Secrets** konfiguriert werden:

1. Gehe zu: `Settings → Secrets and variables → Actions`
2. Erstelle folgende Secrets:
   - `FDROID_KEY_STORE_PASS` - Passwort für `keystore.p12`
   - `FDROID_KEY_PASS` - Passwort für den fdroid Key-Alias

Die Werte befinden sich in der `config.yml`:
```yaml
keystore: keystore.p12
keystorepass: KKKKKK      # ← FDROID_KEY_STORE_PASS
keypass: KKKKKK           # ← FDROID_KEY_PASS
repo_keyalias: fdroid
```

## Manuelle Ausführung

Beide Workflows können manuell ausgelöst werden:
1. Gehe zu `Actions` im GitHub-Repository
2. Wähle den Workflow aus
3. Klicke auf `Run workflow`

## Zeitplan anpassen

Die Cron-Syntax in den Workflows kann angepasst werden:

```yaml
on:
  schedule:
    - cron: '0 3 * * *'  # HH MM * * *
```

**Wichtig:** GitHub Actions nutzt UTC-Zeit.

## Logs überprüfen

Die Logs der Workflow-Ausführungen findest du unter:
`Actions → Workflow-Name → Letzter Run → Details`

## Fehlerbehebung

### Workflow schlägt fehl: "apksigner not found"
- Stelle sicher, dass die `config.yml` den richtigen Pfad zu `apksigner` enthält
- Der Workflow installiert `apksigner` automatisch über `apt-get`

### Workflow schlägt fehl: "Keystore password incorrect"
- Verifiziere die GitHub Secrets
- Die Passwörter müssen genau mit denen in `config.yml` übereinstimmen

### Keine automatischen Commits
- Überprüfe, dass das Repository keine Branch-Protection-Rules hat, die automatie Commits verhindern
- Oder nutze einen GitHub Token mit entsprechenden Rechten

## Weitere Informationen

- [F-Droid Server Dokumentation](https://f-droid.org/en/docs/Build_System/)
- [GitHub Actions Dokumentation](https://docs.github.com/en/actions)
