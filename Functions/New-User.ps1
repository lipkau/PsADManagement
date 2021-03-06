#Requires -Version 2.0
Function New-User
{
    <#
    .Synopsis
        Creates a new user object in Active Directory.

    .Description
        Creates a new user object in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 13:05

    .Inputs
        System.DirectoryServices.DirectoryEntry, System.String

    .Parameter Name
        Display name of the new user

    .Parameter sAMAccountName
        SAM Account name (aka pre windows 2000 name)

    .Parameter ParentContainer
        OU in which object should be created

    .Parameter ParentContainer
        Container in which the user should be created in.

    .Parameter PassThru
        Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.

    .Example
        New-User -Name 'Idera User' -sAMAccountname 'IUser' -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd' -EnableAccount
        -----------
        Description
        Creates new user in the Test OU and enables the account

    .Example
        New-User -Name 'Idera User' -sAMAccountname 'IUser' -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd' -EnableAccount -UserMustChangePassword
        -----------
        Description
        Creates new user in the Test OU and enables the account. The user will have to change password at next logon

    .Example
        New-User -Name 'Idera User' -sAMAccountname 'IUser' -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd' -EnableAccount -PasswordNeverExpires
        -----------
        Description
        Creates new user in the Test OU and enables the account. The users password will not expire.

    .Example
        Get-Content users.txt | foreach { New-User -Name $_ -sAMAccountName ($_ -replace " ") -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd'}
        -----------
        Description
        Creates disabled users from text file in the Test OU (spaces are not allowed in sAMAccountName)

    .Link
        Get-Content
        Get-Object
        Get-OU
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/

    .Notes
        Todo:
            Set more attributes
    #>

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium"
    )]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(mandatory=$true,HelpMessage="Display name of the new user")]
        [string]$Name,

        [ValidateNotNullOrEmpty()]
        [Parameter(mandatory=$true,HelpMessage="SAM Account name (aka pre windows 2000 name)")]
        [string]$sAMAccountName,

        [ValidateNotNullOrEmpty()]
        [Parameter(mandatory=$true,HelpMessage="OU in which object should be created")]
        [ADSI]$ParentContainer,

        [ValidateNotNullOrEmpty()]
        [Parameter(mandatory=$true,HelpMessage="Object's password")]
        [string]$Password,

        [ValidatePattern('^\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b$')]
        [string]$email,

        [string]$UPN,

        [switch]$UserMustChangePassword,

        [switch]$PasswordNeverExpires,

        [switch]$EnableAccount,

        [switch]$PassThru,

        [System.Management.Automation.PSCredential]$Credential
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
        if ($sAMAccountName -match '\s')
            {Write-Error "$($MyInvocation.MyCommand.Name):: sAMAccountName cannot contain spaces";return}

        if (!([ADSI]::Exists($ParentContainer.Path)))
            {Write-Error "$($MyInvocation.MyCommand.Name):: ParentContainer '$($ParentContainer.distinguishedName)' doesn't exist";return}

        $filter = "(&(objectCategory=Person)(objectClass=User)(samaccountname=$sAMAccountname))"
        $root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$(Get-DomainRoot -path $($ParentContainer.distinguishedName))")
        $searcher = New-Object System.DirectoryServices.DirectorySearcher $filter
        Wite-Verbose "$($MyInvocation.MyCommand.Name):: Checking if $Name already exists"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching in: $($searcher.SearchRoot)"

        $searcher.SizeLimit = 0
        $searcher.PageSize = 1000
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching for: $($searcher.filter)"
        $result = $searcher.FindOne()

        if ($result)
            {Write-Error "$($MyInvocation.MyCommand.Name):: User with the same sAMAccountname already exists in your domain.";return}

        if ($UserMustChangePassword -and $PasswordNeverExpires)
        {
            $err = '$($MyInvocation.MyCommand.Name)'
            $err += ' You specified that the password should never expire.'
            $err += ' The user will not be required to change the password at next logon.'
            Write-Warning $err
        }

        #Load different user context if credential parameter is present
        if ($Credential)
            {$null = Push-ImpersonationContext $Credential}

        if ($pscmdlet.ShouldProcess($Name))
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Creating User"
            $user = $ParentContainer.Create("user","cn=$Name")
            if ($name -match ",") {
                $n = $Name.Split(",")
                $n = $n.Trim()
                $n = $n.Split()
                $FirstName = $n[1]
                $LastName = $n[0]
                $null = $user.put("sn",$LastName)
            }elseif ($Name -match '\s'){
                $n = $Name.Split()
                $FirstName = $n[0]
                $LastName = "$($n[1..$n.length])"
                $null = $user.put("sn",$LastName)
            } else
                {$FirstName = $Name}

            $null = $user.put("givenName",$FirstName)
            $null = $user.put("displayName",$Name)
            if ($email)
                {$null = $user.put("mail",$email)}
            $suffix = $root.defaultNamingContext -replace "dc=" -replace ",","."
            if (!($UPN))
                {$upnStr = "$samaccountname@$suffix"}
            else
            {
                if ($UPN -like 'email')
                {
                    if (!($email))
                    {
                        $upnStr = "$samaccountname@$suffix"
                        Write-Warning "$($MyInvocation.MyCommand.Name):: UPN could not be set to the E-Mail, since no E-Mail was specified."
                        Write-Warning "$($MyInvocation.MyCommand.Name):: UPN will be set to default: $samaccountname@$suffix"
                    } else
                        {$upnStr = $email}
                } else
                    {$upnStr = "$UPN"}
            }
            $null = $user.put("userPrincipalName",$upnStr)
            $null = $user.put("sAMAccountName",$sAMAccountName)

            Write-verbose "$($MyInvocation.MyCommand.Name):: Saving Information"
            $null = $user.SetInfo()

            trap
            {
                $pwdPol = "The password does not meet the password policy requirements"
                $InnerException=$_.Exception.InnerException
                if ($InnerException -match $pwdPol)
                {
                    $script:PasswordChangeError=$true
                    Write-Error "$($MyInvocation.MyCommand.Name):: $InnerException";return
                } # else
#                    {Write-Error "$($MyInvocation.MyCommand.Name):: $_";return}
                continue
            }

            Write-Verbose "$($MyInvocation.MyCommand.Name):: Setting Password"
            $null = $user.psbase.Invoke("SetPassword",$Password)

            if ($UserMustChangePassword)
                {$null = $user.pwdLastset=0}
            if ($PasswordNeverExpires)
                {$null = $user.userAccountControl[0] = $user.userAccountControl[0] -bor 65536}

            if ($EnableAccount)
            {
                if ($script:PasswordChangeError)
                    {Write-Warning "Accound cannot be enabled since setting the password did not succeed."}
                else
                    {$null = $user.psbase.InvokeSet("AccountDisabled",$false)}
            } else
                {$null = $user.psbase.InvokeSet("AccountDisabled",$true)}

            Write-Verbose "$($MyInvocation.MyCommand.Name):: Saving Information"
            $null = $user.SetInfo()
        }

        #Restore current user context
        if ($Credential)
            {$null = Pop-ImpersonationContext}
        if ($PassThru)
            {return $user}
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}