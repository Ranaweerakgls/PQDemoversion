# Makes a branch with a failing test, pushes it and opens a pull request, so PipelineIQ has a
# failed CI run to diagnose.
# Usage: powershell -ExecutionPolicy Bypass -File scripts\make-failing-pr.ps1 [-Kind genuine|flaky]
#   genuine (default): breaks add() so a test fails every time.
#   flaky: adds a test that fails about 2 runs in 3.
# Needs a GitHub remote called "origin". With the gh tool it opens the PR; without it, it prints the link.
param([ValidateSet("genuine", "flaky")][string]$Kind = "genuine")
# Git prints progress on stderr, which "Stop" would treat as an error; exit codes are checked instead.
$ErrorActionPreference = "Continue"
Set-Location (Split-Path $PSScriptRoot -Parent)

if (git status --porcelain) { throw "You have uncommitted changes. Commit or stash them first." }
$remote = if ((git remote) -contains "origin") { git remote get-url origin } else { $null }
if (-not $remote) { throw "No 'origin' remote yet. Add one: git remote add origin https://github.com/<you>/piq-demo.git" }

git checkout main *> $null
if ($LASTEXITCODE -ne 0) { throw "Could not switch to main." }
git pull --ff-only origin main *> $null
if ($LASTEXITCODE -ne 0) { throw "Could not update main from GitHub (git pull failed)." }
$branch = "failing-$Kind-" + (Get-Date -Format "MMdd-HHmmss")
git checkout -b $branch *> $null
if ($LASTEXITCODE -ne 0) { throw "Could not create branch $branch." }

if ($Kind -eq "genuine") {
    (Get-Content src\math.js -Raw) -replace "return a \+ b;", "return a - b;" | Set-Content src\math.js -NoNewline
    $message = "Break add(): subtracts instead of adding"
} else {
    $name = "test\flaky-$(Get-Date -Format 'HHmmss').test.js"
    @'
const test = require('node:test');
const assert = require('node:assert');

// Flaky on purpose: fails about 2 runs in 3.
test('flaky: random check', () => {
  assert.ok(Math.random() < 0.33, 'unlucky run');
});
'@ | Set-Content $name
    $message = "Add a flaky test"
}

git add -A
git commit -q -m $message
git push -u origin $branch
if ($LASTEXITCODE -ne 0) { throw "Push failed. Check the remote and your GitHub login." }

if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh pr create --base main --head $branch --title $message --body "Test PR for PipelineIQ ($Kind failure)."
} else {
    $url = ($remote -replace "\.git$", "") -replace "^git@github.com:", "https://github.com/"
    Write-Host "`nPushed $branch. Open the pull request here:`n  $url/compare/main...$branch?expand=1" -ForegroundColor Green
}
git checkout main *> $null
