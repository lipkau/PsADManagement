#Requires -Version 2.0
Function New-OU
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
        Date      : 2011/08/13 13:20

    .Inputs
        System.String
        System.DirectoryServices.DirectoryEntry

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Parameter Name
        Name for the new OU

    .Parameter ParentContainer
        Container in which the OU should be created in.

    .Parameter ManagedBy
        ADSI object of the account that manages the object.

    .Parameter PassThru
        Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.

    .Parameter Country
        Country Code (ISO_3166-1_alpha-2)
        Available values can be found here: http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements

    .Example
        New-OU -Name TestOU -ParentContainer "DC=domain,DC=com"
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
        [Parameter(mandatory=$true,HelpMessage="Name for the new OU")]
        [string]$Name,

        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true,mandatory=$true,HelpMessage="Container in which the OU should be created in")]
        [ADSI]$ParentContainer,

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

        [switch]$PassThru,

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
    }

    Process
    {
        if (!([ADSI]::Exists($ParentContainer.Path)))
            {Write-Error "$($MyInvocation.MyCommand.Name):: ParentContainer '$($ParentContainer.distinguishedName)' doesn't exist";return}

        if ([ADSI]::Exists("LDAP://OU=$Name,$($ParentContainer.distinguishedName)"))
            {Write-Warning "$($MyInvocation.MyCommand.Name):: The OU $name already exists in $ParentContainer."}
        else
        {
            #Load different user context if credential parameter is present
            if ($Credential)
                {$null = Push-ImpersonationContext $Credential}

            if ($pscmdlet.ShouldProcess($Name))
            {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Creating OU: $Name"
                $OU = $ParentContainer.Create("OrganizationalUnit","OU=$Name")

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

                Write-Verbose "$($MyInvocation.MyCommand.Name):: Saving Information for: $Name"
                $null = $OU.SetInfo()
            }

            #Restore current user context
            if ($Credential)
                {$null = Pop-ImpersonationContext}

            if ($PassThru)
                {return $OU}
        }
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}