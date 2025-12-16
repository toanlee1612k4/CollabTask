# Test workspace tasks after fix
Write-Host "`n🚀 Starting server..." -ForegroundColor Cyan
$job = Start-Job -ScriptBlock { 
    Set-Location 'd:\btnv\CollabTask\AppQuanLyCongViec\backend\CollabTask.Api'
    dotnet run 
}

Start-Sleep -Seconds 8

try {
    Write-Host "`n🔑 Logging in..." -ForegroundColor Cyan
    $loginResponse = Invoke-WebRequest -Uri "http://localhost:5131/api/auth/login" `
        -Method POST `
        -Body '{"email":"alice@example.com","password":"Password123"}' `
        -ContentType "application/json" `
        -UseBasicParsing
    
    $token = ($loginResponse.Content | ConvertFrom-Json).token
    $headers = @{Authorization="Bearer $token"}
    Write-Host "✅ Login successful!" -ForegroundColor Green
    
    Write-Host "`n📊 Testing workspace tasks endpoint..." -ForegroundColor Cyan
    $response = Invoke-WebRequest -Uri "http://localhost:5131/api/workspaces/f4904d09-93e7-4028-bdd2-e305132d0057/tasks" `
        -Headers $headers `
        -UseBasicParsing
    
    $data = $response.Content | ConvertFrom-Json
    
    Write-Host "`n✅ Response structure:" -ForegroundColor Green
    Write-Host "   totalCount: $($data.totalCount)" -ForegroundColor Yellow
    Write-Host "   currentPage: $($data.currentPage)" -ForegroundColor Yellow
    Write-Host "   pageSize: $($data.pageSize)" -ForegroundColor Yellow
    Write-Host "   totalPages: $($data.totalPages)" -ForegroundColor Yellow
    Write-Host "   items count: $($data.items.Count)" -ForegroundColor Green
    
    if ($data.items.Count -gt 0) {
        Write-Host "`n📝 First task:" -ForegroundColor Cyan
        $data.items[0] | Format-List taskId, title, status, priority, deadline
    } else {
        Write-Host "`n⚠️ No tasks in items array!" -ForegroundColor Red
    }
    
    Write-Host "`n📊 Testing My Tasks endpoint..." -ForegroundColor Cyan
    $myTasksResponse = Invoke-WebRequest -Uri "http://localhost:5131/api/tasks?pageSize=10" `
        -Headers $headers `
        -UseBasicParsing
    
    $myTasks = $myTasksResponse.Content | ConvertFrom-Json
    Write-Host "   My tasks count: $($myTasks.items.Count) / $($myTasks.totalCount)" -ForegroundColor Green
    
} finally {
    Write-Host "`n🛑 Stopping server..." -ForegroundColor Yellow
    Stop-Job $job
    Remove-Job $job
}
