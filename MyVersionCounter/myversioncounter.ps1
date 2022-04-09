[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try {
    # Get variables
    $VariableGroup = Get-VstsInput -Name groupName -Require
    $VariableName = Get-VstsInput -Name variableName -Require
    $PersonalAccessToken = Get-VstsInput -Name personalAccessToken -Require
    $MaxPatchNum = Get-VstsInput -Name maxPatchNumber -Require
    $MaxMinorNum = Get-VstsInput -Name maxMinorNumber -Require

    $DevOpsUri = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
    $ProjectName = $env:SYSTEM_TEAMPROJECT
    $ProjectId = $env:SYSTEM_PROJECTID
    $BuildId = $env:BUILD_BUILDID

    Write-Output "VariableGroup: $($VariableGroup)"
    Write-Output "VariableName: $($VariableName)"
    Write-Output "MaxPatchNum: $($MaxPatchNum)"
    Write-Output "MaxMinorNum: $($MaxMinorNum)"
    Write-Output "DevOpsUri: $($DevOpsUri)"
    Write-Output "ProjectId: $($ProjectId)"
    Write-Output "BuildId: $($BuildId)"

    $authToken = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "", $PersonalAccessToken)))
    $requestHeader = @{Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"}

    # Get variables from variable group
    $varGroupUri = "$($DevOpsUri)$($ProjectName)/_apis/distributedtask/variablegroups?groupName=$($VariableGroup)&api-version=5.1-preview.1"

    Write-Host "Invoking get request on >> $($varGroupUri)"
    $groups = Invoke-RestMethod -Uri $varGroupUri -Method Get -ContentType "application/json" -Headers $requestHeader
    
    if ($groups.Count -gt 0) {
        Write-Output "Count: $($groups.Count)"
        $version = $groups.value.variables.$VariableName.value
        $groupId = $groups.value.id

        if (!$version) {
            $version = "0.1.0"
        }

        $items = $version.split('.')

        if ($items.Count -gt 3 -or $items.Count -lt 3) {
            Write-Error "Cannot parse version number :("
        } else {
            $patch = $items[2]
            $minor = $items[1]
            $major = $items[0]

            Write-Host "Current..."
            Write-Host "Major: $($major)"
            Write-Host "Minor: $($minor)"
            Write-Host "Patch: $($patch)"

            $patchVal = [Convert]::ToInt32($patch, 10)
            $minorVal = [Convert]::ToInt32($minor, 10)
            $majorVal = [Convert]::ToInt32($major, 10)

            $newMajor = $majorVal
            $newMinor = $minorVal
            $newPatch = $patchVal + 1

            if ($newPatch -gt [Convert]::ToInt32($MaxPatchNum, 10)) {
                $newMinor = $newMinor + 1
                $newPatch = 0
            }

            if ($newMinor -gt [Convert]::ToInt32($MaxMinorNum, 10)) {
                $newMajor = $newMajor + 1
                $newMinor = 0
            }

            Write-Host "New..."
            Write-Host "Major: $($newMajor)"
            Write-Host "Minor: $($newMinor)"
            Write-Host "Patch: $($newPatch)"

            # update
            # Get variables from variable group
            $varUpdateUri = "$($DevOpsUri)$($ProjectName)/_apis/distributedtask/variablegroups/$($groupId)?api-version=5.1-preview.1"

            $obj = $groups.value
            $obj.variables.$VariableName.value = "$($newMajor).$($newMinor).$($newPatch)"

            $body = $obj | ConvertTo-Json -Depth 5 -Compress

            Write-Host ([System.Text.Encoding]::UTF8.GetBytes($body))
            Write-Host "Invoking put request on >> $($varUpdateUri)"
            Invoke-RestMethod -Uri $varUpdateUri -Method Put -ContentType "application/json" -Headers $requestHeader -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
        }
    } else {
        Write-Output "no variables found in the variable group :("
    }

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
