#Requires -Version 2.0
Function ConvertFrom-ADSLargeInteger
{
    <#
    .Synopsis
        Convert Large Integer to Int64
        
    .Description
        Convert Large Integer to Int64
        
    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2016/03/03 17:54
    #>
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true
        )]
        $InputObject
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
    }

    Process
    {
        
        $highPart = $InputObject.GetType().InvokeMember("HighPart", [System.Reflection.BindingFlags]::GetProperty, $null, $InputObject, $null)
        $lowPart  = $InputObject.GetType().InvokeMember("LowPart",  [System.Reflection.BindingFlags]::GetProperty, $null, $InputObject, $null)



        $bytes = [System.BitConverter]::GetBytes($highPart)
        $tmp   = [System.Byte[]]@(0,0,0,0,0,0,0,0)
        [System.Array]::Copy($bytes, 0, $tmp, 4, 4)
        $highPart = [System.BitConverter]::ToInt64($tmp, 0)



        $bytes = [System.BitConverter]::GetBytes($lowPart)
        $lowPart = [System.BitConverter]::ToUInt32($bytes, 0)
 
        $lowPart + $highPart
    }

    End
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}