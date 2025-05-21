# Remove Empty Workspaces
This PowerShell script can be used to eliminate empty workspaces from Fabric environment. This can help in regular clean up routines or ad-hoc removal.

### Pre-Requirements
To run this script you need: 
- A **list of IDs of empty workspaces** to be removed (obtained via a previous assessment, not part of the scope of current script);
- **Powershell 5.1** (or more recent);
- The **_MicrosoftPowerBIMgmt_** installed in PowerShell. You can install it using the following command if it's not already installed:
 ```powershell
 Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
 ```
- An user with **Fabric Administrator** privileges.

### Overview
The following diagram demonstrates the overall clean up process. The steps demonstrated in the **"Remove Empty Workspaces"** are implemented in this script:

```mermaid
---
title: Process - Remove Empty Workspaces
config:
  theme: base
---
flowchart TB 
    subgraph Identify_Empty_Workspaces["**Identify Empty Workspaces**"]
        PBI_ASSESSMENT@{ shape: subproc, label: "Power BI Assessment" } --> EXPORT_WS[Export Empty Workspaces]
    end
    
    subgraph Clean_Empty_Workspaces ["**Remove Empty Workspaces**"]
        direction TB
        IMPORT_CSV[Import CSV w/ Workspaces] --> AUTHENTICATE_PBI["Authenticate to Power BI as Admin"]
        AUTHENTICATE_PBI --> SCAN_WS["Scan Workspace to validate if it's Empty"]
        SCAN_WS --> VALIDATE_EMPTY{"Is the Workspace Empty?"}
        VALIDATE_EMPTY -->|Yes| ADD_ADMIN["Add User as Workspace Admin"]
        
        subgraph Delete_Empty ["**Delete Workspaces**"]
            direction TB
            ADD_ADMIN --> DELETE_WS[Delete the Workspace]
            DELETE_WS --> WS_DELETED{"Was the Workspace Deleted?"}
            WS_DELETED --> |No| REMOVE_ADMIN["Remove User as Workspace Admin (Rollback)"]
            
        end  
    end
    
START([Start]) --> Identify_Empty_Workspaces
EXPORT_WS --> |"CSV with Empty Workspaces Id (*ws_input.csv*)"| IMPORT_CSV
VALIDATE_EMPTY -->|No - Unable to Delete | END 
WS_DELETED --> |Yes - Deletion Complete| END([End]) 
REMOVE_ADMIN --> END
Clean_Empty_Workspaces -.- |Log Operations| L@{ shape: doc, label: "Operations Log (*ws_deletion.log*)"}
Delete_Empty -.- |Deletion Status| T@{ shape: doc, label: "Deletion Status per Workspace (*ws_deletion_status.csv*)"}
%% Invisible relation just to improve visibility
L ~~~ T
```

### Important
Before running this or any other script that may remove content from Fabric, it's important to verify **Worspace Retention** configuration and increase the retention time according to your organization's policies for data retention. 
See this link for more information on how to configure [Workspace Retention in Fabric](https://learn.microsoft.com/en-us/fabric/admin/portal-workspaces#workspace-retention)
