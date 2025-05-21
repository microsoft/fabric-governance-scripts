---
title: Process - Save Access from Empty Workspaces 
config:
  theme: base
---
flowchart TD
    subgraph Identify_Empty_Workspaces["**Identify Empty Workspaces**"]
        PBI_ASSESSMENT@{ shape: subproc, label: "Power BI Assessment" } --> EXPORT_WS[Export Empty Workspaces]
    end

    subgraph Retrieve_Access["**Save Access from Inactive Workspaces**"]
        direction TB
        IMPORT_CSV[Import CSV w/ Workspaces] --> AUTHENTICATE_PBI[Authenticate to Power BI as Admin]
        AUTHENTICATE_PBI --> USER_AUTHENTICATED{"Is User Authenticated?"}
        USER_AUTHENTICATED --> |No| LOG_ERROR
        USER_AUTHENTICATED --> |Yes| GET_ACCESS_DETAILS
        GET_ACCESS_DETAILS["Get Access Details for each Workspace (PBI API: Groups)"]
        GET_ACCESS_DETAILS --> ACCESS_RETRIEVED{Was Access Retrieved?}
        ACCESS_RETRIEVED -->|Yes| EXPORT_CSV[Export Access Details to CSV]
        ACCESS_RETRIEVED -->|No| LOG_ERROR[Log Error]
        EXPORT_CSV --> LOG_SUCCESS[Log Success]
    end     
  
    
START([Start]) --> Identify_Empty_Workspaces 
EXPORT_WS -.- |"CSV with Inactive Workspaces Id (*inactive_workspaces.csv*)"| IMPORT_CSV
LOG_ERROR  --> END([End]) 
LOG_SUCCESS --> END


Retrieve_Access -.- |Log Operations| L@{ shape: doc, label: "Operations Log (*getworkspacelog.log*)"}
Retrieve_Access -.- |Access Details| T@{ shape: doc, label: "Workspace Access Details (*inactive_workspaces_access.csv*)"}
%% Invisible relation just to improve visibility
L ~~~ T