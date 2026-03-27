# HardwareProfiler

SEE NEW CROSS-PLATFORM VERSION: [https://github.com/joe-cena-git/RustHardwareProfiler]

A single-file PowerShell script that generates a comprehensive hardware profile of any Windows machine. Designed for both interactive and unattended (SSH, scheduled task) use — no prompts, no dependencies, just run and get a detailed report.

## What It Captures

| Category | Details |
|---|---|
| **OS** | Edition, version, build, architecture, install date, uptime |
| **Motherboard & BIOS** | Manufacturer, model, serial, BIOS version/date |
| **CPU** | Model, cores/threads, base clock, cache, socket, virtualization |
| **RAM** | Total capacity, per-DIMM breakdown (size, speed, type, slot) |
| **GPU(s)** | Name, VRAM, driver version; NVIDIA cards get full `nvidia-smi` details (temp, power, PCIe, clocks) |
| **Storage** | Physical disks (model, size, type, interface) and logical drives (capacity, free space, file system) |
| **Network** | Adapter name, MAC, speed, IP/subnet/gateway/DNS for each active NIC |
| **Audio** | Detected audio devices |
| **USB** | USB controller inventory |
| **Monitors** | Display name, resolution, size via WMI |
| **Power** | Active power plan; battery status and charge for laptops |
| **Temperatures** | Sensor readings via Open Hardware Monitor (when available) |
| **Dev Tools** | .NET, Rust, Node.js, Python, Git, CUDA, Ollama, Docker |

Every report ends with a **Quick Reference Summary** for at-a-glance specs.

## Requirements

- **PowerShell 5.1+** (ships with Windows 10/11; also works on PowerShell 7+)
- **Windows** (uses WMI/CIM)
- **Administrator** recommended for full BIOS and thermal data

## Quick Start

```powershell
# Run from the directory where you downloaded the script
.\Get-HardwareProfile.ps1
```

Output is automatically saved to a timestamped file next to the script:
`HardwareProfile_MACHINENAME_2026-03-27_14-30-00.txt`

### Custom Output Path

```powershell
.\Get-HardwareProfile.ps1 -OutputFile "C:\reports\my-machine.txt"
```

### Remote / SSH Execution

```powershell
ssh user@machine "powershell -ExecutionPolicy Bypass -File C:\Tools\Get-HardwareProfile.ps1"
```

No interactive prompts — all errors are captured into the report file, not printed to the console.

## Optional Integrations

| Tool | Benefit |
|---|---|
| [NVIDIA GPU drivers](https://www.nvidia.com/drivers) | `nvidia-smi` on PATH enables detailed GPU metrics (temp, power draw, clocks, PCIe link) |
| [Open Hardware Monitor](https://openhardwaremonitor.org/) | Running with its WMI bridge exposes CPU/GPU/disk temperature sensors |

These are detected automatically at runtime. If absent, those sections are gracefully skipped.

## Example Output

```
========================================================================
  HARDWARE PROFILE REPORT
  Generated : 2026-03-27 12:41:50
  Machine   : DESKTOP-EXAMPLE
  User      : User
========================================================================

========================================================================
  OPERATING SYSTEM
========================================================================
    OS Name                         : Microsoft Windows 10 Pro
    Version                         : 10.0.19045
    Build                           : 19045
    Architecture                    : 64-bit
    Install Date                    : 2023-08-14
    Last Boot                       : 2026-03-22 14:21:03
    Uptime                          : 4d 22h 20m
    System Type                     : x64-based PC
    Domain/Workgroup                : WORKGROUP (Workgroup)

========================================================================
  MOTHERBOARD & BIOS
========================================================================

  Motherboard
  --------------------------------------------------------
    Manufacturer                    : MSI
    Product                         : Z270-A PRO (MS-7A71)
    Version                         : 1.0
    Serial Number                   : [REDACTED]

  BIOS
  --------------------------------------------------------
    Manufacturer                    : American Megatrends Inc.
    Name                            : 1.50
    Version                         : 1.50
    Release Date                    : 2018-01-24
    Serial Number                   : [REDACTED]

  Chassis
  --------------------------------------------------------
    Manufacturer                    : MSI
    Model                           :
    Serial Number                   : [REDACTED]

========================================================================
  PROCESSOR (CPU)
========================================================================
    Name                            : Intel(R) Core(TM) i7-6700K CPU @ 4.00GHz
    Manufacturer                    : GenuineIntel
    Socket                          : LGA1151
    Architecture                    : x64
    Physical Cores                  : 4
    Logical Processors              : 8
    Threads per Core                : 2
    Base Clock                      : 4.01 GHz (4008 MHz)
    L2 Cache                        : 1.00 MB
    L3 Cache                        : 8.00 MB
    Status                          : OK
    Load (current)                  : 3%
    Virtualization                  : Enabled

========================================================================
  MEMORY (RAM)
========================================================================
    Total Installed                 : 63.83 GB
    Currently Used                  : 13.86 GB
    Currently Free                  : 49.97 GB
    Stick Count                     : 4

  Stick 1 - BANK 0 / ChannelA-DIMM0
  --------------------------------------------------------
    Capacity                        : 16 GB
    Type                            : DDR4
    Speed                           : 2400 MHz
    Configured Speed                : 2400 MHz
    Manufacturer                    : Corsair
    Part Number                     : CMU32GX4M2C3200C16
    Serial Number                   : [REDACTED]
    Form Factor                     : DIMM
    Data Width                      : 64-bit

  Stick 2 - BANK 1 / ChannelA-DIMM1
  --------------------------------------------------------
    Capacity                        : 16 GB
    Type                            : DDR4
    Speed                           : 2400 MHz
    Configured Speed                : 2400 MHz
    Manufacturer                    : Corsair
    Part Number                     : CMU32GX4M2C3200C16
    Serial Number                   : [REDACTED]
    Form Factor                     : DIMM
    Data Width                      : 64-bit

  Stick 3 - BANK 2 / ChannelB-DIMM0
  --------------------------------------------------------
    Capacity                        : 16 GB
    Type                            : DDR4
    Speed                           : 2400 MHz
    Configured Speed                : 2400 MHz
    Manufacturer                    : Corsair
    Part Number                     : CMU32GX4M2C3200C16
    Serial Number                   : [REDACTED]
    Form Factor                     : DIMM
    Data Width                      : 64-bit

  Stick 4 - BANK 3 / ChannelB-DIMM1
  --------------------------------------------------------
    Capacity                        : 16 GB
    Type                            : DDR4
    Speed                           : 2400 MHz
    Configured Speed                : 2400 MHz
    Manufacturer                    : Corsair
    Part Number                     : CMU32GX4M2C3200C16
    Serial Number                   : [REDACTED]
    Form Factor                     : DIMM
    Data Width                      : 64-bit

========================================================================
  GRAPHICS (GPU)
========================================================================

  Intel(R) HD Graphics 530
  --------------------------------------------------------
    Name                            : Intel(R) HD Graphics 530
    Driver Version                  : 31.0.101.2111
    Driver Date                     : 2022-07-18
    VRAM (WMI)                      : 1.00 GB
    Video Mode                      :
    Current Refresh                 :  Hz
    Max Refresh                     :  Hz
    Bits per Pixel                  :
    Status                          : OK

  NVIDIA GeForce GTX 760
  --------------------------------------------------------
    Name                            : NVIDIA GeForce GTX 760
    Driver Version                  : 30.0.14.7514
    Driver Date                     : 2024-06-09
    VRAM (WMI)                      : 4.00 GB
    Video Mode                      : 1920 x 1080 x 4294967296 colors
    Current Refresh                 : 60 Hz
    Max Refresh                     : 75 Hz
    Bits per Pixel                  : 32
    Status                          : OK

  NVIDIA Detailed - nvidia-smi
  --------------------------------------------------------
    +-----------------------------------------------------------------------------+
    | NVIDIA-SMI 475.14       Driver Version: 475.14       CUDA Version: 11.4     |
    |-------------------------------+----------------------+----------------------+
    | GPU  Name            TCC/WDDM | Bus-Id        Disp.A | Volatile Uncorr. ECC |
    | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
    |                               |                      |               MIG M. |
    |===============================+======================+======================|
    |   0  NVIDIA GeForce ... WDDM  | 00000000:01:00.0 N/A |                  N/A |
    | 42%   45C    P0    N/A /  N/A |   1233MiB /  4096MiB |      2%      Default |
    |                               |                      |                  N/A |
    +-------------------------------+----------------------+----------------------+

  NVIDIA Per-GPU Metrics
  --------------------------------------------------------

    GPU Index                       : 0
    Name                            : NVIDIA GeForce GTX 760
    Driver Version                  : 475.14
    CUDA Version                    : 11.4
    VRAM Total                      : 4096 MB
    VRAM Used                       : 1233 MB
    VRAM Free                       : 2863 MB
    Temperature                     : 45 C
    Fan Speed                       : 42 %
    Power Draw                      : N/A W
    Power Limit                     : N/A W
    GPU Clock                       : 1006 MHz
    Memory Clock                    : 1502 MHz
    GPU Utilization                 : 2 %
    Memory Utilization              : 8 %
    PCIe Gen                        : 3
    PCIe Width                      : x16

========================================================================
  STORAGE
========================================================================

  Physical Disks
  --------------------------------------------------------

    Disk 0                          : Samsung SSD 870 EVO 1TB
      Media Type                    : SSD
      Size                          : 931.51 GB
      Bus Type                      : SATA
      Spindle Speed                 : N/A (SSD/NVMe)
      Health Status                 : Healthy
      Operational Status            : OK
      Firmware Version              : SVT02B6Q
      Serial Number                 : [REDACTED]

    Disk 1                          : Samsung SSD 840 EVO 1TB
      Media Type                    : SSD
      Size                          : 931.51 GB
      Bus Type                      : SATA
      Spindle Speed                 : N/A (SSD/NVMe)
      Health Status                 : Healthy
      Operational Status            : OK
      Firmware Version              : EXT0BB6Q
      Serial Number                 : [REDACTED]

  Logical Drives
  --------------------------------------------------------

    Drive C:                        :
      File System                   : NTFS
      Total Size                    : 930.89 GB
      Used                          : 550.03 GB (59.1%)
      Free                          : 380.86 GB

    Drive D:                        :
      File System                   : NTFS
      Total Size                    : 930.99 GB
      Used                          : 703.79 GB (75.6%)
      Free                          : 227.20 GB

========================================================================
  NETWORK ADAPTERS
========================================================================

    Adapter                         : Ethernet
      Description                   : Gigabit PCI Express Adapter
      Status                        : Up
      MAC Address                   : [REDACTED]
      Link Speed                    : 1000 Mbps
      Connector Type                : True
      IPv4 Address                  : 192.168.1.x
      DHCP Enabled                  : Enabled
      Interface Type                : 6

    Adapter                         : Wi-Fi
      Description                   : Intel(R) Wi-Fi 6 AX200
      Status                        : Disconnected
      MAC Address                   : [REDACTED]
      Link Speed                    : Disconnected / Unknown
      Connector Type                : True
      IPv4 Address                  : Not assigned
      DHCP Enabled                  : Enabled
      Interface Type                : 71

========================================================================
  AUDIO DEVICES
========================================================================

    Name                            : High Definition Audio Device
    Manufacturer                    : Microsoft
    Status                          : OK
    Device ID                       : [REDACTED]

    Name                            : NVIDIA High Definition Audio
    Manufacturer                    : NVIDIA
    Status                          : OK
    Device ID                       : [REDACTED]

    Name                            : Intel(R) Display Audio
    Manufacturer                    : Intel(R) Corporation
    Status                          : OK
    Device ID                       : [REDACTED]

========================================================================
  USB CONTROLLERS
========================================================================

    Name                            : Intel(R) USB 3.0 eXtensible Host Controller - 1.0 (Microsoft)
    Manufacturer                    : Generic USB xHCI Host Controller
    Status                          : OK

========================================================================
  MONITORS & DISPLAYS
========================================================================

    Manufacturer                    : DEL
    Model                           : DELL U3415W
    Serial                          : [REDACTED]
    Year of Mfr                     : 2017
    Week of Mfr                     : 16

    Manufacturer                    : GSM
    Model                           : LG ULTRAGEAR
    Serial                          : [REDACTED]
    Year of Mfr                     : 2023
    Week of Mfr                     : 22

    Active Resolution               : 3440 x 1440
    Refresh Rate                    : 60 Hz
    Color Depth                     : 32-bit

    Active Resolution               : 1920 x 1080
    Refresh Rate                    : 144 Hz
    Color Depth                     : 32-bit

========================================================================
  POWER
========================================================================
    No battery detected (desktop system).
    Active Power Plan               : High performance

========================================================================
  TEMPERATURES (via Open Hardware Monitor WMI bridge)
========================================================================
    CPU Core #1                     : 38.0 C  (Parent: /intelcpu/0)
    CPU Core #2                     : 37.0 C  (Parent: /intelcpu/0)
    CPU Core #3                     : 39.0 C  (Parent: /intelcpu/0)
    CPU Core #4                     : 37.0 C  (Parent: /intelcpu/0)
    CPU Package                     : 41.0 C  (Parent: /intelcpu/0)
    GPU Core                        : 45.0 C  (Parent: /nvidiagpu/0)
    GPU Memory                      : 47.0 C  (Parent: /nvidiagpu/0)
    HDD Samsung SSD 870 EVO 1TB     : 32.0 C  (Parent: /hdd/0)
    HDD Samsung SSD 840 EVO 1TB     : 31.0 C  (Parent: /hdd/1)

========================================================================
  KEY RUNTIMES & TOOLS
========================================================================

  .NET / .NET Framework
  --------------------------------------------------------
    Microsoft.AspNetCore.App 8.0.24 [C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App]
    Microsoft.AspNetCore.App 9.0.13 [C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App]
    Microsoft.NETCore.App 8.0.24 [C:\Program Files\dotnet\shared\Microsoft.NETCore.App]
    Microsoft.NETCore.App 9.0.13 [C:\Program Files\dotnet\shared\Microsoft.NETCore.App]
    Microsoft.WindowsDesktop.App 8.0.24 [C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App]
    Microsoft.WindowsDesktop.App 9.0.13 [C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App]

    Installed SDKs:
      8.0.100 [C:\Program Files\dotnet\sdk]
      9.0.311 [C:\Program Files\dotnet\sdk]

  Rust
  --------------------------------------------------------
    rustc                           : rustc 1.93.1 (01f6ddf75 2026-02-11)
    cargo                           : cargo 1.93.1 (083ac5135 2025-12-15)
    rustup                          : rustup 1.28.2 (e4f3ad6f8 2025-04-28)

  Node.js
  --------------------------------------------------------
    node                            : v24.11.1
    npm                             : 11.6.2

  Python
  --------------------------------------------------------
    python                          : Python 3.14.0
    pip                             : pip 25.2 from C:\Python314\Lib\site-packages\pip (python 3.14)

  Git
  --------------------------------------------------------
    git                             : git version 2.48.1.windows.1

  AI / ML Tooling
  --------------------------------------------------------
    CUDA (nvcc)                     : Cuda compilation tools, release 12.4, V12.4.131
    Ollama                          : ollama version is 0.6.2

  Docker
  --------------------------------------------------------
    docker                          : Docker version 25.0.3, build 4debf41

========================================================================
  QUICK REFERENCE SUMMARY
========================================================================

    Machine                         : DESKTOP-EXAMPLE
    OS                              : Microsoft Windows 10 Pro
    CPU                             : Intel(R) Core(TM) i7-6700K CPU @ 4.00GHz
    Cores / Threads                 : 4 cores / 8 threads
    Base Clock                      : 4.01 GHz (4008 MHz)
    RAM                             : 64 GB
    GPU(s)                          : Intel(R) HD Graphics 530 | NVIDIA GeForce GTX 760

========================================================================
  END OF REPORT - 2026-03-27 12:41:50
========================================================================

Report saved to: C:\Users\User\Downloads\HardwareProfile_DESKTOP-EXAMPLE_2026-03-27_12-41-50.txt
```

## Use Cases

- **System audits** — document hardware across a fleet of machines
- **Build environment snapshots** — record the exact specs of CI runners or dev workstations
- **Support & troubleshooting** — share a single file instead of 10 screenshots
- **Inventory tracking** — keep timestamped profiles for asset management

## Contributing

Contributions are welcome. Please open an issue or submit a pull request.

## License

This project is not yet licensed. If you intend to use it in your own projects, please contact the author.
