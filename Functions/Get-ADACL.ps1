#Requires -Version 2.0
function Get-ADACL
{
    <#
    .Synopsis
        Gets ACL object or SDDL for AD Object

    .Description
        Gets ACL object or SDDL for AD Object

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/26 23:38

        Original  : YetiCentral\bshell <www.bsonposh.com>

    .Inputs
        System.DirectoryServices.DirectoryEntry

    .Parameter InputObject
        Object to Get the ACL from

    .Output
        System.DirectoryServices.ActiveDirectoryAccessRule
        System.String

    .Example
        Get-User "Administrator" | Get-ADACL
        -----------
        Description
        Get ACL for all Get-User results

    .Example
        Get-ADACL (Get-Object "cn=users,dc=domain,dc=com") -SDDL
        -----------
        Description
        Get SDDL for Users container

    .Link
        Get-Computer
        Get-OU
        Get-Object
        Get-User
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [Cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline=$true,Mandatory=$True)]
        [ADSI[]]$InputObject,

        [switch]$SDDL
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        foreach ($object in $inputobject)
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing $($Object.DistinguishedName)"

            $acl = $Object.psbase.ObjectSecurity
            if($SDDL)
            {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Returning SDDL"
                $acl.GetSecurityDescriptorSddlForm([System.Security.AccessControl.AccessControlSections]::All)
            } else {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Returning ACL"
                $acl.GetAccessRules($true,$true,[System.Security.Principal.SecurityIdentifier])
            }
        }
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}