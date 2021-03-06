#Requires -Version 2.0
Function Get-ObjectBySID
{
    <#
    .Synopsis
        Retrieves domain account for known SID.

    .Description
        Retrieves domain account for known SID.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 18:00

    .Inputs
        System.String

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Example
        Get-ObjectBySID -SID  'S-1-5-21-3889274798-524451202-2197197945-1112'

    .Link
        Get-Object
        Get-ObjectSID
        Get-User
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^S\-1\-(1|3|5)\-(([\d]+)|[\d]+\-[0-9\-]+)$')]
        [Parameter(ValueFromPipeline=$true,mandatory=$true)]
        [string[]]$SID
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        if (!(Test-Path function:Get-User))
            {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-User'. Please make sure it's loaded."}
        }

    Process
    {
        foreach ($id in $SID)
        {
            $si = New-Object System.Security.Principal.SecurityIdentifier $id

            if ($si.IsAccountSid())
            {
                $user = Get-User ($si.Translate([System.Security.Principal.NTAccount]).Value)
                if ($user)
                    {$user}
                else
                    {$si.Translate([System.Security.Principal.NTAccount]).Value}
            }
            else
                {Write-Warning "$($MyInvocation.MyCommand.Name):: '$si' is not a valid Windows account SID."}
        }
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}