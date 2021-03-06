#Requires -Version 2.0
Function Get-FSMORoleHolder
{
    <#
    .Synopsis
        Retrieves the forest and domain FSMO roles holders.

    .Description
        Retrieves the forest and domain FSMO roles holders.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 18:16

    .Inputs
        System.String

    .Parameter forestFQDN
        FQDN of the target forest

    .Parameter domainFQDN
        FQDN of the target domain

    .Outputs
        System.Management.Automation.PSCustomObject

    .Example
        Get-FSMORoleHolder
        -----------
        Description
        Gets FSMO Roles from currest domain and forest

    .Example
        Get-FSMORoleHolder -forestFQDN "forest.com" -domainFQDN "domain.forest.com"
        -----------
        Description
        Gets FSMO Roles from the domain "domain" and forest "forest.com"

    .Link
        Get-Domain
        Get-Forest
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('[a-zA-Z0-9_\-]{1,63}\.+[a-zA-Z.]{2,}$')]
        [Parameter()]
        [string]$forestFQDN,

        [ValidateNotNullOrEmpty()]
        [ValidatePattern('(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)')]
        [Parameter()]
        [string]$domainFQDN
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        if (!(Test-Path function:Get-Domain))
            {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-Domain'. Please make sure it's loaded."}
        if (!(Test-Path function:Get-Forest))
            {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-Forest'. Please make sure it's loaded."}
    }

    Process
    {
        if ($domainFQDN)
            {$domain = Get-Domain $domainFQDN}
        else
            {$domain = Get-Domain}
        if ($forestFQDN)
            {$forest = Get-Forest $forestFQDN}
        else
            {$forest = Get-Forest}

        $pso = "" | select Naming,Schema,Pdc,Rid,Infrastructure

        $pso.Naming = $forest.NamingRoleOwner
        $pso.Schema = $forest.SchemaRoleOwner
        $pso.Pdc = $domain.PdcRoleOwner
        $pso.Rid = $domain.RidRoleOwner
        $pso.Infrastructure = $domain.InfrastructureRoleOwner
        $pso
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}