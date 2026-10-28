# Keeps generated Flutter/Gradle folders out of Dropbox.
#
# Every file under the Dropbox folder is a Dropbox cloud-files placeholder (a
# reparse point), even in "ignored" folders. Gradle sometimes cannot read such
# files ("Cannot snapshot ...: not a regular file") and the build fails. So the
# generated folders are moved to %LOCALAPPDATA% and replaced by directory
# junctions, which Dropbox is told to ignore. Paths inside the project stay the
# same for Flutter, Gradle and the IDE.
#
# Safe to re-run. Run again after `flutter clean` (it deletes the `build`
# junction) and on every new machine. Afterwards run `flutter pub get`.
#
# Usage (from repo root):  powershell -ExecutionPolicy Bypass -File tool\dropbox_ignore.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$outside = Join-Path $env:LOCALAPPDATA 'HomeworkAndChores\generated'

# Generated folders: moved outside Dropbox via junction.
$junctioned = @('build', '.dart_tool', 'android\.gradle', 'android\.kotlin', 'android\app\.cxx')
# IDE settings: only ignored.
$ignoredOnly = @('.idea')

foreach ($f in $junctioned) {
  $path = Join-Path $root $f
  $target = Join-Path $outside ($f -replace '[\\/]', '_')
  New-Item -ItemType Directory -Force -Path $target | Out-Null

  $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  if ($item -and $item.LinkType -eq 'Junction') {
    if ($item.Target -contains $target) {
      Write-Host "ok       $f -> $target"
    } else {
      Write-Warning "$f is a junction to $($item.Target), expected $target; left unchanged"
    }
  } else {
    if ($item) {
      # Generated content only: it is rebuilt by flutter pub get / build.
      # Dropbox briefly locks folders it is processing, so retry a few times.
      for ($try = 1; (Test-Path -LiteralPath $path) -and $try -le 10; $try++) {
        cmd /c "rmdir /s /q `"$path`"" 2>$null
        if (Test-Path -LiteralPath $path) { Start-Sleep -Seconds 2 }
      }
      if (Test-Path -LiteralPath $path) {
        throw "Could not delete $f (in use). Close IDEs/emulator builds and run again."
      }
    }
    New-Item -ItemType Junction -Path $path -Target $target | Out-Null
    Write-Host "linked   $f -> $target"
  }
  Set-Content -LiteralPath $path -Stream com.dropbox.ignored -Value 1
}

foreach ($f in $ignoredOnly) {
  $path = Join-Path $root $f
  New-Item -ItemType Directory -Force -Path $path | Out-Null
  Set-Content -LiteralPath $path -Stream com.dropbox.ignored -Value 1
  Write-Host "ignored  $f"
}
