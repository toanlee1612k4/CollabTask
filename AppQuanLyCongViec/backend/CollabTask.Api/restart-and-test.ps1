# Restart and Test Script
Write-Host "=== Restarting Server and Testing ===" -ForegroundColor Cyan

# Stop existing servers
Write-Host "`n1. Stopping existing servers..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -like "*CollabTask.Api*" -or ($_.ProcessName -eq "dotnet" -and $_.Path -like "*CollabTask*")} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Build project
Write-Host "`n2. Building project..." -ForegroundColor Yellow
$buildResult = dotnet build --no-incremental 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ Build successful!" -ForegroundColor Green

# Start server in background
Write-Host "`n3. Starting server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD'; dotnet run" -WindowStyle Minimized
Start-Sleep -Seconds 10
Write-Host "   ✅ Server started!" -ForegroundColor Green

# Clear and reseed database
Write-Host "`n4. Clearing and reseeding database..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:5131/api/seed/clear" -Method POST | Out-Null
    Start-Sleep -Seconds 2
    $seedResult = Invoke-RestMethod -Uri "http://localhost:5131/api/seed/seed" -Method POST
    Write-Host "   ✅ $($seedResult.message)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Seed failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Run tests
Write-Host "`n5. Running tests..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
.\test-complete.ps1

Write-Host "`n=== Done! Server is running in minimized window ===" -ForegroundColor Cyan
Write-Host "To stop server: Get-Process | Where-Object ProcessName -eq 'dotnet' | Stop-Process -Force" -ForegroundColor Gray
