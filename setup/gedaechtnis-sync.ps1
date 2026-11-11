<#
Synchronisiert das Obsidian-Gedächtnis (ein Git-Repo) mit GitHub.
  -Modus pull : neuesten Stand holen (SessionStart)
  -Modus push : Änderungen committen und hochladen (Stop, läuft im Hintergrund)
Bricht nie eine Claude-Sitzung ab: Fehler landen nur in sync.log neben diesem Skript.
#>
param(
  [ValidateSet('pull','push')][string]$Modus = 'push',
  [string]$Ordner = "$HOME\.claude\projects\C--Users-Gutachten-Plus-Architekt\memory"
)
$ErrorActionPreference = 'SilentlyContinue'
$log = Join-Path $PSScriptRoot 'sync.log'
$git = 'C:\Program Files\Git\cmd\git.exe'
if (-not (Test-Path $git)) { $git = 'git' }
$env:GIT_TERMINAL_PROMPT = '0'
function Log($t) { Add-Content -Path $log -Value ("{0:yyyy-MM-dd HH:mm:ss} [{1}] {2}" -f (Get-Date), $Modus, $t) -Encoding UTF8 }
function G { & $git -C $Ordner @args 2>&1 }

if (-not (Test-Path (Join-Path $Ordner '.git'))) { Log "kein Git-Repo: $Ordner"; exit 0 }
if (-not (G remote)) { Log 'kein Remote eingerichtet'; exit 0 }
# Falls ein früherer Lauf mitten im Rebase hängen geblieben ist
if (Test-Path (Join-Path $Ordner '.git\rebase-merge')) { G rebase --abort | Out-Null; Log 'hängenden Rebase abgebrochen' }

if ($Modus -eq 'push') {
  G add -A | Out-Null
  if (G status --porcelain) {
    G commit -q -m ("Gedächtnis-Sync {0:yyyy-MM-dd HH:mm} ({1})" -f (Get-Date), $env:COMPUTERNAME) | Out-Null
  }
}
$r = G pull -q --rebase --autostash origin main
if ($LASTEXITCODE -ne 0) {
  G rebase --abort | Out-Null
  Log "pull fehlgeschlagen (Konflikt oder offline): $r"
  exit 0
}
if ($Modus -eq 'push') {
  $ahead = G rev-list --count origin/main..HEAD
  if ([int]$ahead -gt 0) {
    $r = G push -q origin HEAD:main
    if ($LASTEXITCODE -ne 0) { Log "push fehlgeschlagen: $r" } else { Log "gepusht ($ahead Commit(s))" }
  }
}
exit 0
