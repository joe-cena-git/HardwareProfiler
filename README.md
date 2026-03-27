# HardwareProfiler

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

## Example Output (abridged)

```
========================================================================
  HARDWARE PROFILE REPORT
  Generated : 2026-03-27 14:30:00
  Machine   : WORKSTATION-01
========================================================================

── OPERATING SYSTEM ────────────────────────────────────────────────────
  OS Name              : Microsoft Windows 11 Pro
  Version              : 10.0.22631
  Architecture         : 64-bit
  ...

── PROCESSOR (CPU) ─────────────────────────────────────────────────────
  Name                 : AMD Ryzen 9 7950X
  Cores / Threads      : 16 / 32
  Base Clock           : 4.50 GHz
  ...

── QUICK REFERENCE SUMMARY ─────────────────────────────────────────────
  CPU             : AMD Ryzen 9 7950X
  Cores / Threads : 16 cores / 32 threads
  RAM             : 64 GB
  GPU(s)          : NVIDIA GeForce RTX 4090
========================================================================
  END OF REPORT
========================================================================
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
