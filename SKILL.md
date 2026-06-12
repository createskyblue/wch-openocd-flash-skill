---
name: wch-openocd-flash
description: 使用 WCH-LinkE/WCH-Link、MounRiver Studio 2、WCH OpenOCD 给 WCH RISC-V/CH58x/CH57x/CH32V 工程编译和烧录固件。触发词：WCH 烧录、WCH-LinkE、MounRiver 下载、CH582 烧录、CH583 烧录、CH57x 烧录、CH32V 烧录、openocd wch-riscv、program verify reset。
---

# WCH OpenOCD Flash

核心规则：烧录会改写目标板 Flash。只有在用户明确要求“烧录、下载、刷入、program、flash”时才执行；如果用户只是问能否烧录，先做工具和连接探测。

## 适用场景

- MounRiver Studio 2 生成的 WCH RISC-V 工程。
- 使用 WCH-LinkE/WCH-Link 仿真器，通过 WCH OpenOCD 下载固件。
- 常见目标包括 CH58x、CH57x、CH32V 等 WCH RISC-V 芯片。
- 项目中有 `.launch` 文件，或 `obj/*.elf` / `obj/*.hex` 已经生成。

## 工作流

1. 确认当前目录是目标固件工程。
   - 读取 `git status --short --branch`。
   - 查找 `.launch`、`obj/*.elf`、`obj/*.hex`。
   - 若工作区有未提交改动，继续烧录可以，但不要修改或回退用户改动。

2. 定位 MounRiver 工具。
   - 优先路径：`C:\MounRiver\MounRiver_Studio2`。
   - OpenOCD：`resources\app\resources\win32\components\WCH\OpenOCD\OpenOCD\bin\openocd.exe`。
   - RISC-V GCC：`resources\app\resources\win32\components\WCH\Toolchain\RISC-V Embedded GCC\bin`。
   - Make：`resources\app\resources\win32\others\Build_Tools\Make\bin\make.exe`。

3. 读取项目 `.launch`。
   - 优先使用其中的 `com.mounriver.debug.gdbjtag.openocd.gdbServerOther` 配置。
   - 常见 WCH RISC-V 配置是 `wch-riscv.cfg`。
   - 常见程序是 `obj/<project>.elf`。

4. 编译固件。
   - 从 `obj` 目录运行 MounRiver 自带 `make.exe --no-print-directory all`。
   - 给 PATH 临时加入 RISC-V GCC bin 目录。
   - 编译失败时停止，不烧录旧固件。

5. 烧录并校验。
   - 使用 OpenOCD 命令：
     ```powershell
     openocd.exe -f "<wch-riscv.cfg>" -c "program <firmware.elf> verify reset exit"
     ```
   - 成功标志包括：
     ```text
     ** Programming Finished **
     ** Verify Started **
     ** Verified OK **
     ** Resetting Target **
     ```

6. 失败处理。
   - 如果 OpenOCD 无法打开 WCH-Link，检查 MounRiver、WCH-LinkUtility 或其他 OpenOCD 是否占用仿真器。
   - 如果芯片无法识别，检查 WCH-Link 模式是否为 RV、供电、SWD/SDI 接线和目标芯片系列。
   - 不要强行使用 ISP 工具替代 OpenOCD，除非用户明确要求 ISP/串口下载。

## 快速脚本

优先使用本技能自带脚本：

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\lhw\.cc-switch\skills\wch-openocd-flash\scripts\flash-wch-openocd.ps1 -ProjectDir <工程目录>
```

可选参数：

- `-NoBuild`：跳过编译，直接烧录现有 ELF。
- `-MounRiverRoot <路径>`：指定 MounRiver Studio 2 根目录。
- `-Firmware <路径>`：指定要烧录的 ELF/HEX。
- `-Config <路径>`：指定 OpenOCD cfg。

## 预交付检查

- 已说明是否编译成功。
- 已说明是否执行了烧录。
- 若烧录成功，报告 `Verified OK` 和是否 reset。
- 若失败，给出最可能原因和下一步检查项。
- 不要声称烧录成功，除非日志出现 `Verified OK` 或等价校验成功信息。
