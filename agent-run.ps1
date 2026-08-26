param(
    [Parameter(Mandatory = $true)]
    [string]$Task,
    [switch]$DryRun,
    [ValidateRange(1, 5)]
    [int]$MaxIterations
)

$projectRoot = $PSScriptRoot
$orchestrator = Join-Path $projectRoot "tools\agent_orchestrator.py"
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue
}
if (-not $python) {
    Write-Error "Python 3 was not found. Install Python 3 or add it to PATH."
    exit 2
}

$arguments = @($orchestrator, "--task", $Task)
if ($DryRun) {
    $arguments += "--dry-run"
}
if ($PSBoundParameters.ContainsKey("MaxIterations")) {
    $arguments += @("--max-iterations", $MaxIterations)
}

Push-Location $projectRoot
try {
    & $python.Source @arguments
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
