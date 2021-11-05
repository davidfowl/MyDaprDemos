function Get-GitHubActionsSecret {
    [CmdletBinding()]
    param()

    Write-Output $(Invoke-RestMethod -Uri "https://api.github.com/repos/$($env:GITHUB_USER)/$($env:RepositoryName)/actions/secrets" `
            -Headers @{"Authorization" = "token $($env:ACTIONS_TOKEN)" }).secrets
}

function Remove-GitHubActionsSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [string] $Name
    )

    process {
        Invoke-RestMethod -Uri "https://api.github.com/repos/$($env:GITHUB_USER)/$($env:RepositoryName)/actions/secrets/$Name" `
            -Headers @{"Authorization" = "token $($env:ACTIONS_TOKEN)" } `
            -Method Delete | Out-Null
    }
}

function Set-GitHubActionsSecret {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Name,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Value
    )

    process {
        $publicKey = Get-GitHubRepositoryPublicKey
        $sealedPublicKeyBox = ConvertTo-SodiumEncryptedString -Text $Value -PublicKey $publicKey.key

        $body = @{
            'key_id'          = $publicKey.key_id
            'encrypted_value' = $sealedPublicKeyBox
        }

        $json = $body | ConvertTo-Json

        Invoke-RestMethod -Uri "https://api.github.com/repos/$($env:GITHUB_USER)/$($env:RepositoryName)/actions/secrets/$Name" `
            -Headers @{"Authorization" = "token $($env:ACTIONS_TOKEN)" } `
            -Body $json `
            -Method Put
    }
}

function Get-GitHubRepositoryPublicKey {
    [CmdletBinding()]
    param ()

    Invoke-RestMethod -Uri "https://api.github.com/repos/$($env:GITHUB_USER)/$($env:RepositoryName)/actions/secrets/public-key" `
        -Headers @{"Authorization" = "token $($env:ACTIONS_TOKEN)" }
}

function Get-GitHubActionsWorkflow {
    param (
        [string] $name = $null
    )

    if ($null -ne $name) {
        Invoke-RestMethod -Uri "https://api.github.com/repos/$($env:GITHUB_USER)/$($env:RepositoryName)/actions/workflows/$name" `
        -Headers @{"Authorization" = "token $($env:ACTIONS_TOKEN)" }
    }
    else {
        $(Invoke-RestMethod -Uri "https://api.github.com/repos/$($env:GITHUB_USER)/$($env:RepositoryName)/actions/workflows" `
            -Headers @{"Authorization" = "token $($env:ACTIONS_TOKEN)" }).workflows
    }
}

function Start-GitHubActionsWorkflow {
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [string] $workflow_id,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [string] $branch
    )

    Invoke-RestMethod -Uri "https://api.github.com/repos/$($env:GITHUB_USER)/$($env:RepositoryName)/actions/workflows/$workflow_id/dispatches" `
        -Headers @{"Authorization" = "token $($env:ACTIONS_TOKEN)" } `
        -Method Post `
        -Body '{"ref":"$branch"}'
}