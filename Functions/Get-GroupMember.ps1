#Requires -Version 2.0
function Get-GroupMember
{
    <#
    .Synopsis
        Retrieves the members of a group in Active Directory.

    .Description
        Retrieves the members of a group in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 18:11

    .Inputs
        System.DirectoryServices.DirectoryEntry

    .Parameter Group
        Group to retrieve members.

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Example
        Get-Group TestGroup | Get-GroupMember
        -----------
        Description
        Retrieves all members of a group TestGroup

    .Example
        Get-Group -Name "group01" -SearchRoot "domain.com" | Get-GroupMember -Resolve

    .Link
        Get-Group
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true,mandatory=$true)]
        [ADSI]$Group,

        [switch]$Resolve
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing Group: $($Group.cn)"
        if($Group.psbase.SchemaClassName -eq 'group' -and [ADSI]::Exists($Group.Path))
        {
            if (!($Group.member))
                {return $false}
            if ($Resolve)
            {
                $Group.member | `
                Foreach `
                    {[ADSI]"LDAP://$_"}
            } else
                {$Group.member}
        } else
            {Write-Warning "$Group is not a valid object type (only 'Group' objects are allowed) or it could not be found."}
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended Processing Group: $($Group.cn)"
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}