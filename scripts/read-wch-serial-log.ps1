param(
    [string]$MounRiverRoot = "C:\MounRiver\MounRiver_Studio2",
    [string]$Config = "",
    [string]$PortName = "",
    [string]$PortNamePattern = "*WCH-Link SERIAL*",
    [int]$BaudRate = 500000,
    [int]$Seconds = 10,
    [switch]$NoReset
)

$ErrorActionPreference = "Stop"

function Resolve-ExistingPath {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Label not found: $Path"
    }
    (Resolve-Path -LiteralPath $Path).Path
}

if ([string]::IsNullOrWhiteSpace($PortName)) {
    $portInfo = Get-CimInstance Win32_SerialPort |
        Where-Object { $_.Name -like $PortNamePattern -or $_.Description -like $PortNamePattern } |
        Select-Object -First 1
    if ($null -eq $portInfo) {
        throw "Serial port not found by pattern: $PortNamePattern"
    }
    $PortName = $portInfo.DeviceID
}

Write-Host "Serial: $PortName @ $BaudRate baud"

$port = [System.IO.Ports.SerialPort]::new(
    $PortName,
    $BaudRate,
    [System.IO.Ports.Parity]::None,
    8,
    [System.IO.Ports.StopBits]::One
)

$resetProcess = $null
try {
    $port.Open()
    $port.DiscardInBuffer()

    if (-not $NoReset) {
        $openocd = Join-Path $MounRiverRoot "resources\app\resources\win32\components\WCH\OpenOCD\OpenOCD\bin\openocd.exe"
        $defaultConfig = Join-Path $MounRiverRoot "resources\app\resources\win32\components\WCH\OpenOCD\OpenOCD\bin\wch-riscv.cfg"
        if ([string]::IsNullOrWhiteSpace($Config)) {
            $Config = $defaultConfig
        }
        $openocd = Resolve-ExistingPath $openocd "WCH OpenOCD"
        $Config = Resolve-ExistingPath $Config "OpenOCD config"

        $args = @("-f", $Config, "-c", "init", "-c", "reset", "-c", "resume", "-c", "exit")
        Write-Host "Reset: OpenOCD init/reset/resume"
        $resetProcess = Start-Process -FilePath $openocd -ArgumentList $args -WindowStyle Hidden -PassThru
    }

    $deadline = [DateTime]::UtcNow.AddSeconds($Seconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        $text = $port.ReadExisting()
        if ($text.Length -gt 0) {
            Write-Host -NoNewline $text
        }
        Start-Sleep -Milliseconds 50
    }

    if ($null -ne $resetProcess) {
        $resetProcess.WaitForExit()
        if ($resetProcess.ExitCode -ne 0) {
            throw "OpenOCD reset failed with exit code $($resetProcess.ExitCode)"
        }
    }
} finally {
    if ($port.IsOpen) {
        $port.Close()
    }
    $port.Dispose()
}
