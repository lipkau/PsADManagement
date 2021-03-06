#Requires -Version 2.0
function Set-ForestMode
{
    <#
    .Synopsis
        Modifies the forest functionality.

    .Discription
        Modifies the forest functionality.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 11:56

    .Inputs
        System.String

    .Parameter Forest
        Forest you want to change

    .Parameter Funcionality
        New Functionality Level. Options:
            Windows2000Forest
            Windows2003InterimForest
            Windows2003Forest
            Windows2008Forest
            Windows2008R2Forest

    .Example
        Set-ForestMode "Windows2008Forest"
        -----------
        Description
        Changes the functionality of the current forest to Windows 2008 Forest

    .Link
        Get-Domain
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium"
    )]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(mandatory=$true,HelpMessage="New Functionality Level")]
        [ValidateSet("Windows2000Forest","Windows2003InterimForest","Windows2003Forest","Windows2008Forest","Windows2008R2Forest")]
        [string]$Funcionality,

        [ValidateNotNullOrEmpty()]
        [ValidatePattern('[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)')]
        [Parameter(ValueFromPipeline = $true)]
        [string]$forest,

        [System.Management.Automation.PSCredential]$Credential
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        if (!(Test-Path function:Get-Forest))
            {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-Forest'. Please make sure it's loaded."}

        if ($Credential)
        {
            if (!(Test-Path function:Push-ImpersonationContext))
               {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Push-ImpersonationContext'. Please make sure it's loaded."}
            if (!(Test-Path function:Pop-ImpersonationContext))
               {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Pop-ImpersonationContext'. Please make sure it's loaded."}
        }
    }

    Process
    {
        if ($forest)
            {$f = Get-Forest -domain $forest}
        else
            {$f = Get-Forest}

        #Load different user context if credential parameter is present
        if ($Credential)
            {$null = Push-ImpersonationContext $Credential}

        if ($pscmdlet.ShouldProcess($f.name))
            {$f.RaiseForestFunctionality($Funcionality)}

        #Restore current user context
        if ($Credential)
            {$null = Pop-ImpersonationContext}
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function Ended"}
}