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