#Requires -Version 2.0
Function New-Computer
{
    <#
    .Synopsis
        Creates a new Computer account in Active Directory.

    .Description
        Creates a new Computer account in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 13:20

    .Inputs
        System.String
        System.DirectoryServices.DirectoryEntry

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Parameter Name
        Name for the new Computer

    .Parameter ParentContainer
        Container in which the Computer should be created in.

    .Parameter ManagedBy
        ADSI object of the account that manages the object.

    .Parameter PassThru
        Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.

    .Example
        New-Computer -Name TestPC -ParentContainer "CN=Computers,DC=domain,DC=com" | Enable-Account
        -----------
        Description
        Creates a Computer named TestPC in the Computers OU

    .Link
        Disable-Account
        Enable-Account
        Get-Object
        Get-OU
        Get-User
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium"
    )]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(mandatory=$true,HelpMessage="Name for the new Computer")]
        [string]$Name,

        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true,mandatory=$true,HelpMessage="Container in which the Computer should be created in")]
        [ADSI]$ParentContainer,

        [ADSI]$managedby,

        [string]$Description,

        [datetime]$accountExpires,

        [System.Management.Automation.PSCredential]$Credential,

        [switch]$PassThru
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        if (!(Test-Path function:Get-DomainRoot))
            {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-DomainRoot'. Please make sure it's loaded."}

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
        if (!([ADSI]::Exists($ParentContainer.Path)))
            {Write-Error "$($MyInvocation.MyCommand.Name):: ParentContainer '$($ParentContainer.distinguishedName)' doesn't exist";return}

        $filter = "(&(objectCategory=Person)(objectClass=Computer)(name=$Name))"
        $root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$(Get-DomainRoot -path $($ParentContainer.distinguishedName))")
        $searcher = New-Object System.DirectoryServices.DirectorySearcher $filter
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Checking if $Name already exists"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching in: $($searcher.SearchRoot)"

        $searcher.SizeLimit = 0
        $searcher.PageSize = 1000
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching for: $($searcher.filter)"
        $result = $searcher.FindOne()

        if ($result)
            {Write-Warning "$($MyInvocation.MyCommand.Name):: Computer with the same name already exists in your domain."}
        else
        {
            #Load different user context if credential parameter is present
            if ($Credential)
                {$null = Push-ImpersonationContext $Credential}

            if ($pscmdlet.ShouldProcess($Name))
            {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Creating Computer: $Name"
                $comp = $ParentContainer.Create("Computer","CN=$Name")

                if ($Description)
                    {$null = $comp.put("description",$Description)}

                if ($Managedby)
                {
                    if ($Managedby.psbase.SchemaClassName -match 'User|Contact' -and [ADSI]::Exists($Managedby.Path))
                        {$null = $comp.put("managedBy","$($managedby.distinguishedName)")}
                     else
                        {Write-Warning "$($MyInvocation.MyCommand.Name):: `$Manager is not a valid object type (only 'User' or 'Contact' objects are allowed) or could not be found."}
                }

                if ($accountExpires)
                    {$comp.psbase.InvokeSet("accountexpires","$($accountExpires.ToFileTimeUtc())")}

                Write-Verbose "$($MyInvocation.MyCommand.Name):: Saving Information for: $Name"
                $null = $comp.psbase.CommitChanges()
            }

            #Restore current user context
            if ($Credential)
                {$null = Pop-ImpersonationContext}

            if ($PassThru) {return $comp}
        }
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}