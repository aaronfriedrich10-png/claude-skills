# Werkbank Skills

Privater Plugin-Marktplatz fÃ¼r Claude Code mit 63 Skills in 6 Plugins.
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

Herkunft und Lizenz stehen je Plugin in `SOURCE.md` und `LICENSE`.