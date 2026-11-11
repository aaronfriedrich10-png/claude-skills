# Werkbank Skills

Privater Plugin-Marktplatz fÃ¼r Claude Code mit 77 Skills in 8 Plugins.
Damit stehen dieselben Skills lokal, in Cloud-Sitzungen und in jedem Projekt zur VerfÃ¼gung.

## Einbinden

In `.claude/settings.json` eines Projekts:

```json
{
  "extraKnownMarketplaces": {
    "werkbank-skills": { "source": { "source": "github", "repo": "aaronfriedrich10-png/claude-skills" } }
  },
  "enabledPlugins": { "marketing-skills@werkbank-skills": true }
}
```

Oder interaktiv: `/plugin marketplace add aaronfriedrich10-png/claude-skills`.

## Plugins

- **karpathy-guidelines**: Arbeitsregeln gegen typische LLM-Codingfehler (Andrej Karpathy, via multica-ai)
- **marketing-skills**: 53 Marketing-Skills (Corey Haines): Copywriting, SEO, CRO, Pricing, Launch u. a.
- **obsidian-skills**: Obsidian-Skills (kepano): Markdown, Bases, CLI, JSON Canvas, Defuddle, Knap
- **excalidraw-diagram**: Excalidraw-Diagramme als JSON erzeugen und rendern (Cole Medin)
- **playwright-cli**: Browser-Automatisierung und Tests mit der Playwright CLI (Microsoft)
- **notebooklm**: Gemini Notebook / NotebookLM Ã¼ber die notebooklm-py CLI steuern

Herkunft und Lizenz stehen je Plugin in `SOURCE.md` und `LICENSE`.- **anthropic-skills-extra**: Offizielle Anthropic-Skills (Frontend-Design, Webapp-Tests, MCP-Builder, Web-Artifacts, Themes, Canvas u. a.)
- **rea-skills**: REA Reverse Engineering (braucht den REA-MCP-Server)

## Anderer PC einrichten

```powershell
git clone https://github.com/aaronfriedrich10-png/claude-skills.git
cd claude-skills
powershell -ExecutionPolicy Bypass -File setup\windows-einrichten.ps1
```

Installiert Git, Node.js, Python, GitHub CLI und Obsidian, die CLIs playwright-cli, ctx7, firecrawl und notebooklm,
und kopiert alle Skills nach `%USERPROFILE%\.claude\skills` (Vorhandenes bleibt unverändert).
Für die BIM-Werkbank-Prüfung zusätzlich WSL mit Ubuntu und darin `sudo bash setup/wsl-werkzeuge.sh`.

## Gemeinsames Gedächtnis

Das Obsidian-Gedächtnis liegt im privaten Repo `claude-gedaechtnis`. `setup\gedaechtnis-einrichten.ps1` klont es, kopiert `gedaechtnis-sync.ps1` nach `%USERPROFILE%\.claude\hooks` und trägt zwei Hooks ein (SessionStart: holen, Stop: committen und im Hintergrund hochladen). Mit `-ProjektOrdner` wird das Projekt per `autoMemoryDirectory` in `.claude\settings.local.json` auf das geklonte Gedächtnis umgelenkt.
