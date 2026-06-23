$ErrorActionPreference = 'Stop'
$env:DART_SUPPRESS_ANALYTICS = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'

$root = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $root 'build\aot_benchmarks'
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
$dart = 'dart'
if ($flutter) {
  $flutterRoot = Split-Path -Parent (Split-Path -Parent $flutter.Source)
  $flutterDart = Join-Path $flutterRoot 'bin\cache\dart-sdk\bin\dart.exe'
  if (Test-Path -LiteralPath $flutterDart) {
    $dart = $flutterDart
  }
}

$benchmarks = @(
  'object_query_benchmark.dart',
  'representative_benchmark.dart',
  'structural_churn_benchmark.dart',
  'despawn_store_scaling_benchmark.dart',
  'query_entity_allocation_benchmark.dart',
  'rts_workload_benchmark.dart',
  'transform_sync_benchmark.dart'
)

Push-Location $PSScriptRoot
try {
  foreach ($benchmark in $benchmarks) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($benchmark)
    $exe = Join-Path $outputDir "$name.exe"
    Write-Host "Compiling $benchmark -> $exe"
    & $dart compile exe $benchmark -o $exe
  }
} finally {
  Pop-Location
}
