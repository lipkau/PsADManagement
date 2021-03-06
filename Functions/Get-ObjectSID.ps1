#Requires -Version 2.0
Function Get-ObjectSID
{
    <#
    .Synopsis
        Retrieves AD objects SID.

    .Description
        Retrieves AD objects SID.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 13:25

    .Inputs
        System.DirectoryServices.DirectoryEntry

    .Outputs
        System.String

    .Example
        Get-ObjectSID (Get-User johndoe -SearchRoot domain.com)
        -----------
        Description
        Gets the SID of a specific user

    .Example
        Get-ObjectSID -InputObject 'CN=Guest,CN=Users,DC=Domain,DC=com'
        -----------
        Description
        Gets the SID using the object's DN

    .Link
        Get-Object
        Get-ObjectBySID
        Get-User
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true,mandatory=$true,HelpMessage="Object to get the SID")]
        [ADSI[]]$InputObject
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        foreach ($obj in $InputObject)
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing Object: $($obj.cn)"
            if([ADSI]::Exists($obj.Path))
            {
                $objectSid = [byte[]]$obj.objectSid.value
                $sid = new-object System.Security.Principal.SecurityIdentifier $objectSid,0
                $sid.value
            } else
                {Write-Warning "$($MyInvocation.MyCommand.Name):: Object could not be found."}
        }
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}