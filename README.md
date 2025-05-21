# Fabric Governance Scripts

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/powershell/)

A collection of PowerShell scripts to automate governance actions in Microsoft Fabric environments. These scripts help keep your environment clean by safely removing user access from workspaces, deleting empty workspaces, and restoring access when needed. New scripts will be added as required.

> <strong>ATTENTION</strong></span>
> This repo is not an official Microsoft product! There is no official support available and scripts may break with platform changes. Carefully evaluate each script before running in production.

---

## Table of Contents
- [Features](#features)
- [Workspace CleanUp Scripts](#workspace-cleanup-scripts)
- [Getting Started](#getting-started)
- [Folder Structure](#folder-structure)
- [Contributing](#contributing)
- [License](#license)

---

## Features
- Backup user access assignments for workspaces
- Remove user, group, and service principal access from workspaces
- Restore workspace access from backup
- Delete empty workspaces safely
- Logging and CSV output for audit and rollback

## Workspace CleanUp Scripts
- **[Get Access from Inactive Workspaces](/GetAccessInactiveWorkspaces/):** Backup user assignments before removal operations. Useful for regular or ad-hoc cleanups and for restoring access if a workspace becomes active again.
- **[Remove Accesses from Workspaces](/RemoveAccessfromWorkspaces/):** Remove user/group/service principal access from workspaces, ensuring a new admin is assigned to prevent orphaned workspaces.
- **[Restore Workspace Access](/RestoreWorkspaceAccess/):** Restore access to workspaces from a previously exported backup.
- **[Remove Empty Workspaces](/RemoveEmptyWorkspaces):** Delete empty workspaces after verifying they are safe to remove. All actions are logged and status is output to CSV.

## Getting Started
### Prerequisites
- **PowerShell 5.1 or newer**
- **MicrosoftPowerBIMgmt** module installed:
  ```powershell
  Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
  ```
- **Fabric Administrator** privileges
- Input CSV files as described in each script's README

### Quick Usage Example
See each script's folder for detailed usage and input/output examples:
- [GetAccessInactiveWorkspaces/README.MD](GetAccessInactiveWorkspaces/README.MD)
- [RemoveAccessfromWorkspaces/README.MD](RemoveAccessfromWorkspaces/README.MD)
- [RestoreWorkspaceAccess/README.MD](RestoreWorkspaceAccess/README.MD)
- [RemoveEmptyWorkspaces/README.MD](RemoveEmptyWorkspaces/README.MD)

## Folder Structure
```
GetAccessInactiveWorkspaces/   # Backup user access assignments
RemoveAccessfromWorkspaces/    # Remove user/group access from workspaces
RestoreWorkspaceAccess/        # Restore access from backup
RemoveEmptyWorkspaces/         # Delete empty workspaces
```
Each folder contains:
- PowerShell script(s)
- Sample input/output files
- Flowchart of the process
- Detailed README

## Contributing
Contributions are welcome! Please open an issue or submit a pull request. For major changes, open an issue first to discuss what you would like to change.

## License
This project is provided as-is, without warranty. See the [DISCLAIMER](#introduction) above. If you wish to use this in a commercial or production environment, review and test thoroughly.

---

For questions or suggestions, please open an issue in this repository.