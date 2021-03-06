#Requires -Version 2.0
Function Get-Forest
{
    <#
    .Synopsis
        Retrieves forest information like Domains, Sites, ForestMode, RootDomain, and Forest masters.

    .Description
        Retrieves forest information like Domains, Sites, ForestMode, RootDomain, and Forest masters.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 18:17

    .Inputs
        System.String

    .Parameter forest
        FQDN of the target forest

    .Outputs
        System.DirectoryServices.ActiveDirectory.Forest

    .Example
        (Get-Forest).GlobalCatalogs
        -----------
        Description
        Retrieves the global catalogs information

    .Example
        Get-Forest forest.com
        -----------
        Description
        Retrieves forest information of forest.com

    .Link
        Get-Domain
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('[a-zA-Z0-9_\-]{1,63}\.+[a-zA-Z]{2,}$')]
        [Parameter(ValueFromPipeline = $true)]
        [string]$forest
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        if (!($forest))
            {[System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()}
        else
        {
            $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest",$forest)
            [system.directoryservices.activedirectory.forest]::GetForest($context)
        }
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}