# Script kiểm tra Database hiện tại
Write-Host "🔍 Checking current database state..." -ForegroundColor Cyan

# Start API (background)
$apiProcess = Start-Process -FilePath "dotnet" -ArgumentList "run" -PassThru -NoNewWindow -WorkingDirectory $PSScriptRoot

Start-Sleep -Seconds 8
Write-Host "API started, querying database..." -ForegroundColor Green

try {
    # Query task count by user
    $response = Invoke-RestMethod -Uri "https://localhost:7165/api/seed/stats" -Method Get -SkipCertificateCheck -ErrorAction SilentlyContinue
    
    if ($null -eq $response) {
        Write-Host "⚠️  No data in database. Run seeding first." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To seed NEW data (recommended):" -ForegroundColor Cyan
        Write-Host "  POST https://localhost:7165/api/seed/reseed" -ForegroundColor White
        Write-Host ""
        Write-Host "To seed 1000 tasks/user (for load testing):" -ForegroundColor Cyan
        Write-Host "  POST https://localhost:7165/api/seed/seed-ai-test-data" -ForegroundColor White
    } else {
        Write-Host "✅ Database contains data" -ForegroundColor Green
        $response | Format-List
    }
} catch {
    Write-Host "❌ Could not connect to API. Make sure it's running." -ForegroundColor Red
} finally {
    # Stop API
    Stop-Process -Id $apiProcess.Id -Force -ErrorAction SilentlyContinue
}
