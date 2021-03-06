#Requires -Version 2.0
Function Get-NearestDC
{
    <#
    .Synopsis
        Findes the localhost's nearest Domain Controller

    .Description
        Findes the localhost's nearest Domain Controller

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 18:08

    .Inputs
        System.DirectoryServices.DirectoryEntry

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Example
        Get-NearestDC
        -----------
        Description
        Finds the nearest DC for the current site

    .Example
        Get-NearestDC -Domain "corp.contoso.com"
        -----------
        Description
        Finds the nearest DC from a specific domain

    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/

    .Notes
        ToDo:
            Get-DOmain?
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^.*\..+\.(net|com)$')]
        [Parameter(ValueFromPipeline = $true)]
        [string]$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
    )
    # This function follows this logic:
    # 1. Get the details for the site that this script is being run in.
    # 2. Get the list of domain controllers for the specified domain.
    # 3. Return the first match found.
    # 4. If no matches, repeat (3) for sites that connect to this site.
    # 5. If still no matches, return the first DC in the collection.

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching for DC from: $domain"
        # Get the details for this site
        $site = [System.DirectoryServices.ActiveDirectory.ActiveDirectorysite]::GetComputerSite()
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching DC in: $site"
        $ThisSiteName = $site.Name
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Current site is $ThisSiteName"

        # Get the details for the specified domain
        #Get-Domain $domain
        $domtype = [System.DirectoryServices.ActiveDirectory.DirectoryContexttype]"Domain"
        $domcntxt = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext($domtype, $domain)
        $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($domcntxt)

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Checking DCs for this site"
        $dom.DomainControllers | %  `
        {
            if ($_.SiteName -eq $ThisSiteName)
                {$_.GetDirectoryEntry();break}
        }

        # Failed to match - try another site
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Checking connected sites"
        $site.AdjacentSites | % `
        {
            $ThisSiteName = $_.Name
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Now testing site $ThisSiteName"
            $dom.DomainControllers | % `
            {
                if ($_.SiteName -eq $ThisSiteName)
                    {$_.GetDirectoryEntry();break}
            }
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished testing site $ThisSiteName"
        }

        # Failed that as well - return the first DC for the domain
        $dc = $dom.DomainControllers
        $dc[0].GetDirectoryEntry()
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}