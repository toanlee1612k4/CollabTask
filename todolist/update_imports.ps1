# Script to update all import paths in the new lib structure

$files = Get-ChildItem -Path "d:\btnv\CollabTask\todolist\lib_new" -Recurse -Filter "*.dart"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $updated = $false
    
    # Update imports
    $originalContent = $content
    
    # Models imports
    $content = $content -replace "import '\.\./models\.dart'", "import 'package:todolist/data/models/models.dart'"
    $content = $content -replace "import '\.\.\/models\.dart'", "import 'package:todolist/data/models/models.dart'"
    $content = $content -replace "import 'models\.dart'", "import 'package:todolist/data/models/models.dart'"
    $content = $content -replace "import '\.\.\/\.\.\/models\.dart'", "import 'package:todolist/data/models/models.dart'"
    $content = $content -replace "import '\.\.\/models\/", "import 'package:todolist/data/models/"
    
    # Services imports  
    $content = $content -replace "import '\.\./services/", "import 'package:todolist/data/services/"
    $content = $content -replace "import '\.\.\/services/", "import 'package:todolist/data/services/"
    $content = $content -replace "import 'services/", "import 'package:todolist/data/services/"
    $content = $content -replace "import '\.\.\/\.\.\/services/", "import 'package:todolist/data/services/"
    
    # Widgets imports
    $content = $content -replace "import '\.\./widgets/", "import 'package:todolist/presentation/widgets/common/"
    $content = $content -replace "import '\.\.\/widgets/", "import 'package:todolist/presentation/widgets/common/"
    $content = $content -replace "import 'widgets/", "import 'package:todolist/presentation/widgets/common/"
    $content = $content -replace "import '\.\.\/\.\.\/widgets/", "import 'package:todolist/presentation/widgets/common/"
    
    # Utils imports
    $content = $content -replace "import '\.\./utils/", "import 'package:todolist/core/utils/"
    $content = $content -replace "import '\.\.\/utils/", "import 'package:todolist/core/utils/"
    $content = $content -replace "import 'utils/", "import 'package:todolist/core/utils/"
    $content = $content -replace "import '\.\.\/\.\.\/utils/", "import 'package:todolist/core/utils/"
    
    # Core imports
    $content = $content -replace "import '\.\./core/", "import 'package:todolist/core/"
    $content = $content -replace "import '\.\.\/core/", "import 'package:todolist/core/"
    $content = $content -replace "import '\.\.\/\.\.\/core/", "import 'package:todolist/core/"
    
    # Screen imports - auth
    $content = $content -replace "import 'register_screen\.dart'", "import 'package:todolist/presentation/screens/auth/register_screen.dart'"
    $content = $content -replace "import 'login_screen\.dart'", "import 'package:todolist/presentation/screens/auth/login_screen.dart'"
    $content = $content -replace "import 'forgot_password_screen\.dart'", "import 'package:todolist/presentation/screens/auth/forgot_password_screen.dart'"
    $content = $content -replace "import 'authentications/screens/", "import 'package:todolist/presentation/screens/auth/"
    $content = $content -replace "import '\.\./authentications/screens/", "import 'package:todolist/presentation/screens/auth/"
    
    # Screen imports - dashboard
    $content = $content -replace "import 'dashboard_screen\.dart'", "import 'package:todolist/presentation/screens/dashboard/dashboard_screen.dart'"
    $content = $content -replace "import 'api_test_screen\.dart'", "import 'package:todolist/presentation/screens/dashboard/api_test_screen.dart'"
    $content = $content -replace "import 'screens/dashboard_screen\.dart'", "import 'package:todolist/presentation/screens/dashboard/dashboard_screen.dart'"
    $content = $content -replace "import 'screens/api_test_screen\.dart'", "import 'package:todolist/presentation/screens/dashboard/api_test_screen.dart'"
    
    # Screen imports - workspace
    $content = $content -replace "import 'workspaces_screen\.dart'", "import 'package:todolist/presentation/screens/workspace/workspaces_screen.dart'"
    $content = $content -replace "import 'workspace_detail_screen_v2\.dart'", "import 'package:todolist/presentation/screens/workspace/workspace_detail_screen_v2.dart'"
    $content = $content -replace "import 'screens/workspaces_screen\.dart'", "import 'package:todolist/presentation/screens/workspace/workspaces_screen.dart'"
    $content = $content -replace "import 'screens/workspace_detail_screen_v2\.dart'", "import 'package:todolist/presentation/screens/workspace/workspace_detail_screen_v2.dart'"
    
    # Screen imports - productivity
    $content = $content -replace "import 'productivity/personal_productivity_screen\.dart'", "import 'package:todolist/presentation/screens/productivity/personal_productivity_screen.dart'"
    $content = $content -replace "import 'productivity/workspace_productivity_screen\.dart'", "import 'package:todolist/presentation/screens/productivity/workspace_productivity_screen.dart'"
    $content = $content -replace "import 'screens/productivity/", "import 'package:todolist/presentation/screens/productivity/"
    
    # Screen imports - tasks
    $content = $content -replace "import 'screens/tasks/", "import 'package:todolist/presentation/screens/tasks/"
    $content = $content -replace "import '\.\./screens/tasks/", "import 'package:todolist/presentation/screens/tasks/"
    
    # Check if content changed
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "✅ Updated: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`n✅ All imports updated successfully!" -ForegroundColor Green
