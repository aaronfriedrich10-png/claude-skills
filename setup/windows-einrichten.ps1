<#
Richtet einen weiteren Windows-PC für die Arbeit mit Claude Code und der BIM Werkbank ein.

Aufruf in einer normalen PowerShell im geklonten Repo claude-skills:
    powershell -ExecutionPolicy Bypass -File setup\windows-einrichten.ps1

Was passiert (bereits Vorhandenes wird übersprungen, nichts wird gelöscht oder überschrieben):
  1. Programme per winget: Git, Node.js LTS, Python 3.12, GitHub CLI, Obsidian
  2. Kommandozeilenwerkzeuge: playwright-cli, ctx7 (Context7), firecrawl, notebooklm
  3. Alle Skills aus plugins\*\skills nach %USERPROFILE%\.claude\skills kopieren
  4. Hinweise für WSL (Administratorrechte nötig) und die Anmeldungen ausgeben

Schalter:
  -OhneProgramme   Schritt 1 überspringen
  -OhneCLIs        Schritt 2 überspringen
  -SkillZiel <Pfad> anderer Zielordner für Schritt 3 (zum Testen)
#>
param(
  [switch]$OhneProgramme,
  [switch]$OhneCLIs,
  [string]$SkillZiel = "$HOME\.claude\skills"
)
$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $PSScriptRoot
function Schritt($t) { Write-Host "`n== $t" -ForegroundColor Cyan }
function PfadNeuLaden { $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User') }

if (-not $OhneProgramme) {
  Schritt 'Programme (winget)'
  $pakete = @(
    @{ id = 'Git.Git';             scope = '' },
    @{ id = 'OpenJS.NodeJS.LTS';   scope = '' },
    @{ id = 'Python.Python.3.12';  scope = '--scope user' },
    @{ id = 'GitHub.cli';          scope = '' },
    @{ id = 'Obsidian.Obsidian';   scope = '' }
  )
  foreach ($p in $pakete) {
    $vorhanden = winget list --id $p.id -e --accept-source-agreements 2>$null | Select-String -SimpleMatch $p.id
    if ($vorhanden) { Write-Host "vorhanden: $($p.id)"; continue }
    Write-Host "installiere: $($p.id)"
    $wargs = @('install','--id',$p.id,'-e','--silent','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
    if ($p.scope) { $wargs += $p.scope.Split(' ') }
    winget @wargs | Select-Object -Last 1
  }
  PfadNeuLaden
}

if (-not $OhneCLIs) {
  Schritt 'Kommandozeilenwerkzeuge'
  PfadNeuLaden
  if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm install -g @playwright/cli@0.1.24 ctx7@0.11.0 firecrawl-cli@1.29.0 --no-fund --no-audit 2>&1 | Select-Object -Last 1
  } else { Write-Warning 'npm fehlt – Node.js installieren und das Skript erneut starten.' }
  $py = Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'
  if (-not (Test-Path $py)) { $py = (Get-Command python -ErrorAction SilentlyContinue).Source }
  if ($py) {
    & $py -m pip install --user -q "notebooklm-py[browser]" 2>&1 | Select-Object -Last 1
    $scripts = & $py -c "import sysconfig;print(sysconfig.get_path('scripts','nt_user'))"
    Write-Host "notebooklm liegt in: $scripts (bei Bedarf zum PATH hinzufügen)"
  } else { Write-Warning 'Python fehlt – notebooklm übersprungen.' }
}

Schritt "Skills nach $SkillZiel"
New-Item -ItemType Directory -Force $SkillZiel | Out-Null
$neu = 0; $da = 0
foreach ($s in Get-ChildItem (Join-Path $repo 'plugins\*\skills\*') -Directory) {
  $ziel = Join-Path $SkillZiel $s.Name
  if (Test-Path $ziel) { $da++; continue }
  Copy-Item $s.FullName $ziel -Recurse
  $neu++
}
Write-Host "neu kopiert: $neu, schon vorhanden (unverändert): $da"

Schritt 'Noch von Hand'
Write-Host @'
- GitHub-Anmeldung für die CLI:       gh auth login --web
- BIM-Werkbank-Prüfung braucht WSL.   In einer ADMINISTRATOR-PowerShell:  wsl --install -d Ubuntu
  danach neu starten und in Ubuntu:   sudo bash setup/wsl-werkzeuge.sh   (aus diesem Repo)
- Projekt klonen:                     git clone https://github.com/aaronfriedrich10-png/architekturdigis.git
  Im Projekt danach einmal:           git config core.autocrlf false; git config core.eol lf; git rm -rq --cached .; git reset -q --hard
- Gemeinsames Gedächtnis + Sync-Hooks:  powershell -ExecutionPolicy Bypass -File setup\gedaechtnis-einrichten.ps1 -ProjektOrdner <Pfad zu architekturdigis>
- Plugins des claude.ai-Kontos gelten auf jedem PC automatisch, sobald Claude mit demselben Konto angemeldet ist.
- Firecrawl, Context7 und NotebookLM verlangen beim ersten Aufruf eine eigene Anmeldung bzw. einen API-Schlüssel.
'@
exit 0
