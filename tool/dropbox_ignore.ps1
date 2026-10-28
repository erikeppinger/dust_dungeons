# Marks generated Flutter/Gradle folders as "ignored" for Dropbox so they are not synced.
# Creates missing folders first, because the ignore flag is stored on the folder itself.
# Re-run after `flutter clean` or after deleting any of these folders.
#
# Usage (from repo root):  powershell -ExecutionPolicy Bypass -File tool\dropbox_ignore.ps1

$root = Split-Path -Parent $PSScriptRoot
$folders = @(
  "build",
  ".dart_tool",
  ".idea",
  "android\.gradle",
  "android\.kotlin",
  "android\app\.cxx"
)

foreach ($f in $folders) {
  $path = Join-Path $root $f
  if (-not (Test-Path $path)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
  }
  Set-Content -Path $path -Stream com.dropbox.ignored -Value 1
  Write-Host "Dropbox ignored: $f"
}
