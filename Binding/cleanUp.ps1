# This will start the deletion of a resource group but not wait.

[CmdletBinding()]
param (
    [Parameter(
        Position = 0,
        HelpMessage = "The name of the resource group to be created. All resources will be place in the resource group and start with name."
    )]
    [string]
    $rgName = "dapr_binding_demo",

    [Parameter(
        HelpMessage = "Set to the environment of the resources to clean up."
    )]
    [ValidateSet("all", "azure", "aws", "gcp", "local")]
    [string]
    $env = "all",

    [switch]
    $force,

    [switch]
    $timing
)

# Put the sampleRequests.http file back the way it was
git restore ./sampleRequests.http

if ($env -eq 'all' -or $env -eq 'local') {
    Write-Host "Cleaning up local"

    # Remove the myTestFile.txt
    Remove-Item ./tempfiles/myTestFile.txt -ErrorAction SilentlyContinue
}

if ($env -eq 'all' -or $env -eq 'azure') {
    Write-Host "Cleaning up azure"

    # Remove local_secrets.json
    Remove-Item ./components/azure/local_secrets.json -ErrorAction SilentlyContinue

    if ($timing.IsPresent) {
        $sw = [Diagnostics.Stopwatch]::StartNew()

        if ($force.IsPresent) {
            az group delete --resource-group $rgName --yes
        }
        else {
            az group delete --resource-group $rgName
        }

        $sw.Stop()

        Write-Verbose "Total elapsed time: $($sw.Elapsed.Minutes):$($sw.Elapsed.Seconds):$($sw.Elapsed.Milliseconds) for deleting a Azure Blob Storage"
    }
    else {
        if ($force.IsPresent) {
            az group delete --resource-group $rgName --no-wait --yes
        }
        else {
            az group delete --resource-group $rgName --no-wait
        }
    }
}

if ($env -eq 'all' -or $env -eq 'aws') {
    Write-Host "Cleaning up aws"

    # Delete AWS resources
    if ($(Test-Path ./deploy/aws/terraform.tfvars)) {
        Push-Location ./deploy/aws
        $sw = [Diagnostics.Stopwatch]::StartNew()
        terraform destroy -auto-approve
        $sw.Stop()

        Write-Verbose "Total elapsed time: $($sw.Elapsed.Minutes):$($sw.Elapsed.Seconds):$($sw.Elapsed.Milliseconds) for deleting a AWS S3 Bucket"
        Pop-Location
    }

    # Remove all terraform files
    Remove-Item ./deploy/aws/terraform.tfvars -Force -ErrorAction SilentlyContinue
    Remove-Item ./deploy/aws/terraform.tfstate -Force -ErrorAction SilentlyContinue
    Remove-Item ./deploy/aws/.terraform -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item ./deploy/aws/.terraform.lock.hcl -Force -ErrorAction SilentlyContinue
    Remove-Item ./deploy/aws/terraform.tfstate.backup -Force -ErrorAction SilentlyContinue
}