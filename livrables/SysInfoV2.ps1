# SysinfoLogger.ps1
# Script PowerShell pour collecter des informations système locales et distantes

param (
    [string]$RemoteIP = "192.168.20.9"  # Adresse IP de la machine distante
)

# Fonction pour collecter les informations système locales
function Get-LocalSystemInfo {
    $hostname = $env:COMPUTERNAME
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor
    $gpu = Get-CimInstance -ClassName Win32_VideoController
    $ram = Get-CimInstance -ClassName Win32_PhysicalMemory
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $installedPrograms = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName

    $systemInfo = @{
        Hostname = $hostname
        OS = $os.Caption
        OSVersion = $os.Version
        CPU = $cpu.Name
        GPU = $gpu.Name
        TotalRAM = ($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB
        FreeDiskSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
        TotalDiskSpace = [math]::Round($disk.Size / 1GB, 2)
        InstalledPrograms = $installedPrograms.DisplayName -join ", "
    }

    return $systemInfo
}

# Fonction pour collecter les informations système distantes
function Get-RemoteSystemInfo {
    param (
        [string]$RemoteIP
    )

    $session = New-CimSession -ComputerName $RemoteIP
    $os = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -CimSession $session -ClassName Win32_Processor
    $gpu = Get-CimInstance -CimSession $session -ClassName Win32_VideoController
    $ram = Get-CimInstance -CimSession $session -ClassName Win32_PhysicalMemory
    $disk = Get-CimInstance -CimSession $session -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $installedPrograms = Invoke-Command -ComputerName $RemoteIP -ScriptBlock {
        Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName
    }

    $systemInfo = @{
        Hostname = $os.CSName
        OS = $os.Caption
        OSVersion = $os.Version
        CPU = $cpu.Name
        GPU = $gpu.Name
        TotalRAM = ($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB
        FreeDiskSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
        TotalDiskSpace = [math]::Round($disk.Size / 1GB, 2)
        InstalledPrograms = $installedPrograms.DisplayName -join ", "
    }

    return $systemInfo
}

# Fonction pour enregistrer les informations dans un fichier log
function Write-Log {
    param (
        [string]$LogFile,
        [hashtable]$SystemInfo,
        [string]$Source  # "Local" ou "Remote"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║ SYSINFO LOGGER - $Source ║
╟═══════════════════════════════════════════════════════════════════════════════╣
║ Log date: $timestamp ║
╙━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╜
┌ OPERATING SYSTEM
| Hostname: $($SystemInfo.Hostname)
| OS: $($SystemInfo.OS)
└ Version: $($SystemInfo.OSVersion)
┌ HARDWARE
| CPU: $($SystemInfo.CPU)
| GPU: $($SystemInfo.GPU)
└ RAM: $([math]::Round($SystemInfo.TotalRAM, 2)) GB
┌ DISK
| Free Space: $($SystemInfo.FreeDiskSpace) GB
| Total Space: $($SystemInfo.TotalDiskSpace) GB
└ Installed Programs: $($SystemInfo.InstalledPrograms)
"@

    Add-Content -Path $LogFile -Value $logEntry
}

# Fonction principale
function Main {
    $logFile = "sysloginfo.log"

    # Collecte des informations locales
    Write-Host "Collecting local system information..."
    $localSystemInfo = Get-LocalSystemInfo
    Write-Log -LogFile $logFile -SystemInfo $localSystemInfo -Source "Local"

    # Collecte des informations distantes (si une adresse IP est fournie)
    if ($RemoteIP) {
        Write-Host "Collecting system information from remote machine: $RemoteIP"
        $remoteSystemInfo = Get-RemoteSystemInfo -RemoteIP $RemoteIP
        Write-Log -LogFile $logFile -SystemInfo $remoteSystemInfo -Source "Remote"
    }

    Write-Host "System information has been logged to $logFile"
}

# Exécution du script
Main