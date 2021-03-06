#Requires -Version 2.0
Function New-Group
{
    <#
    .Synopsis
        Creates a new group in Active Directory.

    .Description
        Creates a new group in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/16 18:38

    .Inputs
        System.String
        System.DirectoryServices.DirectoryEntry

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Parameter Name
        Name for the new group

    .Parameter ParentContainer
        Container in which the group should be created in.

    .Parameter GroupScope
        Group scopes can be:
            Universal:    Can include Accounts, Global groups and Universal groups from the forest.
            Global:       Can include Accounts and Global groups from the same domain.
            Domain Local: Can include Accounts, Global groups and Universal groups from any doamins and Domain Local groups from the same domain.
        Read more at: http://technet.microsoft.com/en-us/library/cc755692(WS.10).aspx

    .Parameter PassThru
        Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.

    .Parameter GroupType
        Group types can be:
            Distribution: Distribution groups can be used only with e-mail applications (such as Exchange) to send e-mail to collections of users.
            Security:     Security Groups can assign permissions to security groups on resources and user rights to security groups in Active Directory .
        Read more at: http://technet.microsoft.com/en-us/library/cc781446(WS.10).aspx

    .Parameter ManagedBy
        ADSI object of the account that manages the object.

    .Example
        New-Group -Name  TestGroup -GroupScope universal -GroupType security -ParentContainer  "OU=Test,DC=domain,DC=com"
        -----------
        Description
        Creates universal security group TestGroup in Test OU

    .Link
        Group Scopes:
            http://technet.microsoft.com/en-us/library/cc755692(WS.10).aspx

    .Link
        Group Types:
            http://technet.microsoft.com/en-us/library/cc781446(WS.10).aspx

    .Link
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
        [Parameter(mandatory=$true,HelpMessage="Name for the new group")]
        [string[]]$Name,

        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true,mandatory=$true,HelpMessage="Container in which the group should be created in.")]
        [ADSI]$ParentContainer,

        [ValidateNotNullOrEmpty()]
        [ValidateSet("Universal","Global","DomainLocal")]
        [string]$GroupScope = "Global",

        [ValidateNotNullOrEmpty()]
        [ValidateSet("Security","Distribution")]
        [string]$GroupType = "Security",

        [string]$Description,

        [string]$Email,

        [ADSI]$managedby,

        [string]$Notes,

        [System.Management.Automation.PSCredential]$Credential,

        [switch]$PassThru
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

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
        foreach ($n in $name)
        {
            if (!([ADSI]::Exists($ParentContainer.Path)))
                {Write-Error "$($MyInvocation.MyCommand.Name):: ParentContainer '$($ParentContainer.distinguishedName)' doesn't exist";return}

            switch ($GroupScope)
            {
                "Global"
                    {$GroupTypeAttr = 2}
                "DomainLocal"
                    {$GroupTypeAttr = 4}
                "Universal"
                    {$GroupTypeAttr = 8}
            }

            # modify group type attribute if the group is security enabled
            if ($GroupType -eq 'Security')
                {$GroupTypeAttr = $GroupTypeAttr -bor 0x80000000}

            if ([ADSI]::Exists("LDAP://CN=$n,$($ParentContainer.distinguishedName)"))
                {Write-Warning "$($MyInvocation.MyCommand.Name):: The group $n already exists in $($ParentContainer.distinguishedName)."}
            else
            {

                #Load different user context if credential parameter is present
                if ($Credential)
                    {$null = Push-ImpersonationContext $Credential}

                if ($pscmdlet.ShouldProcess($n))
                {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Creating Group: $n"
                    $group = $ParentContainer.Create("group","CN=$n")
                    $null = $group.put("sAMAccountname",$n)
                    $null = $group.put("grouptype",$GroupTypeAttr)

                    if ($Description)
                        {$null = $group.put("description",$Description)}

                    if ($email)
                        {$null = $group.put("mail",$email)}

                    if ($notes)
                        {$null = $group.put("info",$Notes)}

                    if ($managedby)
                    {
                        if ($managedby.psbase.SchemaClassName -match 'User|Contact' -and [ADSI]::Exists($managedby.Path))
                            {$null = $group.put("managedBy","$($managedby.distinguishedName)")}
                         else
                            {Write-Warning "$($MyInvocation.MyCommand.Name):: `$Managedby is not a valid object type (only 'User' or 'Contact' objects are allowed) or could not be found."}
                    }

                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Saving Information for: $n"
                    $null = $group.SetInfo()
                }

                #Restore current user context
                if ($Credential)
                    {$null = Pop-ImpersonationContext}

                if ($PassThru) {return $Group}
            }
        }
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}