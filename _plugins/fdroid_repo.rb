# Dieses Plugin repliziert die Logik der ehemaligen Next.js-Implementierung (pages/index.tsx).
# Es liest die von `fdroidserver` generierte `public/repo/index.html`, entfernt den
# HTML-Wrapper (DOCTYPE/html/head/body) und passt die relativen Bild- und Datei-Pfade
# an den `repo_base`-Pfad an (entspricht NEXT_PUBLIC_REPO_BASE).
#
# Das Ergebnis wird in `site.data.fdroid_repo_markup` gespeichert und im Layout
# ausgegeben. Alles wird zur Build-Zeit ausgeführt, damit die Seite statisch bleibt.

module FdroidRepo
  class Generator < Jekyll::Generator
    def generate(site)
      # Falls keine Umgebungsvariable gesetzt ist, wird der Wert aus _config.yml genutzt
      repo_base = ENV.fetch('REPO_BASE', site.config['repo_base'] || '/fdroid/repo')

      file_path = File.join(site.source, 'public', 'repo', 'index.html')
      markup = ''

      begin
        if File.exist?(file_path)
          markup = File.read(file_path, encoding: 'utf-8')

          # HTML-Wrapper entfernen (DOCTYPE, html, head und body)
          markup = markup
                    .gsub(/<!DOCTYPE[^>]*>/i, '')
                    .gsub(%r{</?html[^>]*>}i, '')
                    .gsub(%r{<head[\s\S]*?</head>}i, '')
                    .gsub(%r{</?body[^>]*>}i, '')

          # Alle relativen Bild- und Datei-Pfade für QR-Codes, Icons & Grafiken anpassen
          markup = markup
                    .gsub(/src=["']\.\/([^"']+)["']/, "src=\"#{repo_base}/\\1\"")
                    .gsub(/src=["'](?!https?:|\/)([^"']+)["']/, "src=\"#{repo_base}/\\1\"")
                    .gsub(/href=["']\.\/([^"']+)["']/, "href=\"#{repo_base}/\\1\"")
        else
          markup = "<p style=\"padding: 20px; font-family: sans-serif;\">Datei nicht gefunden unter: #{file_path}</p>"
        end
      rescue StandardError => e
        markup = "<p style=\"padding: 20px; font-family: sans-serif;\">Fehler beim Laden: #{e.message}</p>"
      end

      site.data['fdroid_repo_markup'] = markup
      site.config['repo_base'] = repo_base
    end
  end
end
