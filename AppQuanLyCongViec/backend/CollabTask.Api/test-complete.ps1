# Complete Test Script for CollabTask API
Write-Host "=== CollabTask API Complete Test ===" -ForegroundColor Cyan

# Test 1: Login
Write-Host "`n1. Testing Login..." -ForegroundColor Yellow
$loginBody = @{
    email = "alice@example.com"
    password = "Password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:5131/api/auth/login" `
        -Method POST `
        -Body $loginBody `
        -ContentType "application/json"
    
    $token = $loginResponse.token
    Write-Host "   ✅ Login successful!" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    Authorization = "Bearer $token"
}

# Test 2: Get Workspaces
Write-Host "`n2. Testing Get Workspaces..." -ForegroundColor Yellow
try {
    $workspaces = Invoke-RestMethod -Uri "http://localhost:5131/api/workspaces" `
        -Method GET `
        -Headers $headers
    
    # WorkspacesController returns array directly, not wrapped in {data: [...]}
    $workspaceCount = if ($workspaces -is [array]) { $workspaces.Count } else { 1 }
    Write-Host "   ✅ Found $workspaceCount workspaces" -ForegroundColor Green
    $workspaceId = if ($workspaces -is [array]) { $workspaces[0].workspaceID } else { $workspaces.workspaceID }
} catch {
    Write-Host "   ❌ Get workspaces failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Get Workspace Tasks
Write-Host "`n3. Testing Get Workspace Tasks..." -ForegroundColor Yellow
try {
    $wsTasks = Invoke-RestMethod -Uri "http://localhost:5131/api/workspaces/$workspaceId/tasks?page=1&pageSize=10" `
        -Method GET `
        -Headers $headers
    
    Write-Host "   ✅ Workspace has $($wsTasks.totalCount) total tasks" -ForegroundColor Green
    Write-Host "   First 3 tasks:" -ForegroundColor Gray
    $wsTasks.data | Select-Object -First 3 | ForEach-Object {
        $title = $_.title.Substring(0, [Math]::Min(50, $_.title.Length))
        Write-Host "      - [$($_.priority)] $title..." -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ Get workspace tasks failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Get My Tasks
Write-Host "`n4. Testing Get My Tasks..." -ForegroundColor Yellow
try {
    $myTasks = Invoke-RestMethod -Uri "http://localhost:5131/api/tasks?page=1&pageSize=10" `
        -Method GET `
        -Headers $headers
    
    Write-Host "   ✅ Alice has $($myTasks.totalCount) tasks assigned" -ForegroundColor Green
    Write-Host "   First 3 assigned tasks:" -ForegroundColor Gray
    $myTasks.data | Select-Object -First 3 | ForEach-Object {
        $title = $_.title.Substring(0, [Math]::Min(50, $_.title.Length))
        Write-Host "      - [$($_.priority)] $title..." -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ Get my tasks failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Get AI Suggestions
Write-Host "`n5. Testing AI Task Suggestions..." -ForegroundColor Yellow
try {
    $suggestions = Invoke-RestMethod -Uri "http://localhost:5131/api/suggested" `
        -Method GET `
        -Headers $headers
    
    Write-Host "   ✅ AI suggested $($suggestions.Count) tasks" -ForegroundColor Green
    Write-Host "   Top 5 AI suggestions:" -ForegroundColor Gray
    $suggestions | Select-Object -First 5 | ForEach-Object {
        $title = $_.title.Substring(0, [Math]::Min(45, $_.title.Length))
        $deadline = if ($_.deadline) { (Get-Date $_.deadline -Format "MM/dd") } else { "No deadline" }
        Write-Host "      - [$($_.priority)] $title... (Due: $deadline)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ AI suggestions failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== All Tests Completed! ===" -ForegroundColor Cyan
