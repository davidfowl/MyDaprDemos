# This will call setup of every demo.

[CmdletBinding()]
param (
    $demo = @('Binding', 'Observability', 'PubSub', 'StateStore', 'Secrets', 'DevOps')
)

foreach ($d in $demo) {
    Write-Host "Setting up $d"

    Push-Location "../$d"
    ./demo.ps1 -deployOnly
    Pop-Location
}