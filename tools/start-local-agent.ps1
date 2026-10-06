<#
    start-local-agent.ps1 -- get a local Claude Code running on this repo.

    Owner, 2026-10-04: "i dont know my path and id rather get a local agent
    anyways". So this finds the repo itself, and nothing in it needs a path
    typed by hand.

    HOW TO RUN IT, if you cannot find this file either: paste the four lines
    under "THE NO-SCRIPT VERSION" in docs/HANDOFF.md into PowerShell instead.
    They do the same thing without needing the script.

    Otherwise: right-click this file -> Run with PowerShell. Or in a terminal:
        powershell -ExecutionPolicy Bypass -File .\tools\start-local-agent.ps1
#>

$ErrorActionPreference = 'Stop'

function Say($msg, $colour = 'Cyan') { Write-Host "  $msg" -ForegroundColor $colour }

Write-Host ""
Write-Host "  Mine For Cards -- local agent bootstrap" -ForegroundColor White
Write-Host ""

# --- 1. Find the repo -------------------------------------------------------
# default.project.json is the Rojo project file and sits at the repo root, so
# finding it finds the repo. Searched under the user profile, which is where
# GitHub Desktop and git clone both land by default.
$here = Split-Path -Parent $PSScriptRoot   # tools\ -> repo root
if (-not (Test-Path (Join-Path $here 'default.project.json'))) {
    Say "Searching for the repo under $HOME ..." 'DarkGray'
    $found = Get-ChildItem -Path $HOME -Filter 'default.project.json' -Recurse -ErrorAction SilentlyContinue |
             Select-Object -First 1
    if (-not $found) {
        Say "Could not find default.project.json anywhere under $HOME." 'Red'
        Say "Open GitHub Desktop, right-click the repo, 'Show in Explorer', and" 'Yellow'
        Say "copy the path from the address bar. Then: cd `"<that path>`"" 'Yellow'
        exit 1
    }
    $here = $found.Directory.FullName
}
Say "Repo: $here" 'Green'
Set-Location $here

# --- 2. Get the latest work -------------------------------------------------
try {
    Say "Pulling..." 'DarkGray'
    git pull
} catch {
    Say "git pull failed -- carrying on with what is on disk." 'Yellow'
}

# --- 3. Node, then Claude Code ---------------------------------------------
# `claude` is an npm global, so Node has to exist first. Checked rather than
# assumed, because "npm is not recognised" is the first wall people hit.
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Say "Node.js is not installed." 'Red'
    Say "Install the LTS build from https://nodejs.org, then reopen PowerShell" 'Yellow'
    Say "and run this script again." 'Yellow'
    exit 1
}
Say "Node $(node --version)" 'Green'

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Say "Installing Claude Code (one time, a minute or two)..." 'DarkGray'
    npm install -g @anthropic-ai/claude-code
    # A fresh npm global is not on PATH in THIS shell until it restarts, so
    # add it by hand rather than telling the owner to open another terminal.
    $npmRoot = (npm root -g)
    $npmBin = Split-Path -Parent $npmRoot
    if (Test-Path $npmBin) { $env:Path = "$npmBin;$env:Path" }
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Say "Claude Code installed but is not on PATH in this window." 'Yellow'
    Say "Close PowerShell, open it again, then type:  claude" 'Yellow'
    exit 1
}

# --- 4. Hand over -----------------------------------------------------------
Write-Host ""
Say "Starting Claude Code. Tell it: 'read docs/HANDOFF.md and continue'" 'White'
Write-Host ""
claude
