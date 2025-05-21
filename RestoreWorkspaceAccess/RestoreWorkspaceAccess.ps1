<# 
.SYNOPSIS
Restore user's, groups and service principal access to a workspace based on a previous snapshot

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

# Add a timestamp to the file name
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

# Path to the input CSV file with the list of users and access details
$InputFilePath = "C:\Example\Inactive\20241203141950_inactive_workspaces_access.csv"

# Directory for the generated files
$OutputDirectory = "C:\Example\Restore\"

# Path to the log file
$logFilePath = "$OutputDirectory" + $timestamp + "_restoreaccesslog.log"

# Path to the output CSV file
$outputFilePath = "$OutputDirectory" + $timestamp + "_restored_access_status.csv"

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

# Add user access to the workspace
function Add-UserAccessToWorkspace {
    param (
        [string]$workspaceId,
        [string]$identifier = $null,
        [string]$principalType,
        [string]$groupUserAccessRight,
        [string]$emailAddress = $null
    )

    try {
        $urlAddAccess = "https://api.powerbi.com/v1.0/myorg/admin/groups/$workspaceId/users"
        $bodyAddAccess = @{
            "principalType" = $principalType
            "groupUserAccessRight" = $groupUserAccessRight
        }

        if ($principalType -eq "User") {
            $bodyAddAccess["emailAddress"] = $emailAddress
        } else {
            $bodyAddAccess["identifier"] = $identifier
        }

        $bodyAddAccess = $bodyAddAccess | ConvertTo-Json
        Invoke-PowerBIRestMethod -Url $urlAddAccess -Method Post -Body $bodyAddAccess -ContentType "application/json" -ErrorAction Stop

        return @{
            Status = "Success"
            Description = "Access added successfully."
        }
    } catch {
        return @{
            Status = "Failure"
            Description = "Error adding access: $_.Exception.Message"
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

    # Add the user access to the workspace
    $addAccessResult = Add-UserAccessToWorkspace -workspaceId $workspaceId -identifier $identifier -principalType $principalType -groupUserAccessRight $groupUserAccessRight -emailAddress $emailAddress
    
    if ($addAccessResult.Status -eq "Success") {
        if ($principalType -eq "User"){
            Write-Log -message "Added $principalType $displayName ($emailAddress) with $groupUserAccessRight access to workspace $workspaceId."
        } else {
            Write-Log -message "Added $principalType $displayName ($identifier) with $groupUserAccessRight access to workspace $workspaceId."
        }
        $status = "Success"
        $description = $addAccessResult.Description
    } else {
        Write-Log -message "Error adding $emailAddress with $groupUserAccessRight access to workspace $workspaceId. $addAccessResult.Description" -type "ERROR"
        $status = "Failure"
        $description = $addAccessResult.Description
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

Write-Output "Access restoration process completed. Check the log file and updated CSV file for details."