---
title: Process - Restore Access to Workspaces
config:
  theme: base
---
flowchart TB 
    subgraph Restore_Access_Workspace["**Identify Empty Workspaces**"]
        PBIAssessment@{ shape: subproc, label: "Save Access from Inactive Workspaces" }
        SaveAccessInactiveWS@{ shape: subproc, label: "Save Access from Inactive Workspaces" }
        PBIAssessment --> SaveAccessInactiveWS
    end
    
    subgraph Restore_Access_WS ["**Restore Access to Workspace**"]
        direction TB
        IMPORT_CSV[Import CSV w/ Access Details] --> AUTHENTICATE_PBI[Authenticate to Power BI as Admin]
        AUTHENTICATE_PBI --> ADD_ACCESS["Add Users to the Workspace"]
        ADD_ACCESS --> EXPORT_ACCESS_Restore["Export Access Restore status (per user)"]
        
    end

EXPORT_ACCESS_Restore --> END([End])
START([Start]) --> Restore_Access_Workspace
SaveAccessInactiveWS --> |"CSV with Workspace Access (*timestamp_inactive_workspace_access.csv*)" | IMPORT_CSV
Restore_Access_WS -.- |Log Operations| L@{ shape: doc, label: "Operations Log (*timestamp_restoreaccesslog.log*)"}
Restore_Access_WS -.- |Deletion Status| T@{ shape: doc, label: "Deletion Status per Workspace (*timestamp_restored_access_status.csv*)"}
%% Invisible relation just to improve visibility
L ~~~ T