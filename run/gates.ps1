# Run every headless gate. Exit 1 if any is red. The loop's definition of "done".
# Portable across both PCs: never hardcode a profile path - the two machines have
# different usernames (Stream Boi / Mr. French) and different Godot locations.
$ErrorActionPreference = "Continue"
$root = Split-Path $PSScriptRoot -Parent

function Find-Godot {
  if ($env:GODOT -and (Test-Path $env:GODOT)) { return $env:GODOT }
  $onPath = (Get-Command godot -ErrorAction SilentlyContinue).Source
  if ($onPath) { return $onPath }
  $roots = @("$env:USERPROFILE\Downloads", "G:\Godot", "G:\Programs", "$env:LOCALAPPDATA\Programs", "C:\Program Files")
  foreach ($r in $roots) {
    if (-not (Test-Path $r)) { continue }
    $hit = Get-ChildItem $r -Recurse -Depth 2 -Filter "Godot_v4*.exe" -ErrorAction SilentlyContinue |
           Sort-Object Name -Descending | Select-Object -First 1
    if ($hit) { return $hit.FullName }
  }
  return $null
}

$godot = Find-Godot
if (-not $godot) {
  Write-Host "GODOT NOT FOUND. Set it for this shell, then re-run:"
  Write-Host '  $env:GODOT = "<full path to Godot_v4.x.exe>"'
  exit 1
}
Write-Host "godot: $godot`n"

$gates = Get-ChildItem "$root\tests\smoke_*.gd" | ForEach-Object { $_.BaseName } | Sort-Object
$red = @()
foreach ($g in $gates) {
  & $godot --headless --path $root --script "res://tests/$g.gd" | Out-Null
  if ($LASTEXITCODE -ne 0) { $red += $g; Write-Host "RED  $g" } else { Write-Host "green $g" }
}
if ($red.Count) { Write-Host "`nGATES RED: $($red -join ', ')"; exit 1 }
Write-Host "`nALL $($gates.Count) GATES GREEN"; exit 0
