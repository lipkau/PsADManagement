#Requires -Version 2.0
Function Set-OU
{
    <#
    .Synopsis
        Creates a new Organizational Unit in Active Directory.

    .Description
        Creates a new Organizational Unit in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 11:53

    .Inputs
        System.String
        System.DirectoryServices.DirectoryEntry

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Parameter OU
        OU to be changed.

    .Parameter ManagedBy
        ADSI object of the account that manages the object.

    .Parameter Country
        Country Code (ISO_3166-1_alpha-2)
        Available values can be found here: http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements

    .Example
        Get-Object "ou=OU,dc=domain,dc=com" | set-OU
        -----------
        Description
        Creates a OU named TestOU in the domain root

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
        [Parameter(mandatory=$true,HelpMessage="OU to be changed")]
        [ADSI]$OU,

        [ADSI]$managedby,

        [string]$Street,

        [string]$City,

        [Alias("Province")]
        [string]$State,

        [Alias("PostalCode")]
        [string]$zip,

        [ValidateSet("AD","AE","AF","AG","AI","AL","AM","AN","AO","AQ","AR","AS","AT","AU","AW","AX","AZ","BA","BB","BD","BE","BF","BG","BH","BI","BJ","BL","BM","BN","BO","BR","BS","BT","BV","BW","BY","BZ","CA","CC","CD","CF","CG","CH","CI","CK","CL","CM","CN","CO","CR","CU","CV","CX","CY","CZ","DE","DJ","DK","DM","DO","DZ","EC","EE","EG","EH","ER","ES","ET","FI","FJ","FK","FM","FO","FR","GA","GB","GD","GE","GF","GG","GH","GI","GL","GM","GN","GP","GQ","GR","GS","GT","GU","GW","GY","HK","HM","HN","HR","HT","HU","ID","IE","IL","IM","IN","IO","IQ","IR","IS","IT","JE","JM","JO","JP","KE","KG","KH","KI","KM","KN","KP","KR","KW","KY","KZ","LA","LB","LC","LI","LK","LR","LS","LT","LU","LV","LY","MA","MC","MD","ME","MF","MG","MH","MK","ML","MM","MN","MO","MP","MQ","MR","MS","MT","MU","MV","MW","MX","MY","MZ","NA","NC","NE","NF","NG","NI","NL","NO","NP","NR","NU","NZ","OM","PA","PE","PF","PG","PH","PK","PL","PM","PN","PR","PS","PT","PW","PY","QA","RE","RO","RS","RU","RW","SA","SB","SC","SD","SE","SG","SH","SI","SJ","SK","SL","SM","SN","SO","SR","ST","SV","SY","SZ","TC","TD","TF","TG","TH","TJ","TK","TL","TM","TN","TO","TR","TT","TV","TW","TZ","UA","UG","UM","US","UY","UZ","VA","VC","VE","VG","VI","VN","VU","WF","WS","YE","YT","ZA","ZM","ZW")]
        [string]$Country,

        [string]$Description,

        [switch]$EnableProtectFromDeletion,

        [switch]$DisableProtectFromDeletion,

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

        if ($DisableProtectFromDeletion -or $EnableProtectFromDeletion)
        {
            if (!(Test-Path function:Get-ADACL))
                {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-ADACL'. Please make sure it's loaded."}
            if (!(Test-Path function:Set-ADACL))
                {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Set-ADACL'. Please make sure it's loaded."}
        }
    }

    Process
    {
        #Load different user context if credential parameter is present
        if ($Credential)
            {$null = Push-ImpersonationContext $Credential}

        if ($pscmdlet.ShouldProcess($OU.cn))
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Altering OU: $($OU.cn)"

            if ($Description)
                {$null = $OU.put("description",$Description)}

            if ($Managedby)
            {
                if ($Managedby.psbase.SchemaClassName -match 'User|Contact' -and [ADSI]::Exists($Managedby.Path))
                     {$null = $OU.put("managedby","$($Managedby.distinguishedName)")}
                 else
                     {Write-Warning "$($MyInvocation.MyCommand.Name):: `$ManagerDN is not a valid object type (only 'User' or 'Contact' objects are allowed) or could not be found."}
            }

            if ($City)
                {$null = $OU.put("l",$City)}

            if ($Street)
                {$null = $OU.put("street",$Street)}

            if ($State)
                {$null = $OU.put("st",$State)}

            if ($zip)
                {$null = $OU.put("postalCode",$zip)}

            if ($Country)
                {$null = $OU.put("c",$Country)}

            if ($DisableProtectFromDeletion -and (!$EnableProtectFromDeletion))
            {
                $sddl = Get-ADACL $ou -sddl
                Set-ADACL $ou -sddl ($sddl -replace "(:[A-Za-z]*)\(","`$1(D;;DTSD;;;WD)(")
            }

            if ($EnableProtectFromDeletion -and (!$DisableProtectFromDeletion))
            {
                $sddl = Get-ADACL $ou -sddl
                Set-ADACL $ou -sddl ($sddl -replace "\(D;;DTSD;;;WD\)","")
            }

            Write-Verbose "$($MyInvocation.MyCommand.Name):: Saving Information for: $Name"
            $null = $OU.SetInfo()
        }

        #Restore current user context
        if ($Credential)
            {$null = Pop-ImpersonationContext}

        return $OU
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}