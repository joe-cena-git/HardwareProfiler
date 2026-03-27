#Requires -Version 5.1
<#
.SYNOPSIS
    Produces a detailed, human-readable hardware profile of any Windows machine.

.DESCRIPTION
    Queries WMI/CIM, nvidia-smi, and system APIs to produce a comprehensive
    snapshot of the machine's hardware - CPU, RAM, GPU(s), storage, network,
    motherboard, power, and cooling. Output is always saved to a timestamped
    text file. All errors are captured into the same file rather than printed
    to the console, making the script safe for SSH and unattended execution.

.PARAMETER OutputFile
    Optional. Full path for the output file. Defaults to a timestamped file
    in the same directory as the script.

.EXAMPLE
    .\Get-HardwareProfile.ps1
    .\Get-HardwareProfile.ps1 -OutputFile "C:\reports\my-build.txt"

    # Via SSH (no interactive prompt, output goes straight to file):
    ssh user@machine "powershell -ExecutionPolicy Bypass -File C:\Get-HardwareProfile.ps1"

.NOTES
    Run as Administrator for full details (BIOS, some thermal sensors).
    nvidia-smi must be on PATH for detailed GPU info (standard with NVIDIA drivers).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputFile
)

Set-StrictMode -Version Latest

# Capture errors into the report buffer rather than printing to console.
# This ensures clean output when run via SSH or unattended execution.
$ErrorActionPreference = "SilentlyContinue"

# Trap terminating errors - write them into the report buffer so they land in the file
trap {
    $script:ReportLines.Add("") | Out-Null
    $script:ReportLines.Add("ERROR: $_") | Out-Null
    continue
}

# -----------------------------------------------------------------------------
# Output buffer - all report lines accumulate here then flush to file at end
# -----------------------------------------------------------------------------
$script:ReportLines = [System.Collections.Generic.List[string]]::new()

function Write-Report {
    param([string]$Line = "")
    # Write to console AND buffer - file is saved at end
    $script:ReportLines.Add($Line) | Out-Null
    Write-Host $Line
}

function Write-Header {
    param([string]$Title)
    $separator = "=" * 72
    Write-Report ""
    Write-Report $separator
    Write-Report "  $Title"
    Write-Report $separator
}

function Write-SubHeader {
    param([string]$Title)
    $separator = "-" * 56
    Write-Report ""
    Write-Report "  $Title"
    Write-Report "  $separator"
}

function Write-Field {
    param(
        [string]$Label,
        [string]$Value,
        [int]$Indent = 4
    )
    $paddedLabel = $Label.PadRight(32)
    Write-Report (" " * $Indent + "${paddedLabel}: $Value")
}

function Format-Bytes {
    param([long]$Bytes)
    if ($Bytes -ge 1TB) { return "{0:N2} TB" -f ($Bytes / 1TB) }
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Format-MHz {
    param([long]$MHz)
    if ($MHz -ge 1000) { return "{0:N2} GHz ({1} MHz)" -f ($MHz / 1000), $MHz }
    return "$MHz MHz"
}

function Get-MemoryTypeString {
    param([int]$TypeCode)
    $return = switch ($TypeCode) {
        0  { "Unknown" }
        1  { "Other" }
        2  { "DRAM" }
        3  { "Synchronous DRAM" }
        4  { "Cache DRAM" }
        5  { "EDO" }
        6  { "EDRAM" }
        7  { "VRAM" }
        8  { "SRAM" }
        9  { "RAM" }
        10 { "ROM" }
        11 { "Flash" }
        12 { "EEPROM" }
        13 { "FEPROM" }
        14 { "EPROM" }
        15 { "CDRAM" }
        16 { "3DRAM" }
        17 { "SDRAM" }
        18 { "SGRAM" }
        19 { "RDRAM" }
        20 { "DDR" }
        21 { "DDR2" }
        22 { "DDR2 FB-DIMM" }
        24 { "DDR3" }
        26 { "DDR4" }
        27 { "LPDDR" }
        28 { "LPDDR2" }
        29 { "LPDDR3" }
        30 { "LPDDR4" }
        34 { "DDR5" }
        35 { "LPDDR5" }
        default { "Type Code $TypeCode" }
    }
    return $return
}

function Get-DriveTypeString {
    param([string]$MediaType)
    $return = switch -Wildcard ($MediaType) {
        "*SSD*"         { "SSD" }
        "*NVMe*"        { "NVMe SSD" }
        "*HDD*"         { "HDD" }
        "*Unspecified*" { "Unknown" }
        $null           { "Unknown" }
        default         { $MediaType }
    }
    return $return
}

# -----------------------------------------------------------------------------
# REPORT HEADER
# -----------------------------------------------------------------------------
$reportTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$machineName     = $env:COMPUTERNAME
$currentUser     = $env:USERNAME

Write-Report ("=" * 72)
Write-Report "  HARDWARE PROFILE REPORT"
Write-Report "  Generated : $reportTimestamp"
Write-Report "  Machine   : $machineName"
Write-Report "  User      : $currentUser"
Write-Report ("=" * 72)

# -----------------------------------------------------------------------------
# OPERATING SYSTEM
# -----------------------------------------------------------------------------
Write-Header "OPERATING SYSTEM"

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem

Write-Field "OS Name"          $os.Caption
Write-Field "Version"          $os.Version
Write-Field "Build"            $os.BuildNumber
Write-Field "Architecture"     $os.OSArchitecture
Write-Field "Install Date"     ($os.InstallDate.ToString("yyyy-MM-dd"))
Write-Field "Last Boot"        ($os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss"))
Write-Field "Uptime"           ("{0}d {1}h {2}m" -f `
    (New-TimeSpan -Start $os.LastBootUpTime).Days,
    (New-TimeSpan -Start $os.LastBootUpTime).Hours,
    (New-TimeSpan -Start $os.LastBootUpTime).Minutes)
Write-Field "System Type"      $cs.SystemType
Write-Field "Domain/Workgroup" $(if ($cs.PartOfDomain) { $cs.Domain } else { "$($cs.Workgroup) (Workgroup)" })

# -----------------------------------------------------------------------------
# MOTHERBOARD & BIOS
# -----------------------------------------------------------------------------
Write-Header "MOTHERBOARD & BIOS"

$board = Get-CimInstance Win32_BaseBoard
$bios  = Get-CimInstance Win32_BIOS
$sys   = Get-CimInstance Win32_ComputerSystem

Write-SubHeader "Motherboard"
Write-Field "Manufacturer"     $board.Manufacturer
Write-Field "Product"          $board.Product
Write-Field "Version"          $board.Version
Write-Field "Serial Number"    $board.SerialNumber

Write-SubHeader "BIOS"
Write-Field "Manufacturer"     $bios.Manufacturer
Write-Field "Name"             $bios.Name
Write-Field "Version"          $bios.SMBIOSBIOSVersion
Write-Field "Release Date"     ($bios.ReleaseDate.ToString("yyyy-MM-dd"))
Write-Field "Serial Number"    $bios.SerialNumber

Write-SubHeader "Chassis"
$chassis = Get-CimInstance Win32_SystemEnclosure
Write-Field "Manufacturer"     $chassis.Manufacturer
Write-Field "Model"            $chassis.Model
Write-Field "Serial Number"    $chassis.SerialNumber

# -----------------------------------------------------------------------------
# CPU
# -----------------------------------------------------------------------------
Write-Header "PROCESSOR (CPU)"

# Force array wrapper so .Count works correctly on single-CPU machines
[array]$cpus = Get-CimInstance Win32_Processor

foreach ($cpu in $cpus) {
    if ($cpus.Count -gt 1) { Write-SubHeader "CPU: $($cpu.DeviceID)" }

    Write-Field "Name"              $cpu.Name.Trim()
    Write-Field "Manufacturer"      $cpu.Manufacturer
    Write-Field "Socket"            $cpu.SocketDesignation
    Write-Field "Architecture"      $(switch ($cpu.Architecture) {
                                        0 { "x86" }; 5 { "ARM" }; 9 { "x64" }; default { $cpu.Architecture }
                                    })
    Write-Field "Physical Cores"    $cpu.NumberOfCores
    Write-Field "Logical Processors" $cpu.NumberOfLogicalProcessors
    Write-Field "Threads per Core"  ($cpu.NumberOfLogicalProcessors / $cpu.NumberOfCores)
    Write-Field "Base Clock"        (Format-MHz $cpu.MaxClockSpeed)
    Write-Field "L2 Cache"          (Format-Bytes ($cpu.L2CacheSize * 1KB))
    Write-Field "L3 Cache"          (Format-Bytes ($cpu.L3CacheSize * 1KB))
    Write-Field "Status"            $cpu.Status
    Write-Field "Load (current)"    "$($cpu.LoadPercentage)%"
    Write-Field "Virtualization"    $(if ($cpu.VirtualizationFirmwareEnabled) { "Enabled" } else { "Disabled/Unknown" })
}

# -----------------------------------------------------------------------------
# RAM
# -----------------------------------------------------------------------------
Write-Header "MEMORY (RAM)"

$ramSticks  = Get-CimInstance Win32_PhysicalMemory
$totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRamGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRamGB  = [math]::Round($totalRamGB - $freeRamGB, 2)

Write-Field "Total Installed"   "$totalRamGB GB"
Write-Field "Currently Used"    "$usedRamGB GB"
Write-Field "Currently Free"    "$freeRamGB GB"
Write-Field "Stick Count"       $ramSticks.Count

$stickIndex = 0
foreach ($stick in $ramSticks) {
    $stickIndex++
    $capacityGB  = [math]::Round($stick.Capacity / 1GB, 2)
    $memTypeStr  = Get-MemoryTypeString -TypeCode $stick.MemoryType
    $smTypeStr   = Get-MemoryTypeString -TypeCode $stick.SMBIOSMemoryType

    # SMBIOSMemoryType is more reliable than MemoryType
    $resolvedType = if ($smTypeStr -ne "Unknown" -and $smTypeStr -ne "Other") { $smTypeStr } else { $memTypeStr }

    Write-SubHeader "Stick $stickIndex - $($stick.BankLabel) / $($stick.DeviceLocator)"
    Write-Field "Capacity"          "$capacityGB GB"
    Write-Field "Type"              $resolvedType
    Write-Field "Speed"             "$($stick.Speed) MHz"
    Write-Field "Configured Speed"  "$($stick.ConfiguredClockSpeed) MHz"
    Write-Field "Manufacturer"      $stick.Manufacturer
    Write-Field "Part Number"       $stick.PartNumber.Trim()
    Write-Field "Serial Number"     $stick.SerialNumber
    Write-Field "Form Factor"       $(switch ($stick.FormFactor) {
                                        8 { "DIMM" }; 12 { "SO-DIMM" }; 13 { "TSOP" }; default { $stick.FormFactor }
                                    })
    Write-Field "Data Width"        "$($stick.DataWidth)-bit"
}

# -----------------------------------------------------------------------------
# GPU(s)
# -----------------------------------------------------------------------------
Write-Header "GRAPHICS (GPU)"

$gpus = Get-CimInstance Win32_VideoController

foreach ($gpu in $gpus) {
    Write-SubHeader $gpu.Name

    $vramBytes = [long]$gpu.AdapterRAM
    $vramStr   = if ($vramBytes -gt 0) { Format-Bytes $vramBytes } else { "Unknown (query nvidia-smi)" }

    Write-Field "Name"              $gpu.Name
    Write-Field "Driver Version"    $gpu.DriverVersion
    Write-Field "Driver Date"       ($gpu.DriverDate.ToString("yyyy-MM-dd"))
    Write-Field "VRAM (WMI)"        $vramStr
    Write-Field "Video Mode"        $gpu.VideoModeDescription
    Write-Field "Current Refresh"   "$($gpu.CurrentRefreshRate) Hz"
    Write-Field "Max Refresh"       "$($gpu.MaxRefreshRate) Hz"
    Write-Field "Bits per Pixel"    $gpu.CurrentBitsPerPixel
    Write-Field "Status"            $gpu.Status
}

# nvidia-smi detailed output - much more accurate than WMI for NVIDIA cards
$nvidiaSmi = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
if ($nvidiaSmi) {
    Write-SubHeader "NVIDIA Detailed - nvidia-smi"

    # Full nvidia-smi table
    $nvOutput = nvidia-smi 2>&1
    foreach ($line in $nvOutput) {
        Write-Report "    $line"
    }

    # Structured query for key metrics
    Write-SubHeader "NVIDIA Per-GPU Metrics"
    $nvQuery = nvidia-smi --query-gpu=`
index,name,driver_version,cuda_version,`
memory.total,memory.used,memory.free,`
temperature.gpu,fan.speed,`
power.draw,power.limit,`
clocks.current.graphics,clocks.current.memory,`
utilization.gpu,utilization.memory,`
pcie.link.gen.current,pcie.link.width.current `
        --format=csv,noheader,nounits 2>&1

    if ($LASTEXITCODE -eq 0 -and $nvQuery) {
        foreach ($gpuLine in $nvQuery) {
            $fields = $gpuLine -split ", "
            if ($fields.Count -ge 17) {
                Write-Report ""
                Write-Field "GPU Index"          $fields[0]
                Write-Field "Name"               $fields[1]
                Write-Field "Driver Version"     $fields[2]
                Write-Field "CUDA Version"       $fields[3]
                Write-Field "VRAM Total"         "$($fields[4]) MB"
                Write-Field "VRAM Used"          "$($fields[5]) MB"
                Write-Field "VRAM Free"          "$($fields[6]) MB"
                Write-Field "Temperature"        "$($fields[7])  C"
                Write-Field "Fan Speed"          "$($fields[8]) %"
                Write-Field "Power Draw"         "$($fields[9]) W"
                Write-Field "Power Limit"        "$($fields[10]) W"
                Write-Field "GPU Clock"          "$($fields[11]) MHz"
                Write-Field "Memory Clock"       "$($fields[12]) MHz"
                Write-Field "GPU Utilization"    "$($fields[13]) %"
                Write-Field "Memory Utilization" "$($fields[14]) %"
                Write-Field "PCIe Gen"           $fields[15]
                Write-Field "PCIe Width"         "x$($fields[16])"
            }
        }
    }
}

# -----------------------------------------------------------------------------
# STORAGE
# -----------------------------------------------------------------------------
Write-Header "STORAGE"

# Physical disks
$physicalDisks = Get-PhysicalDisk | Sort-Object DeviceId
Write-SubHeader "Physical Disks"

foreach ($disk in $physicalDisks) {
    $sizeStr     = Format-Bytes $disk.Size
    $mediaType   = Get-DriveTypeString -MediaType $disk.MediaType

    Write-Report ""
    Write-Field "Disk $($disk.DeviceId)"  $disk.FriendlyName
    Write-Field "  Media Type"            $mediaType
    Write-Field "  Size"                  $sizeStr
    Write-Field "  Bus Type"              $disk.BusType
    Write-Field "  Spindle Speed"         $(if ($disk.SpindleSpeed -gt 0) { "$($disk.SpindleSpeed) RPM" } else { "N/A (SSD/NVMe)" })
    Write-Field "  Health Status"         $disk.HealthStatus
    Write-Field "  Operational Status"    $disk.OperationalStatus
    Write-Field "  Firmware Version"      $disk.FirmwareVersion
    Write-Field "  Serial Number"         $disk.SerialNumber
}

# Logical drives / partitions
Write-SubHeader "Logical Drives"

$logicalDisks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
foreach ($drive in $logicalDisks) {
    $totalGB = [math]::Round($drive.Size / 1GB, 2)
    $freeGB  = [math]::Round($drive.FreeSpace / 1GB, 2)
    $usedGB  = [math]::Round($totalGB - $freeGB, 2)
    $usedPct = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 1) } else { 0 }

    Write-Report ""
    Write-Field "Drive $($drive.DeviceID)"  $drive.VolumeName
    Write-Field "  File System"             $drive.FileSystem
    Write-Field "  Total Size"              "$totalGB GB"
    Write-Field "  Used"                    "$usedGB GB ($usedPct%)"
    Write-Field "  Free"                    "$freeGB GB"
}

# -----------------------------------------------------------------------------
# NETWORK ADAPTERS
# -----------------------------------------------------------------------------
Write-Header "NETWORK ADAPTERS"

$adapters = Get-NetAdapter | Where-Object { $_.Status -ne "Not Present" } | Sort-Object InterfaceIndex

foreach ($adapter in $adapters) {
    $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue |
                Where-Object { $_.AddressFamily -eq "IPv4" }

    # LinkSpeed can be a string like "0 bps" on disconnected adapters - guard against that
    $linkSpeedStr = try {
        $speedBits = [long]$adapter.LinkSpeed
        if ($speedBits -gt 0) { "$([math]::Round($speedBits / 1MB, 0)) Mbps" } else { "Disconnected / Unknown" }
    } catch {
        $adapter.LinkSpeed.ToString()
    }

    Write-Report ""
    Write-Field "Adapter"            $adapter.Name
    Write-Field "  Description"      $adapter.InterfaceDescription
    Write-Field "  Status"           $adapter.Status
    Write-Field "  MAC Address"      $adapter.MacAddress
    Write-Field "  Link Speed"       $linkSpeedStr
    Write-Field "  Connector Type"   $adapter.ConnectorPresent
    Write-Field "  IPv4 Address"     $(if ($ipConfig) { $ipConfig.IPAddress } else { "Not assigned" })
    Write-Field "  DHCP Enabled"     $(($adapter | Get-NetIPInterface -ErrorAction SilentlyContinue).Dhcp)
    Write-Field "  Interface Type"   $adapter.InterfaceType
}

# -----------------------------------------------------------------------------
# AUDIO
# -----------------------------------------------------------------------------
Write-Header "AUDIO DEVICES"

$audioDevices = Get-CimInstance Win32_SoundDevice

foreach ($audio in $audioDevices) {
    Write-Report ""
    Write-Field "Name"          $audio.Name
    Write-Field "Manufacturer"  $audio.Manufacturer
    Write-Field "Status"        $audio.Status
    Write-Field "Device ID"     $audio.DeviceID
}

# -----------------------------------------------------------------------------
# USB CONTROLLERS
# -----------------------------------------------------------------------------
Write-Header "USB CONTROLLERS"

$usbControllers = Get-CimInstance Win32_USBController

foreach ($usb in $usbControllers) {
    Write-Report ""
    Write-Field "Name"          $usb.Name
    Write-Field "Manufacturer"  $usb.Manufacturer
    Write-Field "Status"        $usb.Status
}

# -----------------------------------------------------------------------------
# MONITORS / DISPLAYS
# -----------------------------------------------------------------------------
Write-Header "MONITORS & DISPLAYS"

$monitors = Get-CimInstance WmiMonitorID -Namespace root\wmi -ErrorAction SilentlyContinue

if ($monitors) {
    foreach ($monitor in $monitors) {
        # Filter zero bytes first - pipe inside a method call argument breaks the PowerShell parser
        [byte[]]$mfrBytes    = $monitor.ManufacturerName | Where-Object { $_ -ne 0 }
        [byte[]]$modelBytes  = $monitor.UserFriendlyName | Where-Object { $_ -ne 0 }
        [byte[]]$serialBytes = $monitor.SerialNumberID   | Where-Object { $_ -ne 0 }
        $mfr    = [System.Text.Encoding]::ASCII.GetString($mfrBytes)
        $model  = [System.Text.Encoding]::ASCII.GetString($modelBytes)
        $serial = [System.Text.Encoding]::ASCII.GetString($serialBytes)

        Write-Report ""
        Write-Field "Manufacturer"  $mfr
        Write-Field "Model"         $model
        Write-Field "Serial"        $serial
        Write-Field "Year of Mfr"   $monitor.YearOfManufacture
        Write-Field "Week of Mfr"   $monitor.WeekOfManufacture
    }
} else {
    Write-Report "    No monitor information available via WMI."
}

# Resolution from video controller
$videoControllers = Get-CimInstance Win32_VideoController
foreach ($vc in $videoControllers) {
    if ($vc.CurrentHorizontalResolution -gt 0) {
        Write-Report ""
        Write-Field "Active Resolution"  "$($vc.CurrentHorizontalResolution) x $($vc.CurrentVerticalResolution)"
        Write-Field "Refresh Rate"       "$($vc.CurrentRefreshRate) Hz"
        Write-Field "Color Depth"        "$($vc.CurrentBitsPerPixel)-bit"
    }
}

# -----------------------------------------------------------------------------
# POWER / BATTERY
# -----------------------------------------------------------------------------
Write-Header "POWER"

$battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
if ($battery) {
    foreach ($bat in $battery) {
        Write-Field "Battery Name"      $bat.Name
        Write-Field "Status"            $bat.Status
        Write-Field "Charge Remaining"  "$($bat.EstimatedChargeRemaining)%"
        Write-Field "Estimated Runtime" "$($bat.EstimatedRunTime) minutes"
        Write-Field "Chemistry"         $(switch ($bat.Chemistry) {
                                            1 { "Other" }; 2 { "Unknown" }; 3 { "Lead Acid" }
                                            4 { "Nickel Cadmium" }; 5 { "Nickel Metal Hydride" }
                                            6 { "Lithium Ion" }; 7 { "Zinc Air" }; 8 { "Lithium Polymer" }
                                            default { $bat.Chemistry }
                                        })
    }
} else {
    Write-Report "    No battery detected (desktop system)."
}

# Active power plan
$powerPlan = Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan |
             Where-Object { $_.IsActive -eq $true }
if ($powerPlan) {
    Write-Field "Active Power Plan"  $powerPlan.ElementName
}

# -----------------------------------------------------------------------------
# TEMPERATURES - requires Open Hardware Monitor or HWiNFO to be running
# Falls back gracefully if unavailable
# -----------------------------------------------------------------------------
Write-Header "TEMPERATURES (via Open Hardware Monitor WMI bridge)"

$ohmSensors = Get-CimInstance -Namespace "root\OpenHardwareMonitor" -ClassName Sensor `
              -ErrorAction SilentlyContinue |
              Where-Object { $_.SensorType -eq "Temperature" }

if ($ohmSensors) {
    foreach ($sensor in $ohmSensors | Sort-Object Parent, Name) {
        Write-Field $sensor.Name "$([math]::Round($sensor.Value, 1))  C  (Parent: $($sensor.Parent))"
    }
} else {
    Write-Report "    Temperature data not available."
    Write-Report "    To enable: install and run Open Hardware Monitor as Administrator."
    Write-Report "    Download: https://openhardwaremonitor.org"
    Write-Report ""
    Write-Report "    For NVIDIA GPU temps, see the nvidia-smi section above."
}

# -----------------------------------------------------------------------------
# INSTALLED CRITICAL RUNTIMES & TOOLS
# -----------------------------------------------------------------------------
Write-Header "KEY RUNTIMES & TOOLS"

# .NET versions
Write-SubHeader ".NET / .NET Framework"
$dotnetRuntimes = & dotnet --list-runtimes 2>$null
if ($dotnetRuntimes) {
    foreach ($runtime in $dotnetRuntimes) {
        Write-Report "    $runtime"
    }
} else {
    Write-Report "    dotnet CLI not found on PATH."
}

$dotnetSdks = & dotnet --list-sdks 2>$null
if ($dotnetSdks) {
    Write-Report ""
    Write-Report "    Installed SDKs:"
    foreach ($sdk in $dotnetSdks) {
        Write-Report "      $sdk"
    }
}

# Rust
Write-SubHeader "Rust"
$rustcVersion  = & rustc --version 2>$null
$cargoVersion  = & cargo --version 2>$null
$rustupVersion = & rustup --version 2>$null
Write-Field "rustc"   $(if ($rustcVersion) { $rustcVersion } else { "Not found" })
Write-Field "cargo"   $(if ($cargoVersion) { $cargoVersion } else { "Not found" })
Write-Field "rustup"  $(if ($rustupVersion) { $rustupVersion } else { "Not found" })

# Node.js / npm
Write-SubHeader "Node.js"
$nodeVersion = & node --version 2>$null
$npmVersion  = & npm --version 2>$null
Write-Field "node"  $(if ($nodeVersion) { $nodeVersion } else { "Not found" })
Write-Field "npm"   $(if ($npmVersion) { $npmVersion } else { "Not found" })

# Python
Write-SubHeader "Python"
$pythonVersion = & python --version 2>$null
$pip3Version   = & pip --version 2>$null
Write-Field "python"  $(if ($pythonVersion) { $pythonVersion } else { "Not found" })
Write-Field "pip"     $(if ($pip3Version) { $pip3Version } else { "Not found" })

# Git
Write-SubHeader "Git"
$gitVersion = & git --version 2>$null
Write-Field "git"  $(if ($gitVersion) { $gitVersion } else { "Not found" })

# CUDA / Ollama
Write-SubHeader "AI / ML Tooling"

# Pre-initialize to empty string so StrictMode never throws on unset variable
$nvccVersion   = ""
$ollamaVersion = ""

# Use Get-Command first to avoid "not recognized" errors polluting output
if (Get-Command "nvcc" -ErrorAction SilentlyContinue) {
    $nvccVersion = (& nvcc --version 2>$null | Select-Object -Last 1)
}
if (Get-Command "ollama" -ErrorAction SilentlyContinue) {
    $ollamaVersion = (& ollama --version 2>$null)
}

Write-Field "CUDA (nvcc)"   $(if ($nvccVersion)   { $nvccVersion }   else { "Not found / not on PATH" })
Write-Field "Ollama"        $(if ($ollamaVersion) { $ollamaVersion } else { "Not installed" })

# Docker
Write-SubHeader "Docker"
$dockerVersion = & docker --version 2>$null
Write-Field "docker"  $(if ($dockerVersion) { $dockerVersion } else { "Not found" })

# -----------------------------------------------------------------------------
# SYSTEM SUMMARY - quick reference at the end
# -----------------------------------------------------------------------------
Write-Header "QUICK REFERENCE SUMMARY"

$cpu      = (Get-CimInstance Win32_Processor | Select-Object -First 1)
$totalRAM = "$([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)) GB"
$gpuNames = (Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name) -join " | "

Write-Report ""
Write-Field "Machine"         $machineName
Write-Field "OS"              $os.Caption
Write-Field "CPU"             $cpu.Name.Trim()
Write-Field "Cores / Threads" "$($cpu.NumberOfCores) cores / $($cpu.NumberOfLogicalProcessors) threads"
Write-Field "Base Clock"      (Format-MHz $cpu.MaxClockSpeed)
Write-Field "RAM"             $totalRAM
Write-Field "GPU(s)"          $gpuNames

Write-Report ""
Write-Report ("=" * 72)
Write-Report "  END OF REPORT - $reportTimestamp"
Write-Report ("=" * 72)
Write-Report ""

# -----------------------------------------------------------------------------
# SAVE TO FILE - always auto-saves silently, no interaction required
# Console output above is visible in any environment (local or SSH).
# File output lands next to the script for easy retrieval.
# -----------------------------------------------------------------------------

# Default output path: timestamped file in same directory as the script.
# Can be overridden via -OutputFile parameter.
if (-not $OutputFile) {
    $timestamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $scriptDir  = if ($PSScriptRoot) { $PSScriptRoot } else { $PWD.Path }
    $OutputFile = Join-Path $scriptDir "HardwareProfile_${machineName}_${timestamp}.txt"
}

# Flush buffer to file - errors and all output captured
$script:ReportLines | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host ""
Write-Host "Report saved to: $OutputFile"
