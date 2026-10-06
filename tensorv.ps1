param([ValidateSet('all','test','unit','smoke','benchmark','synth','tools')][string]$Target = 'all')
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    & wsl.exe -d Ubuntu -- make $Target
    if ($LASTEXITCODE -ne 0) { throw "TENSOR-V target '$Target' failed (exit $LASTEXITCODE)." }
} finally { Pop-Location }
