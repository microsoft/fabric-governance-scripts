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
        IMPORT_CSV[Import CSV w/ Workspaces] --> AUTHENTICATE_PBI[Authenticate to Power BI as Admin]
        AUTHENTICATE_PBI --> SCAN_WS[Scan Workspace to validate if it's Empty]
        SCAN_WS --> VALIDATE_EMPTY{Is the Workspace Empty?}
        VALIDATE_EMPTY -->|Yes| ADD_ADMIN[Add User as Workspace Admin]
        
        subgraph Delete_Empty ["**Delete Workspaces**"]
            direction TB
            ADD_ADMIN --> DELETE_WS[Delete the Workspace]
            DELETE_WS --> WS_DELETED{Was the Workspace Deleted?}
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