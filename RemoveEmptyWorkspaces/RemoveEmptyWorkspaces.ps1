<# 
.SYNOPSIS
Remove Power BI Workspaces that are empty. Use results from previous Power BI Assessments to identify empty workspaces and this script to remove them in bulk.

.DESCRIPTION
The sample scripts are not supported under any Microsoft standard support program or service. 
The sample scripts are provided AS IS without warranty of any kind. 
Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of 
fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation 
remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of 
the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, 
business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the 
sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages. 
#>

Import-Module MicrosoftPowerBIMgmt

# Replace with your CSV file path. The file should have a column called WorkspaceId with the workspace IDs to be deleted
$workspacesFilePath = "C:\temp\ws_input.csv"     
# Path to the log file
$logFilePath = "C:\temp\ws_deletion.log"    
#Path to CSV file where the deletion status will be logged for each workspace
$wsDeletionLogFilePath = "C:\temp\ws_deletion_status.csv"

#Email of the user that is running the script and that will be added as Admin of the workspace to proceed deletions. Should be the same that logs in the Power BI Service
$email = "xxxxx@contoso.com"                      

# Logging functions
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp`t$message"
    Add-Content -Path $logFilePath -Value $logMessage
}

function Write-Removal-Status {
    param (
        [string]$workspaceId,
        [string]$status
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $errorEntry = [PSCustomObject]@{
        Timestamp   = $timestamp
        WorkspaceId = $workspaceId
        Status      = $status
    }
    if (-Not (Test-Path -Path $wsDeletionLogFilePath)) {
        $errorEntry | Export-Csv -Path $wsDeletionLogFilePath -NoTypeInformation
    } else {
        $errorEntry | Export-Csv -Path $wsDeletionLogFilePath -NoTypeInformation -Append
    }
}

# Function to add admin rights as some operations require admin access at the workspace level
function Add-Admin {
    param (
        [string]$workspaceId,
        [string]$useremail
    )
    $uri = "https://api.powerbi.com/v1.0/myorg/admin/groups/$workspaceId/users"
    $body = @{
        emailAddress        = $useremail
        groupUserAccessRight = "Admin"
    } | ConvertTo-Json
    try {
        Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $body -ContentType "application/json"
        Write-Log "Added admin rights for workspace $workspaceId."
    } catch {
        Write-Log "Failed to add admin rights for workspace $workspaceId. Error: $($_.Exception.Message)"
    }
}

# Function to remove admin rights in case of failure in the process to restore original state of the workspace
function Remove-Admin {
    param (
        [string]$workspaceId,
        [string]$useremail
    )
    $uri = "https://api.powerbi.com/v1.0/myorg/admin/groups/$workspaceId/users/$useremail"
    try {
        Invoke-WebRequest -Uri $uri -Method Delete -Headers $headers
        Write-Log "Removed admin rights for workspace $workspaceId."
    } catch {
        Write-Log "Failed to remove admin rights for workspace $workspaceId. Error: $($_.Exception.Message)"
    }
}

# Function to check if the workspace is empty
function Get-IsWorkspaceEmpty {
    param (
        [string]$workspaceId
    )

    try {
        # Obtain the details of the workspace and check if it has any content, excluding DELETED workspaces
        $workspace = Get-PowerBIWorkspace -Id $workspaceId -Include All -Scope Organization
        if ($null -ne $workspace) {
            
            #Check if the workspace state is not Deleted
            if ($workspace.State -ne "Deleted") {     
                #Uncomment to view workspace details
                #Write-Host "Workspace details: $($workspace | ConvertTo-Json -Depth 3)"
                
                $datasetsCount = if ($workspace.Datasets) { ($workspace.Datasets | Measure-Object).Count } else { 0 } 
                $reportsCount = if ($workspace.Reports) { ($workspace.Reports | Measure-Object).Count } else { 0 } 
                $dashboardsCount = if ($workspace.Dashboards) { ($workspace.Dashboards | Measure-Object).Count } else { 0 } 
                $dataflowsCount = if ($workspace.Dataflows) { ($workspace.Dataflows | Measure-Object).Count } else { 0 } 
                $workbooksCount = if ($workspace.Workbooks) { ($workspace.Workbooks | Measure-Object).Count } else { 0 }
                
                Write-Log "Workspace ID: $workspaceId | Datasets: $datasetsCount | Reports: $reportsCount | Dashboards: $dashboardsCount | Dataflows: $dataflowsCount | Workbooks: $workbooksCount"

                if ($datasetsCount -eq 0 -and 
                    $reportsCount -eq 0 -and 
                    $dashboardsCount -eq 0 -and 
                    $dataflowsCount -eq 0 -and 
                    $workbooksCount -eq 0) {
                    Write-Log "Workspace $workspaceId is empty. Script will try to delete it."
                    return $true
                } else {
                    Write-Log "Workspace $workspaceId is not empty. It can not be deleted." 
                }
            } else {
                Write-Log "Workspace $workspaceId is already in Deleted state. It can not be deleted."
            }
        } else {            
            Write-Log "Workspace $workspaceId was not found. It can not be deleted."
        }  
    } catch {
        Write-Log "Failed to retrieve workspace $workspaceId. Error: $($_.Exception.Message)"
    }

    return $false
}

#Function to remove a workspace 
function Remove-Workspace {
    param (
        [string]$workspaceId
    )
    $uri = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId"
    try {
        Invoke-WebRequest -Uri $uri -Method Delete -Headers $headers
        Write-Log "Deleted workspace $workspaceId."
        return $true
    } catch {
        Write-Log "Failed to delete workspace $workspaceId. Error: $($_.Exception.Message)"
        return $false
    }
}

# Main script. Authenticate to Power BI, get access token, import workspaces from CSV, and process each workspace, only deleting them if they are empty
Write-Host "Script execution started."
Write-Log "Script execution started."

# Authenticate to Power BI
try {
    Connect-PowerBIServiceAccount
    Write-Log "Successfully authenticated to Power BI."
} catch {
    Write-Log "Failed to authenticate to Power BI. Error: $($_.Exception.Message)"
    exit
}

# Get access token
$tokenResponse = Get-PowerBIAccessToken
if ($null -eq $tokenResponse -or $tokenResponse.AccessToken -eq "") {
    Write-Host "Failed to retrieve access token. Exiting script"
    exit
}

$accessToken = $tokenResponse.Authorization
$headers = @{ Authorization = "$accessToken" }

# Import workspaces from CSV
try {    
    $items = Import-Csv -Path $workspacesFilePath -Delimiter ","
    Write-Log "Successfully imported workspaces from $workspacesFilePath."
} catch {
    Write-Log "Failed to import workspaces from $workspacesFilePath. Error: $($_.Exception.Message)"
    exit
}

#Process each workspace, only deleting them if they are empty
foreach ($item in $items) {
    $workspaceId = $item.WorkspaceId
    Write-Log "Processing workspace: $workspaceId"   

    # Check if workspace is empty
    if (Get-IsWorkspaceEmpty -workspaceId $workspaceId) {
        # Add admin rights
        Add-Admin -workspaceId $workspaceId -useremail $email
        # Delete workspace
        $deleted = Remove-Workspace -workspaceId $workspaceId
        if ($deleted) {
            Write-Removal-Status -workspaceId $workspaceId -status "DELETED"
        } else {
            Write-Removal-Status -workspaceId $workspaceId -status "FAILED TO DELETE"
            # Remove admin rights for the current user as removal failed
            Remove-Admin -workspaceId $workspaceId -useremail $email
        }
    } else {
        Write-Removal-Status -workspaceId $workspaceId -status "WS NOT EMPTY / NOT FOUND / ALREADY DELETED"
    }
}

Write-Host "Script execution completed."
Write-Log "Script execution completed."