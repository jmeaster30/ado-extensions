[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    # Get variables
    $RepoName = Get-VstsInput -Name repositoryName -Require
    $BranchName = Get-VstsInput -Name branchName -Require
    $SourceBranch = Get-VstsInput -Name sourceBranchName -Require

    $DevOpsUri = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
    $ProjectName = $env:SYSTEM_TEAMPROJECT
    $ProjectId = $env:SYSTEM_PROJECTID
    $BuildId = $env:BUILD_BUILDID

    Write-Output "Repository: $($RepoName)"
    Write-Output "SourceBranch: $($SourceBranch)"
    Write-Output "BranchName: $($BranchName)"
    Write-Output "DevOpsUri: $($DevOpsUri)"
    Write-Output "ProjectId: $($ProjectId)"
    Write-Output "BuildId: $($BuildId)"

    $requestHeader = @{Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"}

    # Get variables from variable group
    $findBranchUri = "$($DevOpsUri)$($ProjectName)/_apis/git/repositories/$RepoName/refs?filter=heads/$BranchName&api-version=5.1-preview.1"
    Write-Host "Invoking get request on >> $($findBranchUri)"
    $branches = Invoke-RestMethod -Uri $findBranchUri -Method Get -ContentType "application/json" -Headers $requestHeader
    
    $findSourceBranchUri = "$($DevOpsUri)$($ProjectName)/_apis/git/repositories/$RepoName/refs?filter=heads/$SourceBranch&api-version=5.1-preview.1"
    Write-Host "Invoking get request on >> $($findSourceBranchUri)"
    $sourceBranches = Invoke-RestMethod -Uri $findSourceBranchUri -Method Get -ContentType "application/json" -Headers $requestHeader

    if ($branches.Count -eq 0 -And $sourceBranches.Count -eq 1) {
        Write-Host "Creating $BranchName from $SourceBranch!"
        $SourceObjectId = $sourceBranches.value[0].objectId
        
        $UpdateObject = @{
            refUpdates = @(@{
                name        = "refs/heads/$BranchName"
                oldObjectId = "0000000000000000000000000000000000000000"
                newObjectId = "$SourceObjectId"
            })
        }

        Write-Host $UpdateObject

        $updateUri = "$($DevOpsUri)$($ProjectName)/_apis/git/repositories/$RepoName/refs?api-version=5.1-preview.1"

        $body = $UpdateObject | ConvertTo-Json -Depth 5 -Compress

        Write-Host ([System.Text.Encoding]::UTF8.GetBytes($body))
        Write-Host "Invoking put request on >> $($updateUri)"
        Invoke-RestMethod -Uri $updateUri -Method Post -ContentType "application/json" -Headers $requestHeader -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
    } elseif ($branches.Count -ne 0) {
        Throw "$BranchName already exists"
    } else {
        Throw "Couldn't find valid $SourceBranch"
    }
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
