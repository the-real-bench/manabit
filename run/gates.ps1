# Run every headless gate. Exit 1 if any is red. The loop's definition of "done".
$ErrorActionPreference = "Continue"
$godot = if ($env:GODOT) { $env:GODOT } else { "C:\Users\Stream Boi\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" }
$root = Split-Path $PSScriptRoot -Parent
$gates = Get-ChildItem "$root\tests\smoke_*.gd" | ForEach-Object { $_.BaseName } | Sort-Object
$red = @()
foreach ($g in $gates) {
  & $godot --headless --path $root --script "res://tests/$g.gd" | Out-Null
  if ($LASTEXITCODE -ne 0) { $red += $g; Write-Host "RED  $g" } else { Write-Host "green $g" }
}
if ($red.Count) { Write-Host "`nGATES RED: $($red -join ', ')"; exit 1 }
Write-Host "`nALL $($gates.Count) GATES GREEN"; exit 0
