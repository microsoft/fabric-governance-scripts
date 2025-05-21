<# 
.SYNOPSIS
Remove Users, Service Principals and Groups access from the workspaces and add an alternative Administrator

.DISCLAIMER
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

# Add a timestamp to the file name
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

# Path to the input CSV file with the list of users and access details
$InputFilePath = "C:\Example\Inactive\20241203141950_inactive_workspaces_access.csv"

# Directory for the generated files
$OutputDirectory = "C:\Example\Removal\"

# Path to the log file
$logFilePath = "$OutputDirectory" + $timestamp + "_removeaccesslog.log"

# Path to the output CSV file
$outputFilePath = "$OutputDirectory" + $timestamp + "_updated_access_status.csv"

# Email of the user that is running the script and that will be added as Admin of the workspace to proceed deletions. Should be the same that logs in the Power BI Service
$newAdminEmail = "user1@example.com"

# Logging functions
function Write-Log {
    param (
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp`t[$type]`t$message"
    Add-Content -Path $logFilePath -Value $logMessage
    Write-Host $logMessage
}

#Add a user as Admin of the workspace to ensure it's not Orphaned
function Add-AdminToWorkspace {
    param (
        [string]$workspaceId,
        [string]$userEmail,
        [string]$access
    )
    try {
        $url = "https://api.powerbi.com/v1.0/myorg/admin/groups/$workspaceId/users"
        $body = @{
            "emailAddress" = $userEmail
            "groupUserAccessRight" = $access
        } | ConvertTo-Json
        $result = Invoke-PowerBIRestMethod -Url $url -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        
        return @{
            Status = "Success"
            Description = "Admin added successfully."
        }
    } catch {       
        return @{
            Status = "Failure"
            Description = "Error adding admin: $_.Exception.Message"
        }
    }
}


# Authenticate with the Power BI API
try {
    Connect-PowerBIServiceAccount -ErrorAction Stop
    Write-Log -message "Authenticated with the Power BI API."
} catch {
    Write-Log -message "Error authenticating with the Power BI API. $_" -type "ERROR"
    exit
}

# Read the list of access details from the CSV file
try {
    $accessDetails = Import-Csv -Path $InputFilePath -ErrorAction Stop
    Write-Log -message "Access details read from the CSV file."
} catch {
    Write-Log -message "Error reading the access details from the CSV file. $_" -type "ERROR"
    exit
}

# Create a new list for storing updated access details
$updatedAccessDetails = @()

# Create a hash table to keep track of workspaces that have already had the admin added
$workspacesWithAdmin = @{}

# Loop over the access details and process each entry
foreach ($entry in $accessDetails) {
    # Reuse variables to avoid repetition
    $workspaceId = $entry.workspaceId
    $emailAddress = $entry.emailAddress
    $displayName = $entry.displayName
    $identifier = $entry.identifier
    $principalType = $entry.principalType
    $groupUserAccessRight = $entry.groupUserAccessRight
    $executionTimestamp = $entry.executionTimestamp

    $status = ""
    $description = ""
   
    # Add current user as admin to the workspace (only once per workspace)
    if (-not $workspacesWithAdmin.ContainsKey($workspaceId)) {
        $addAdminResult = Add-AdminToWorkspace -workspaceId $workspaceId -userEmail $newAdminEmail -access "Admin"
    
        if ($addAdminResult.Status -eq "Success") {
            Write-Log -message "Added $newAdminEmail as admin to workspace $workspaceId."
            $workspacesWithAdmin[$workspaceId] = $true
        } else {
            Write-Log -message "Error adding $newAdminEmail as admin to workspace $workspaceId. $addAdminResult.Description" -type "ERROR"
            $status = "Failure"
            $description = $addAdminResult.Description
            $updatedAccessDetails += [pscustomobject]@{
                workspaceId = $workspaceId
                emailAddress = $emailAddress
                displayName = $displayName
                identifier = $identifier
                principalType = $principalType
                groupUserAccessRight = $groupUserAccessRight
                executionTimestamp = $executionTimestamp
                Status = $status
                Description = $description
            }
            continue
        }
    }

    # Remove existing access based on the principal type
    try {

        #Check if the email is equal to the new Admin Email to avoid removing Admin access if previously had access to the workspace 
        if ($emailAddress -eq $newAdminEmail){        
            $status = "Not Removed"
            $description = "User is the same as the new admin and need to be kept in the Workspace"
        } else {                            
            $urlRemoveAccess = "https://api.powerbi.com/v1.0/myorg/admin/groups/$workspaceId/users/$identifier"
            if ($principalType -eq "Group") {
                $urlRemoveAccess += "?isGroup=true"
            } elseif ($principalType -eq "ServicePrincipal") {
                $urlRemoveAccess += "?profileId=$identifier"
            }
            Invoke-PowerBIRestMethod -Url $urlRemoveAccess -Method Delete -ErrorAction Stop
            Write-Log -message "Removed access for $principalType ($identifier) from workspace $workspaceId."
            $status = "Removed"
            $description = "Principal access removed from the workspace"
        }
    } catch {
        Write-Log -message "Error removing access for $principalType ($identifier) from workspace $workspaceId. $_" -type "ERROR"
        $status = "Failure"
        $description = "Error removing access: $_.Exception.Message"
    }

    # Add the result to the updated access details
    $updatedAccessDetails += [pscustomobject]@{
        workspaceId = $workspaceId
        emailAddress = $emailAddress
        displayName = $displayName
        identifier = $identifier
        principalType = $principalType
        groupUserAccessRight = $groupUserAccessRight
        executionTimestamp = $executionTimestamp
        Status = $status
        Description = $description
    }
}

# Save the updated access details to a new CSV file
try {
    $updatedAccessDetails | Export-Csv -Path $outputFilePath -NoTypeInformation -ErrorAction Stop
    Write-Log -message "Updated access details saved to $outputFilePath."
} catch {
    Write-Log -message "Error saving updated access details to $outputFilePath. $_" -type "ERROR"
}

Write-Output "Access removal process completed. Check the log file and updated CSV file for details."
