#Requires -Version 2.0
Function New-Password
{
    <#
    .Synopsis
        Generates a random password with the specified length.

    .Description
        Generates a random password with the specified length.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 15:13

    .Inputs
        System.Integer

    .Parameter Length
        Password length is the number of characters the password will have.

    .Parameter NumberOfNonAlphanumericCharacters
        Total of Non Alpanumeric Characters, such as: "!","?","@","$","&", etc.

    .Outputs
        System.String

    .Example
        New-Password -HowMany 3 -Length 8 -NumberOfNonAlphanumericCharacters 2
        -----------
        Description
        Generates 3 passwords, with 8 characters length each and 2 punctuation characters.

    .Link
        http://msdn.microsoft.com/en-us/library/system.web.security.membership.generatepassword.aspx
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [int]$Length = 12,

        [ValidateNotNullOrEmpty()]
        [int]$SpecialCharacters = 3
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        $null = [Reflection.Assembly]::LoadWithPartialName("System.Web")
    }

    Process
    {
        if ($Length -lt 6 -or $Length -gt 128)
            {Write-Error "Length must be between 6 and 128.";return}

        if ($SpecialCharacters -lt 1 -or $SpecialCharacters -gt 128)
            {Write-Error "Password must have between 1 and 128 special characters.";return}

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Generating Password"
        return [System.Web.Security.Membership]::GeneratePassword($length,$SpecialCharacters)
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}