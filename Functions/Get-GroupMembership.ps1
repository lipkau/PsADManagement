#Requires -Version 2.0
function Get-GroupMembership
{
    <#
    .Synopsis
        Retrieves all groups to which an object belongs.

    .Description
        Retrieves all groups to which an object belongs.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 18:09

    .Inputs
        System.DirectoryServices.DirectoryEntry

    .Parameter InputObject
        DN of the Object to get groups it belongs to. Can be an array

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Example
        Get-Computer Server1 | Get-GroupMembership -Resolve
        -----------
        Description
        Retrieves all groups to which computer Server1 belongs and returns the results as DirectoryEntry types

    .Example
        Get-User Test1 | Get-GroupMembership -ExpandNested
        -----------
        Description
        Retrieves all groups to which user Test1 belongs, including nested ones

    .Link
        Get-User
        Get-Computer
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true,mandatory=$true)]
        [ADSI]$InputObject,

        [switch]$Recurse
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing Object: $($object.cn)"
        if($InputObject.MemberOf -and [ADSI]::Exists($object.Path))
        {
            if (!($InputObject.MemberOf))
                {return $false}
            $InputObject.MemberOf | `
            foreach `
            {
                $object = [ADSI]"LDAP://$_"
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing Group: $($object.cn)"
                if($Recurse)
                    {$object  | Get-GroupMembership -ExpandNested}
                else
                    {$object}
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended Processing $($object.cn)"
            }
        } else
            {Write-Warning "$($MyInvocation.MyCommand.Name):: Object could not be found."}
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended Processing Object: $($InputObject.cn)"
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}