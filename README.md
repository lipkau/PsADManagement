# [PsADManagement](http://lipkau.github.io/PsADManagement/)
## Description  
This compilation contains functions to simplify the management of Active Directories.
Check the examples to see how to find computers, create new users, and much more.

_(tested with: Windows Server(r) 2003 R2, Windows Server(r) 2008, Windows Server(r) 2008 R2)_

## Table of Contents  
* [Description](#description)
* [Background](#background)
* [Functions/Feature](#functionsfeature)
* [Usage](#usage)
* [Authors/Contributors](#authorscontributors)

## Background
> Microsoft introduced a built-in PowerShell module for managing Active Directory in Windows 2008R2(r). However, I have two problems with this module:
> * It is only available on the server and I want to be able to run stuff (most of all Get-* commands) from my local computer
> * It doesn’t work with Windows 2008 and 2003 ADs and DCs
> 
> So I decided to write my own set of functions, which soon turned into a complete module. Since it is supposed to be a tool to work mainly with older servers, it’s time to finally publish it (Although it is not 100% yet).
> 
> There might still be bugs in the functions.

_This was first published @ http://oliver.lipkau.net/blog/admanagement-module on 2011/07/18_

## Functions/Feature  
* Add-GroupMember
* Disable-Account
* Enable-Account
* Get-ADACL
* Get-Computer
* Get-Domain
* Get-DomainControllerInfo
* Get-DomainControllers
* Get-DomainPasswordPolicy
* Get-DomainRoot
* Get-EmptyGroup
* Get-Forest
* Get-FSMORoleHolder
* Get-Group
* Get-GroupMember
* Get-GroupMembership
* Get-IPSite
* Get-NearestDC
* Get-Object
* Get-ObjectBySID
* Get-ObjectSID
* Get-RODC
* Get-StaleComputer
* Get-User
* Impersonation
* Move-Object
* New-Computer
* New-Group
* New-OU
* New-Password
* New-User
* Remove-GroupMember
* Remove-Object
* Rename-Object
* Set-ADACL
* Set-Computer
* Set-DomainMode
* Set-ForestMode
* Set-OU
* Set-User
* Test-IsRODC
* Test-SameSubnet

## Usage
### Load the Module
Unzip the content of the file to: C:\Users\_<your user name>_\Documents\WindowsPowerShell\Modules\ADManagement, open powershell and run `Import-Module PsADManagement`

### Examples
_Yet to come_

## Authors/Contributors  
* [Oliver Lipkau](http://oliver.lipkau.net)
* [YetiCentral\bshell](http://www.bsonposh.com)