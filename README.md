# WCH OpenOCD Flash Skill

一个用于 WCH RISC-V 工程的 Codex/AI Agent 技能，支持使用 MounRiver Studio 2 自带的 WCH OpenOCD 和 WCH-LinkE/WCH-Link 完成固件编译、烧录、校验和复位。

## 适用场景

- WCH RISC-V / CH58x / CH57x / CH32V 工程
- MounRiver Studio 2 工程
- WCH-LinkE / WCH-Link 仿真器
- 需要自动执行 `build -> flash -> verify -> reset`

## 功能

- 自动定位 MounRiver Studio 2 常见安装路径
- 调用 MounRiver 自带 `make.exe` 编译工程
- 使用 WCH OpenOCD 和 `wch-riscv.cfg` 烧录 ELF/HEX
- 执行 `verify reset exit`
- 烧录失败时保留 OpenOCD 输出，方便定位连接、占用或芯片识别问题

## 快速使用

在技能目录中运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-wch-openocd.ps1 -ProjectDir <工程目录>
```

示例：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-wch-openocd.ps1 -ProjectDir C:\Users\lhw\mounriver-studio-projects\CH582M_BLE_HeartRate
```

## 可选参数

```powershell
-NoBuild
```

跳过编译，直接烧录现有固件。

```powershell
-MounRiverRoot <路径>
```

指定 MounRiver Studio 2 安装目录。

```powershell
-Firmware <路径>
```

指定要烧录的 ELF 或 HEX 文件。

```powershell
-Config <路径>
```

指定 OpenOCD 配置文件。

## 成功标志

日志中出现以下内容表示烧录和校验成功：

```text
** Programming Finished **
** Verify Started **
** Verified OK **
** Resetting Target **
```

## 说明

烧录会改写目标板 Flash。该技能设计为在用户明确要求烧录时执行，普通探测或咨询场景应先检查工具路径、工程配置和仿真器连接状态。
