# Bumps the version in pubspec.yaml and, for releases, rolls CHANGELOG.md.
#
#   -Part patch|minor|major  -> bump SemVer, increment build, move [Unreleased] into a new release section
#   -Part build              -> only increment the build number (e.g. a re-built APK)
#
# Usage (from repo root):  powershell -ExecutionPolicy Bypass -File tool\bump_version.ps1 -Part patch

param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('major', 'minor', 'patch', 'build')]
  [string]$Part
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pubspec = Join-Path $root 'pubspec.yaml'
$changelog = Join-Path $root 'CHANGELOG.md'
$utf8 = New-Object System.Text.UTF8Encoding($false)

$text = [IO.File]::ReadAllText($pubspec)
$m = [regex]::Match($text, '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$')
if (-not $m.Success) { throw 'No "version: X.Y.Z+N" line found in pubspec.yaml' }

$major = [int]$m.Groups[1].Value
$minor = [int]$m.Groups[2].Value
$patch = [int]$m.Groups[3].Value
$build = [int]$m.Groups[4].Value + 1

switch ($Part) {
  'major' { $major++; $minor = 0; $patch = 0 }
  'minor' { $minor++; $patch = 0 }
  'patch' { $patch++ }
}

$semver = "$major.$minor.$patch"
$text = $text.Remove($m.Index, $m.Length).Insert($m.Index, "version: $semver+$build")
[IO.File]::WriteAllText($pubspec, $text, $utf8)
Write-Host "pubspec.yaml -> $semver+$build"

if ($Part -ne 'build') {
  $log = [IO.File]::ReadAllText($changelog)
  if ($log -notmatch '(?m)^## \[Unreleased\]') { throw 'No "## [Unreleased]" section in CHANGELOG.md' }
  $date = Get-Date -Format 'yyyy-MM-dd'
  $log = [regex]::Replace($log, '(?m)^## \[Unreleased\]', "## [Unreleased]`n`n## [$semver] - $date", 1)
  $log = [regex]::Replace($log, '(?m)^\[Unreleased\]: .*$', "[Unreleased]: #`n[$semver]: #", 1)
  [IO.File]::WriteAllText($changelog, $log, $utf8)
  Write-Host "CHANGELOG.md -> [$semver] - $date"
}
