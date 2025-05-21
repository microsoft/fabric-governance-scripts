# Remove Accesses from Workspaces
This PowerShell script can be used to remove user's access from a workspace. The script will first add a new admin to the workspace to avoid it to become "orphaned" and then will remove each user, group and service principal access of this workspace. As a input, this script must use the csv file output from script `GetAccessInactiveWorkspaces.ps1`.

This script is meant to be used as part of clean up routines, for example, temporarily removing user access from the workspace before eliminating then definitively. You can use script `RestoreWorkspaceAcccess.ps1` to restore access to the workspace in case of user's request to revert effects from current script execution.  

### Pre-Requirements
To run this script you need: 
- A csv file with **worspaces ids and user access** from a previous backup. See **inputs** below for more details;
- **Powershell 5.1** (or more recent);
- The **_MicrosoftPowerBIMgmt_** installed in PowerShell. You can install it using the following command if it's not already installed:
 ```powershell
 Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
 ```
- An user with **Fabric Administrator** privileges.

### Overview
The following diagram demonstrates the overall process to remove access from the workspaces. The steps demonstrated in the **"Remove Access from Workspaces"** are implemented in this script:

```mermaid
---
title: Process - Remove Users, Service Principals, and Groups Access from Workspaces
config:
  theme: base
---
flowchart TB
    subgraph Identify_Empty_Workspaces["**Identify Empty Workspaces**"]
        PBIAssessment@{ shape: subproc, label: "Save Access from Inactive Workspaces" }
        SaveAccessInactiveWS@{ shape: subproc, label: "Save Access from Inactive Workspaces" }
        PBIAssessment --> SaveAccessInactiveWS
    end

  subgraph Remove_User_Access["**Remove Access from Workspaces**"]
    AUTHENTICATE[Authenticate to Power BI] --> IMPORT_CSV[Import CSV with Access Details]
    
    subgraph Process_Entries["**Process Access Entries**"]
        CHECK_ADMIN{Is Admin already in the Workspace?}
        CHECK_ADMIN -->|No| ADD_ADMIN[Add Admin to Workspace]
        CHECK_ADMIN -->|Yes| REMOVE_ACCESS["Remove Workspaces Access (except for new Admin)"]
        ADD_ADMIN -->|Success| REMOVE_ACCESS
        ADD_ADMIN -->|Failure| LOG_ADD_ADMIN_ERROR[Log Admin Addition Error]
        REMOVE_ACCESS --> |Log|LOG_REMOVE_SUCCESS["Log Access Removal Status (per principal)"]
        REMOVE_ACCESS --> |csv|EXPORT_CSV[Export Updated Access Details to CSV]
    end 
  end


START([Start]) --> Identify_Empty_Workspaces
SaveAccessInactiveWS --> |"CSV with Workspace Access (*timestamp_inactive_workspace_access.csv*)" | AUTHENTICATE

IMPORT_CSV --> |For each entry| CHECK_ADMIN
EXPORT_CSV --> END
LOG_ADD_ADMIN_ERROR --> END([End])
Remove_User_Access -.- |Log Operations| L@{ shape: doc, label: "Operations Log (*timestamp_removeaccesslog.log*)"}
Remove_User_Access -.- |Deletion Status| T@{ shape: doc, label: "Deletion Status per Workspace (*timestamp_updated_access_status.csv*)"}
%% Invisible relation just to improve visibility
L ~~~ T
```

### Script Inputs and Outputs
- **Input**: 
-- **`<timestamp>_inactive_workspace_access.csv`**: the list of workspaces with corresponding access. The list will includes principals (Users, Groups, Service Principal) and corresponding access in the workspace (Admin, Viewer, Contributor, etc). See example on `inactive_workspaces_access (SAMPLE).csv`;
- **Output**:
-- **`<timestamp>_updated_access_status.csv`**: outputs the list of workspaces with corresponding user access and access removal status. Principals that were removed will appear as "Removed", while issues in processing a removal will appear as "Not Removed" with a description of the reason. See example on `updated_access_status (SAMPLE).csv`;
-- **`<timestamp>_removeaccesslog.log`**: A log with main script steps execution process. Use it to troubleshoot execution. See example in `removeaccesslog (SAMPLE).log`.   

### Important
This script will remove access to the workspaces only. It's important to check if there are other access directly to workspace items, like Reports and Semantic models, but this is not part of the scope of this script as the focus of the clean up process is targeting empty workspaces.