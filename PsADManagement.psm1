#Requires -Version 2.0
<#
    .Synopsis
        This is a compilation of functions to simplify scripts to manage AD tasks

    .Description
        This compilation contains functions to simplify the management of Active Directories.
        Check the examples to see how to find computers, create new users, and much more.

    .Notes
        Author   : Oliver Lipkau <oliver@lipkau.net>
        Thanks to:
            YetiCentral\bshell <www.bsonposh.com>

        ChangeLog:
            2010/05/24 23:42      Created
            2010/05/30            Added Get-NearestDC
            2010/06/04            Added Test-SameSubnet
                                  Added Get-DomainRoot
            2010/06/09 14:51      Enabled Get-Help
            2010/06/09            Added Test-IsRODC
            2010/06/21            Adapted to module
            2010/07               Added New-Computer
                                  Added New-Group
                                  Added New-OU
            2010/08/25 18:31      Updates in all script (only accept adsi objects)
            2010/08/27 21:51      Added Get-ADACL
            2010/08/28 07:11      Added Set-ADACL
            2010/08/28 09:35      Added Rename-Object
            2010/08/28 10:39      Added Get-IPSite
            2010/08/29 15:06      Added Set-DomainMode
            2010/08/29 15:17      Added Set-ForestMode
            2010/10/13 09:24      Added Get-object
            2010/10/13 09:24      Added -credential switch to functions
            2010/10/29 14:51      Added Get-RODC
            2010/12/12            Added Remove-OU
            2010/12/12            Added Set-Computer
            2010/12/12            Added Remove-OU
            2010/12/12            Added Set-OU
            2011/08/13 11:44      Added Get-StaleComputerAccounts
            2015/06/20            Improvment Migration to GitHub
                                  Improvment Migrate to semantic versioning
                                  IMprovment Moved ps1 files to FUnctinos folder
            2016/03/03            Added ConvertFrom-ADSLargeInteger

        ToDo:

             - Get-DOmaincontollers to use get-domain?
             - set HelpMessage
             - Add DisableProtectFromDeletion and enable to all set-* and new-*
             - shouldprocess ("Would do ...","do ...?","doing ...")


            get ip from ping?
            check shouldprocess is in right place.
            Test if function need Credentials

            -Passthru

            Test get-domin/forest in non-domain pc

            Test:
                Get-EmptyGroup
                Get-GroupMember
                Get-GroupMembership
                Get-IPSite
                Get-Object (-recurse)
                Get-RODC
                New-User : add set-user? : AccountExpires
                Remove-GroupMember
                Set-User : UserCannotChangePassword + more : AccountExpires
                Test-IsRODC
                Get-StaleComputer

            Add:
                Get-AltRecipient
                New-Object
                Set-Group
                Set-User -> Try/Catch : AccountExpires
                Test-ADReplication
                Unlock-Account

    .Table of Content
    .Link
        Add-GroupMember
        ConvertTo-ADSLargeInteger
        Disable-Account
        Enable-Account
        Get-ADACL
        Get-Computer
        Get-Domain
        Get-DomainControllerInfo
        Get-DomainControllers
        Get-DomainPasswordPolicy
        Get-DomainRoot
        Get-EmptyGroup
        Get-Forest
        Get-FSMORoleHolder
        Get-Group
        Get-GroupMember
        Get-GroupMembership
        Get-IPSite
        Get-NearestDC
        Get-Object
        Get-ObjectBySID
        Get-ObjectSID
        Get-RODC
        Get-StaleComputer
        Get-User
        Impersonation
        Move-Object
        New-Computer
        New-Group
        New-OU
        New-Password
        New-User
        Remove-GroupMember
        Remove-Object
        Rename-Object
        Set-ADACL
        Set-Computer
        Set-DomainMode
        Set-ForestMode
        Set-OU
        Set-User
        Test-IsRODC
        Test-SameSubnet
#>
param()

$ScriptPath = $MyInvocation.MyCommand.Path
$ADManagementModuleHome = split-path -parent $ScriptPath

Get-ChildItem "$ADManagementModuleHome\Functions" *.ps1 | ForEach-Object {
    . $_.FullName
}
