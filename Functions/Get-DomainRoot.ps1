#Requires -Version 2.0
function Get-DomainRoot
{
    <#
    .Synopsis
        Retrieves the Domain Root of any DN.

    .Description
        Retrieves the Domain Root of any DN.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/05/24 23:11

    .Inputs
        System.String

    .Parameter Path
        DN path from which you want the root

    .Outputs
        System.String

    .Example
        Get-DomainRoot -Path 'OU=TEST,DC=Domain,DC=com'
        -----------
        Description
        Gets the domain root 'DC=Domain,DC=com'

    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^((CN|OU)=.*)*(DC=.*)*$')]
        [Parameter(ValueFromPipeline = $true,mandatory=$true)]
        [string]$path
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Getting root for: $path"
        $path = $path.replace(";",",")
        $arr = $path.split(",")
        $out = ""
        foreach ($i in $arr)
        {
            if ($i -match "dc=(.*)")
                {$out += $i + ","}
        }
        $out.Remove($out.Length -1)
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}