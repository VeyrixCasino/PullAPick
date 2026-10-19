<#
    run.ps1 -- hand one job to the Cursor agent and let it work headless.

    Owner, 2026-10-18: "give me cursor prompt or setup something so you can
    deploy cursor to work". Claude runs this to hand a job off, and so can you.

    ONE TIME, sign the Cursor agent in (a browser window opens):
        powershell -ExecutionPolicy Bypass -File "C:\Users\uybuv\Projects\mine-for-cards\tools\cursor\run.ps1" -Login

    RUN A JOB (a file in tools\cursor\tasks, named without .md):
        powershell -ExecutionPolicy Bypass -File "C:\Users\uybuv\Projects\mine-for-cards\tools\cursor\run.ps1" -Task icons-upload

    CHECK THE SIGN-IN:
        powershell -ExecutionPolicy Bypass -File "C:\Users\uybuv\Projects\mine-for-cards\tools\cursor\run.ps1" -Status

    What a job gets: tools\cursor\brief.md (the standing rules) and its task
    file. It runs with every tool allowed (--force), MCP servers approved (so it
    can drive Studio) and this repo trusted. The whole transcript goes to
    build\cursor\<task>-<time>.log, and the agent writes its own summary to
    build\cursor\<task>-report.md.

    -Model picks a model (see -Models for the list). -Worktree runs the job
    in its own git worktree, for repo-only work that must not collide with
    anyone; leave it off for Studio work, since Rojo serves this checkout.
#>
param(
    [string]$Task,
    [switch]$Login,
    [switch]$Status,
    [switch]$Models,
    [string]$Model = $env:CURSOR_MODEL,
    [switch]$Worktree
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)   # tools\cursor -> repo

# The CLI ships inside the Cursor app; a stand-alone install puts it on PATH.
function Find-Agent {
    foreach ($n in @('cursor-agent', 'agent')) {
        $c = Get-Command $n -ErrorAction SilentlyContinue
        if ($c) { return $c.Source }
    }
    $root = Join-Path $env:APPDATA 'Cursor\User\globalStorage\anysphere.cursor-agent-worker\agent-cli\.local\share\cursor-agent\versions'
    if (Test-Path $root) {
        $v = Get-ChildItem $root -Directory | Sort-Object Name -Descending |
            Where-Object { Test-Path (Join-Path $_.FullName 'cursor-agent.ps1') } | Select-Object -First 1
        if ($v) { return (Join-Path $v.FullName 'cursor-agent.ps1') }
    }
    throw 'The Cursor agent CLI was not found. Open the Cursor app once (it ships the CLI), then try again.'
}
$agent = Find-Agent
# From here on the agent's own stderr is just output. Under 'Stop', Windows
# PowerShell 5.1 turns the first stderr line of a redirected command into a
# terminating error, which would kill a job over a warning.
$ErrorActionPreference = 'Continue'

if ($Login) { & $agent login; exit $LASTEXITCODE }
if ($Status) { & $agent status; exit $LASTEXITCODE }
if ($Models) { & $agent models; exit $LASTEXITCODE }
if (-not $Task) { throw 'Pass -Task with a job name from tools\cursor\tasks, or -Login, -Status or -Models.' }

$taskFile = Join-Path $repo "tools\cursor\tasks\$Task.md"
if (-not (Test-Path $taskFile)) { Write-Host "  No job file at $taskFile" -ForegroundColor Red; exit 2 }

$who = (& $agent status 2>&1 | Out-String)
if ($who -match 'Not logged in') {
    Write-Host '  The Cursor agent is not signed in. Run this script once with -Login.' -ForegroundColor Red
    exit 3
}

$outDir = Join-Path $repo 'build\cursor'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$log = Join-Path $outDir ("$Task-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')

# Kept to one line on purpose: the agent reads the long brief and task from
# disk, so nothing multi-line has to survive the command line.
$prompt = "Read tools/cursor/brief.md, then do the job in tools/cursor/tasks/$Task.md. Write your report to build/cursor/$Task-report.md."

$argv = @('-p', '--force', '--trust', '--approve-mcps', '--output-format', 'text', '--workspace', $repo)
if ($Model) { $argv += @('--model', $Model) }
if ($Worktree) { $argv += @('--worktree', $Task) }
$argv += $prompt

Write-Host "  Cursor job '$Task' started. Log: $log" -ForegroundColor Cyan
$code = 1
Push-Location $repo
try {
    & $agent @argv 2>&1 | Tee-Object -FilePath $log
    $code = $LASTEXITCODE
} finally {
    Pop-Location
}
Write-Host "  Cursor job '$Task' finished (exit $code). Report: build\cursor\$Task-report.md" -ForegroundColor Cyan
exit $code
