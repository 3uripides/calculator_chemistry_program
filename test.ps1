# Usage: .\test.ps1 TNAME [TNAME...]  -- boots CEmu once, sends src programs, then for each test:
# sends tests\TNAME, launches it and saves docs\TNAME.png. A test that errors may leave the emulator
# on the error screen; rerun that test alone.
$exe  = "$env:LOCALAPPDATA\Programs\CEmu\CEmu.exe"
$root = $PSScriptRoot
function Cmd($a) { $j = Start-Job { param($e,$x) & $e @x 2>&1 | Out-String } -ArgumentList $exe,$a
  Wait-Job $j -Timeout 40 | Out-Null; Receive-Job $j | Out-Null; Stop-Job $j -ErrorAction SilentlyContinue; Remove-Job $j -Force }
New-Item -ItemType Directory -Force "$root\docs" | Out-Null
Get-Process CEmu -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2
Start-Process $exe -ArgumentList '--id','cemu','--no-state','--rom',"`"$root\New folder\thing.rom`""; Start-Sleep 10
$first = $true
foreach ($p in (Get-ChildItem "$root\src\*.txt" | ForEach-Object { $_.BaseName.ToUpper() })) {
  $a = @('--id','cemu'); if (-not $first) { $a += '--no-reset' }; $a += '--send'; $a += "$root\build\send\$p.8xp"
  Cmd $a; Start-Sleep ($(if ($first) { 5 } else { 2 })); $first = $false
}
foreach ($n in $args) {
  Cmd @('--id','cemu','--no-reset','--send',"$root\build\tests\$n.8xp"); Start-Sleep 2
  Cmd @('--id','cemu','--launch',$n); Start-Sleep 5
  Cmd @('--id','cemu','--screenshot',"$root\docs\$n.png"); Start-Sleep 2
  "docs\$n.png"
}
