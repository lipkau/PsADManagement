#Requires -Version 2.0
function Set-User
{
    <#
    .Synopsis
        Modifies attributes of a user object in Active Directory.

    .Discription
        Modifies attributes of a user object in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 11:51

    .Inputs
        System.DirectoryServices.DirectoryEntry, System.String

    .Parameter User
        User object to be changed.

    .Example
        Get-User User1 | Set-User -FirstName Heli -LastName Copter -Initials HC
        -----------
        Description
        Sets the FirstName, LastName and Initials of a user

    .Example
        Get-User User1 | Set-User -HomeDirectory '\\server\share\user1' -HomeDrive 'H:'
        -----------
        Description
        Sets the HomeDirectory and HomeDrive for User1

    .Example
        Get-User -SearchRoot 'OU=TEST,DC=Domain,DC=com' | Set-User -Description TestUsers -Office QA
        -----------
        Description
        Sets the Office attribute for all users in the Test OU

    .Example
        Get-User -SearchRoot 'OU=TEST,DC=Domain,DC=com' | Set-User -Description TestUsers -PasswordNeverExpires
        -----------
        Description
        Sets the Description attribute for all users in the Test OU and password to never expiry

    .Link
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
        [Parameter(ValueFromPipeline=$true,mandatory=$true,HelpMessage="User object to be changed.")]
        [Alias("CN")]
        [ADSI]$User,

        [string]$DistinguishedName,
        [string]$sAMAccountname,
        [string]$FirstName,
        [string]$LastName,
        [string]$Initials,
        [string]$Description,
        [string]$Email,
        [string]$UserPrincipalName,
        [string]$DisplayName,
        [string]$Office,
        [string]$Department,
        [ADSI]$ManagedBy,
        [string]$EmployeeID,
        [string]$EmployeeNumber,
        [string]$HomeDirectory,
        [string]$HomeDrive,
        [string]$Mobile,
        [string]$Password,
        [switch]$UserMustChangePassword,
        [switch]$PasswordNeverExpires,
        [switch]$UserCanChangePassword,
        [switch]$UserCannotChangePassword,

        [System.Management.Automation.PSCredential]$Credential
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

        function Convert-SLargeInteger([object]$LargeInteger)
        {
            $type = $LargeInteger.GetType()
            $highPart = $type.InvokeMember("HighPart","GetProperty",$null,$LargeInteger,$null)
            $lowPart = $type.InvokeMember("LowPart","GetProperty",$null,$LargeInteger,$null)

            $bytes = [System.BitConverter]::GetBytes($highPart)
            $tmp = New-Object System.Byte[] 8
            [Array]::Copy($bytes,0,$tmp,4,4)
            $highPart = [System.BitConverter]::ToInt64($tmp,0)
            $bytes = [System.BitConverter]::GetBytes($lowPart)
            $lowPart = [System.BitConverter]::ToUInt32($bytes,0)

            $lowPart + $highPart
        }
    }

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing Object: $($User.cn)"
        if ($User.psbase.SchemaClassName -eq 'User' -and [ADSI]::Exists($User.Path))
        {
            #Load different user context if credential parameter is present
            if ($Credential)
                {$null = Push-ImpersonationContext $Credential}

            if ($sAMAccountname)
                {$null = $User.put("sAMAccountname",$sAMAccountname)}

            if ($FirstName)
                {$null = $User.put("givenName",$FirstName)}

            if ($LastName)
                {$null = $User.put("sn",$LastName)}

            if ($Initials)
                {$null = $User.put("initials",$Initials)}

            if ($Description)
                {$null = $User.put("Description",$Description)}

            if ($Email)
                {$null = $User.put("mail",$Email)}

            if ($UserPrincipalName)
                {$null = $User.put("userPrincipalName",$UserPrincipalName)}

            if ($UserPrincipalName)
                {$null = $User.put("userPrincipalName",$UserPrincipalName)}

            if ($DisplayName)
                {$null = $User.put("displayName",$DisplayName)}

            if ($Office)
                {$null = $User.put("physicalDeliveryOfficeName",$Office)}

            if ($Department)
                {$null = $User.put("department",$Department)}

            if ($ManagedBy)
            {
                if ($ManagedBy.psbase.SchemaClassName -match 'User|Contact' -and [ADSI]::Exists($ManagedBy.Path))
                        {$null = $User.put("managedby",$ManagedBy.distinguishedName)}
                 else
                    {Write-Warning "$($MyInvocation.MyCommand.Name):: `$ManagedBy is not a valid object type (only 'User' or 'Contact' objects are allowed) or could not be found."}
            }

            if ($EmployeeID)
                {$null = $User.psbase.Invoke("employeeID",$EmployeeID)}

            if ($EmployeeNumber)
                {$null = $User.psbase.Invoke("employeeNumber",$EmployeeNumber)}

            if ($HomeDirectory)
                {$null = $User.psbase.Invoke("homeDirectory",$HomeDirectory)}

            if ($HomeDrive)
                {$null = $User.psbase.Invoke("homeDrive",$HomeDrive)}

            if ($Mobile)
                {$null = $User.psbase.InvokeSet("mobile",$Mobile)}

            if ($Password)
            {
                trap
                {
                    $pwdPol = "The password does not meet the password policy requirements"
                    $InnerException=$_.Exception.InnerException

                    if ($InnerException -match $pwdPol)
                    {
                        $script:PasswordChangeError=$true
                        Write-Warning $InnerException
                    }
                    else
                        {Write-Error $_}
                    continue
                }
                $null = $User.psbase.Invoke("setpassword",$Password)
            }

            if ($UserMustChangePassword)
            {
                if ($User.userAccountControl[0] -band 65536)
                {
                    $err = '$($MyInvocation.MyCommand.Name)'
                    $err += 'The password is already set to never expire.'
                    $err += ' The user will not be required to change the password at next logon.'
                    Write-Warning $err
                }
                elseif ($PasswordNeverExpires)
                {
                    $err = '$($MyInvocation.MyCommand.Name)'
                    $err += ' You specified that the password should never expire.'
                    $err += ' The user will not be required to change the password at next logon.'
                    Write-Warning $err
                } else
                    {$null = $User.pwdLastset=0}
            }

            if ($PasswordNeverExpires)
            {
                $pwdLastSet = Convert-SLargeInteger $User.pwdLastSet[0]

                if ($pwdLastSet -eq 0)
                {
                    $err = '$($MyInvocation.MyCommand.Name)'
                    $err += ' You specified that the password should never expire.'
                    $err += "The attribute 'User must change password at next logon' will be unchecked."
                    Write-Warning $err
                }

                $User.userAccountControl[0] = $User.userAccountControl[0] -bor 65536
            }

            if (($UserCanChangePassword) -and (!$userCannotChangePassword))
            {
                $acl = $user.psbase.ObjectSecurity
                $deny = $acl.GetAccessRules($true,$false,[System.Security.Principal.NTAccount]) | `
                Where-Object `
                {
                    ($_.IdentityReference -eq 'Everyone' -or $_.IdentityReference -eq 'NT AUTHORITY\SELF') `
                    -and $_.AccessControlType -eq 'Deny' -and $_.ActiveDirectoryRights -eq 'ExtendedRight'
                }

                if($deny)
                {
                    $deny | `
                    Foreach-Object `
                        {$null = $acl.psbase.RemoveAccessRule($_)}
                    $user.psbase.CommitChanges()
                }
            } elseif ((!$UserCanChangePassword) -and ($userCannotChangePassword)) {
                $CHANGE_PASSWORD_GUID = "AB721A53-1E2F-11D0-9819-00AA0040529B"
                'S-1-1-0','S-1-5-10' | `
                Foreach-Object `
                {
                    $si = [System.Security.Principal.SecurityIdentifier]$_
                    $Deny = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($si,"ExtendedRight","Deny",$CHANGE_PASSWORD_GUID)
                    $user.psbase.ObjectSecurity.AddAccessRule($Deny)
                }
                $user.psbase.CommitChanges()
            }

            if ($pscmdlet.ShouldProcess($User.cn))
                {$null = $User.SetInfo()}

            #Restore current user context
            if ($Credential)
                {$null = Pop-ImpersonationContext}

            return $user
        } else
            {Write-Warning "`$User is not a valid object type (only 'User' objects are allowed) or could not be found."}
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function Ended"}
}