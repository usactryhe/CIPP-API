function Set-CIPPAssignedApplication {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        $GroupName,
        $Intent,
        $AppType,
        $ApplicationId,
        $TenantFilter,
        $APIName = 'Assign Application',
        $Headers
    )
    Write-Host "GroupName: $GroupName Intent: $Intent AppType: $AppType ApplicationId: $ApplicationId TenantFilter: $TenantFilter APIName: $APIName"
    try {
        $MobileAppAssignment = switch ($GroupName) {
            'AllUsers' {
                @(@{
                        '@odata.type' = '#microsoft.graph.mobileAppAssignment'
                        target        = @{
                            '@odata.type' = '#microsoft.graph.allLicensedUsersAssignmentTarget'
                        }
                        intent        = $Intent
                        settings      = @{
                            '@odata.type'       = "#microsoft.graph.$($appType)AppAssignmentSettings"
                            notifications       = 'hideAll'
                            installTimeSettings = $null
                            restartSettings     = $null
                        }
                    })
                break
            }
            'AllDevices' {
                @(@{
                        '@odata.type' = '#microsoft.graph.mobileAppAssignment'
                        target        = @{
                            '@odata.type' = '#microsoft.graph.allDevicesAssignmentTarget'
                        }
                        intent        = $Intent
                        settings      = @{
                            '@odata.type'       = "#microsoft.graph.$($appType)AppAssignmentSettings"
                            notifications       = 'hideAll'
                            installTimeSettings = $null
                            restartSettings     = $null
                        }
                    })
                break
            }
            'AllDevicesAndUsers' {
                @(
                    @{
                        '@odata.type' = '#microsoft.graph.mobileAppAssignment'
                        target        = @{
                            '@odata.type' = '#microsoft.graph.allLicensedUsersAssignmentTarget'
                        }
                        intent        = $Intent
                        settings      = @{
                            '@odata.type'       = "#microsoft.graph.$($appType)AppAssignmentSettings"
                            notifications       = 'hideAll'
                            installTimeSettings = $null
                            restartSettings     = $null
                        }
                    },
                    @{
                        '@odata.type' = '#microsoft.graph.mobileAppAssignment'
                        target        = @{
                            '@odata.type' = '#microsoft.graph.allDevicesAssignmentTarget'
                        }
                        intent        = $Intent
                        settings      = @{
                            '@odata.type'       = "#microsoft.graph.$($appType)AppAssignmentSettings"
                            notifications       = 'hideAll'
                            installTimeSettings = $null
                            restartSettings     = $null
                        }
                    }
                )
            }
            default {
                $GroupNames = $GroupName.Split(',')
                $GroupIds = New-GraphGetRequest -uri 'https://graph.microsoft.com/beta/groups' -tenantid $TenantFilter | ForEach-Object {
                    $Group = $_
                    foreach ($SingleName in $GroupNames) {
                        if ($_.displayname -like $SingleName) {
                            $group.id
                        }
                    }
                }
                Write-Information "found $($GroupIds) groups"
                foreach ($Group in $GroupIds) {
                    @{
                        '@odata.type' = '#microsoft.graph.mobileAppAssignment'
                        target        = @{
                            '@odata.type' = '#microsoft.graph.groupAssignmentTarget'
                            groupId       = $Group
                        }
                        intent        = $Intent
                        settings      = @{
                            '@odata.type'       = "#microsoft.graph.$($appType)AppAssignmentSettings"
                            notifications       = 'hideAll'
                            installTimeSettings = $null
                            restartSettings     = $null
                        }
                    }
                }
            }
        }
        $DefaultAssignmentObject = [PSCustomObject]@{
            mobileAppAssignments = @(
                $MobileAppAssignment
            )
        }
        if ($PSCmdlet.ShouldProcess($GroupName, "Assigning Application $ApplicationId")) {
            Start-Sleep -Seconds 1
            $null = New-GraphPOSTRequest -uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($ApplicationId)/assign" -tenantid $TenantFilter -type POST -body ($DefaultAssignmentObject | ConvertTo-Json -Compress -Depth 10)
            Write-LogMessage -headers $Headers -API $APIName -message "Assigned Application to $($GroupName)" -Sev 'Info' -tenant $TenantFilter
        }
        return "Assigned Application to $($GroupName)"
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        Write-LogMessage -headers $Headers -API $APIName -message "Could not assign application to $GroupName. Error: $($ErrorMessage.NormalizedError)" -Sev 'Error' -tenant $TenantFilter -LogData $ErrorMessage
        return "Could not assign application to $GroupName. Error: $($ErrorMessage.NormalizedError)"
    }
}
