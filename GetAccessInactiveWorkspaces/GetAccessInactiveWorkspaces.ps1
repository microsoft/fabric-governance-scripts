<# 
.SYNOPSIS
Get the current access to the workspaces in the input file and save them for future reference (to serve as a backup, for example)

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

# Path to the input file with the list of workspaces
$InputFilePath = "C:\Example\Inactive\inactive_workspaces.csv"

# Directory for the generated CSV file
$OutputDirectory = "C:\Example\Inactive\"

# Path to the log file
$logFilePath = "C:\Example\Inactive\" + $timestamp + "_getworkspacelog.log"

# Logging function
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

# Authenticate with the Power BI API
try {
    Connect-PowerBIServiceAccount
    Write-Log -message "Authenticated with the Power BI API."
} catch {
    Write-Log -message "Error authenticating with the Power BI API. $_" -type "ERROR"
    exit
}

# Read the list of inactive workspaces from the CSV file
try {
    $inactiveWorkspaces = Import-Csv -Path $InputFilePath | Select-Object -ExpandProperty workspaceid
    Write-Log -message "List of inactive workspaces read from the CSV file."
} catch {
    Write-Log -message "Error reading the list of workspaces from the CSV file. $_" -type "ERROR"
    exit
}

# Create a list to store access details
$accessDetails = @()

# Get access details using the Admin API
foreach ($workspaceId in $inactiveWorkspaces) {
    try {
        $url = "https://api.powerbi.com/v1.0/myorg/admin/groups/$workspaceId/users"
        Write-Log -message "Trying to retrieve access information for workspace $workspaceId."
        $response = Invoke-PowerBIRestMethod -Url $url -Method Get -ErrorAction Stop

        if ($response -ne $null){
            $response = $response | ConvertFrom-Json
            Write-Log -message "Successfully retrieved access from workspace $workspaceId."

            foreach ($user in $response.value) {
                $accessDetails += [pscustomobject]@{
                    workspaceId = $workspaceId
                    emailAddress = $user.emailAddress
                    displayName = $user.displayName
                    identifier = $user.identifier
                    principalType = $user.principalType
                    groupUserAccessRight = $user.groupUserAccessRight
                    executionTimestamp = $timestamp
                }
            }
        }
        else {
            Write-Log -message "Error obtaining access information from workspace $workspaceId. Check if the workspace still exists or try again if this is a transient issue.".  -type "ERROR"
        }

    } catch {
        # Log detailed error information
        $errorMessage = $_.Exception.Message -replace "(\r\n|\n)"," "
        $errorDetails = $_.Exception.StackTrace -replace "(\r\n|\n)", " "
        Write-Log -message "Exception when obtaining access information for workspace $workspaceId. Check if still exists - Error Message: $errorMessage - Error Details: $errorDetails" -type "ERROR"
    }
}

$outputFilePath = "$OutputDirectory" + $timestamp + "_inactive_workspaces_access.csv"

# Save the details to a CSV file
try {
    $accessDetails | Export-Csv -Path $outputFilePath -NoTypeInformation
    Write-Log -message "Access details saved to $outputFilePath."
} catch {
    Write-Log -message "Error saving access details to $outputFilePath. $_" -type "ERROR"
}

Write-Output "Access to Inactive Workspaces was saved to $outputFilePath"