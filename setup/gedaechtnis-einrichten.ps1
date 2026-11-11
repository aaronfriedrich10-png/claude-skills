<#
Richtet das gemeinsame Claude-Gedächtnis (privates Repo claude-gedaechtnis) auf diesem PC ein
und trägt die Hooks ein, die es automatisch mit GitHub synchronisieren.

Diesen PC (Gedächtnis liegt schon im Standardordner von Claude):
    powershell -ExecutionPolicy Bypass -File setup\gedaechtnis-einrichten.ps1 -Ordner "$HOME\.claude\projects\C--Users-Gutachten-Plus-Architekt\memory"

Weiterer PC (klont das Gedächtnis und lenkt das Projekt darauf um):
    powershell -ExecutionPolicy Bypass -File setup\gedaechtnis-einrichten.ps1 -ProjektOrdner "C:\Pfad\zu\architekturdigis"

Was passiert (nichts wird gelöscht; vorhandene Einträge bleiben):
  1. Gedächtnis-Repo nach -Ordner klonen, falls dort noch keins liegt
  2. gedaechtnis-sync.ps1 nach %USERPROFILE%\.claude\hooks kopieren
  3. In %USERPROFILE%\.claude\settings.json zwei Hooks ergänzen:
       SessionStart -> neuesten Stand holen, Stop -> committen und im Hintergrund hochladen
  4. Mit -ProjektOrdner: dort .claude\settings.local.json mit autoMemoryDirectory = -Ordner
#>
param(
  [string]$Ordner = "$HOME\claude-gedaechtnis",
  [string]$ProjektOrdner = '',
  [string]$Repo = 'https://github.com/aaronfriedrich10-png/claude-gedaechtnis.git',
  [string]$EinstellungsDatei = "$HOME\.claude\settings.json",
  [string]$HookZiel = "$HOME\.claude\hooks"
)
$ErrorActionPreference = 'Stop'
$git = 'C:\Program Files\Git\cmd\git.exe'; if (-not (Test-Path $git)) { $git = 'git' }
$node = (Get-Command node -ErrorAction SilentlyContinue).Source
if (-not $node) { throw 'Node.js fehlt – zuerst setup\windows-einrichten.ps1 ausführen.' }
$Ordner = [IO.Path]::GetFullPath($Ordner)

# 1. Gedächtnis-Repo
if (Test-Path (Join-Path $Ordner '.git')) {
  Write-Host "Gedächtnis-Repo vorhanden: $Ordner"
} elseif ((Test-Path $Ordner) -and (Get-ChildItem $Ordner -Force | Select-Object -First 1)) {
  throw "$Ordner existiert, ist aber kein Git-Repo und nicht leer. Bitte anderen -Ordner wählen."
} else {
  & $git clone -q $Repo $Ordner
  if ($LASTEXITCODE -ne 0) { throw 'Klonen fehlgeschlagen (GitHub-Anmeldung prüfen).' }
  & $git -C $Ordner config core.autocrlf false
  Write-Host "Gedächtnis geklont nach: $Ordner"
}

# 2. Sync-Skript
New-Item -ItemType Directory -Force $HookZiel | Out-Null
$sync = Join-Path $HookZiel 'gedaechtnis-sync.ps1'
Copy-Item (Join-Path $PSScriptRoot 'gedaechtnis-sync.ps1') $sync -Force
Write-Host "Sync-Skript: $sync"

# 3. Hooks in settings.json ergänzen (über Node, damit das JSON sauber bleibt)
$js = @'
const fs = require('fs');
const [file, sync, dir] = process.argv.slice(2);
let s = {};
if (fs.existsSync(file)) { const t = fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''); if (t.trim()) s = JSON.parse(t); }
s.hooks = s.hooks || {};
const mk = (modus, extra) => ({ hooks: [Object.assign({ type: 'command', command: 'powershell.exe',
  args: ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', sync, '-Modus', modus, '-Ordner', dir] }, extra)] });
const has = ev => (s.hooks[ev] || []).some(g => (g.hooks || []).some(h => JSON.stringify(h).includes('gedaechtnis-sync')));
let added = [];
if (!has('SessionStart')) { (s.hooks.SessionStart = s.hooks.SessionStart || []).push(mk('pull', { timeout: 30 })); added.push('SessionStart'); }
if (!has('Stop')) { (s.hooks.Stop = s.hooks.Stop || []).push(mk('push', { timeout: 60, async: true })); added.push('Stop'); }
fs.mkdirSync(require('path').dirname(file), { recursive: true });
fs.writeFileSync(file, JSON.stringify(s, null, 2) + '\n');
console.log(added.length ? 'Hooks ergänzt: ' + added.join(', ') : 'Hooks waren schon eingetragen');
'@
$tmp = Join-Path $env:TEMP 'gedaechtnis-hooks.js'
[IO.File]::WriteAllText($tmp, $js, (New-Object Text.UTF8Encoding $false))
& $node $tmp $EinstellungsDatei ($sync -replace '\\','/') ($Ordner -replace '\\','/')
if ($LASTEXITCODE -ne 0) { throw "settings.json konnte nicht ergänzt werden: $EinstellungsDatei" }
Remove-Item $tmp

# 4. Projekt auf das Gedächtnis umlenken
if ($ProjektOrdner) {
  $local = Join-Path $ProjektOrdner '.claude\settings.local.json'
  $js2 = @'
const fs = require('fs'); const [file, dir] = process.argv.slice(2);
let s = {}; if (fs.existsSync(file)) { const t = fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''); if (t.trim()) s = JSON.parse(t); }
s.autoMemoryDirectory = dir; fs.mkdirSync(require('path').dirname(file), { recursive: true });
fs.writeFileSync(file, JSON.stringify(s, null, 2) + '\n'); console.log('autoMemoryDirectory gesetzt in ' + file);
'@
  $tmp2 = Join-Path $env:TEMP 'gedaechtnis-local.js'
  [IO.File]::WriteAllText($tmp2, $js2, (New-Object Text.UTF8Encoding $false))
  & $node $tmp2 $local ($Ordner -replace '\\','/'); Remove-Item $tmp2
  $exclude = Join-Path $ProjektOrdner '.git\info\exclude'
  if ((Test-Path $exclude) -and -not (Select-String -Path $exclude -SimpleMatch '.claude/settings.local.json' -Quiet)) {
    Add-Content $exclude '.claude/settings.local.json'
  }
}
Write-Host 'Fertig. Neue Claude-Sitzung starten, damit die Hooks aktiv werden.'
exit 0
