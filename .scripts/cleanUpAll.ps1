# This will call cleanUp of every demo.

[CmdletBinding()]
param (
    $demo = @('Binding', 'Observability', 'PubSub', 'StateStore', 'Secrets', 'DevOps'),

    [switch]
    $Force
)

foreach ($d in $demo) {
    Write-Host "Cleaning up $d"

    Push-Location "../$d"
    ./cleanUp.ps1 -force:$Force.IsPresent
    Pop-Location
}