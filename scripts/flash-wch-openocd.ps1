param(
    [string]$ProjectDir = (Get-Location).Path,
    [string]$MounRiverRoot = "C:\MounRiver\MounRiver_Studio2",
    [string]$Firmware = "",
    [string]$Config = "",
    [switch]$NoBuild
)

$ErrorActionPreference = "Stop"

function Resolve-ExistingPath {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Label not found: $Path"
    }
    (Resolve-Path -LiteralPath $Path).Path
}

$ProjectDir = Resolve-ExistingPath $ProjectDir "Project directory"
$openocd = Join-Path $MounRiverRoot "resources\app\resources\win32\components\WCH\OpenOCD\OpenOCD\bin\openocd.exe"
$defaultConfig = Join-Path $MounRiverRoot "resources\app\resources\win32\components\WCH\OpenOCD\OpenOCD\bin\wch-riscv.cfg"
$gccBin = Join-Path $MounRiverRoot "resources\app\resources\win32\components\WCH\Toolchain\RISC-V Embedded GCC\bin"
$make = Join-Path $MounRiverRoot "resources\app\resources\win32\others\Build_Tools\Make\bin\make.exe"

$openocd = Resolve-ExistingPath $openocd "WCH OpenOCD"
if ([string]::IsNullOrWhiteSpace($Config)) {
    $Config = $defaultConfig
}
$Config = Resolve-ExistingPath $Config "OpenOCD config"

$objDir = Join-Path $ProjectDir "obj"
if (-not $NoBuild) {
    $objDir = Resolve-ExistingPath $objDir "obj directory"
    $make = Resolve-ExistingPath $make "MounRiver make"
    $gccBin = Resolve-ExistingPath $gccBin "RISC-V GCC bin"
    $env:Path = "$gccBin;$env:Path"
    Push-Location $objDir
    try {
        & $make --no-print-directory all
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed with exit code $LASTEXITCODE"
        }
    } finally {
        Pop-Location
    }
}

if ([string]::IsNullOrWhiteSpace($Firmware)) {
    $elf = Get-ChildItem -LiteralPath $objDir -Filter *.elf -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $elf) {
        throw "No ELF found under $objDir. Provide -Firmware explicitly."
    }
    $Firmware = $elf.FullName
}
$Firmware = Resolve-ExistingPath $Firmware "Firmware"
$firmwareForOpenOcd = $Firmware -replace "\\", "/"

Write-Host "OpenOCD:  $openocd"
Write-Host "Config:   $Config"
Write-Host "Firmware: $Firmware"

& $openocd -f $Config -c "program $firmwareForOpenOcd verify reset exit"
if ($LASTEXITCODE -ne 0) {
    throw "OpenOCD failed with exit code $LASTEXITCODE"
}
