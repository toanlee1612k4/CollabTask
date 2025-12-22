# CollabTask - Setup Guide for New Developers

Hướng dẫn thiết lập môi trường phát triển local cho dự án CollabTask.

**Last Updated**: December 19, 2025

---

## 📋 Mục Lục

1. [Prerequisites - Cài Đặt Trước](#prerequisites---cài-đặt-trước)
2. [Clone Project từ GitHub](#clone-project-từ-github)
3. [Backend Setup (.NET API)](#backend-setup-net-api)
4. [Flutter Frontend Setup](#flutter-frontend-setup)
5. [Testing & Verification](#testing--verification)
6. [Troubleshooting](#troubleshooting)

---

## 🛠 Prerequisites - Cài Đặt Trước

### 1. .NET SDK 9.0

**Version Required**: `.NET 9.0` (latest stable)

**Kiểm tra version hiện tại**:
```powershell
dotnet --version
# Nên hiển thị: 9.0.xxx
```

**Cài đặt**:
- Download từ: https://dotnet.microsoft.com/download/dotnet/9.0
- Chọn: **.NET SDK 9.0** (không phải Runtime)
- Cài đặt và restart terminal

**Verify**:
```powershell
dotnet --info
# Kiểm tra .NET SDK version 9.0.xxx có trong list
```

---

### 2. SQL Server LocalDB

**LocalDB** là phiên bản nhẹ của SQL Server, dùng cho development.

**Kiểm tra đã cài chưa**:
```powershell
sqllocaldb info
# Nếu thấy list instances (vd: mssqllocaldb) → đã cài
# Nếu báo lỗi "command not found" → chưa cài
```

**Cài đặt**:

**Option 1: Cài qua Visual Studio Installer** (Recommended)
- Mở **Visual Studio Installer**
- Click **Modify** trên Visual Studio 2022
- Chọn tab **Individual components**
- Tìm và check: **SQL Server Express LocalDB**
- Click **Modify** để cài

**Option 2: Standalone Installer**
- Download **SQL Server Express**: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
- Chọn **Express** edition → Download
- Khi cài, chọn **Basic** installation
- LocalDB sẽ được cài kèm

**Verify sau khi cài**:
```powershell
# Start LocalDB
sqllocaldb start mssqllocaldb

# Kiểm tra status
sqllocaldb info mssqllocaldb
# Nên thấy: State: Running
```

---

### 3. Flutter SDK

**Version Required**: `Flutter 3.x` (stable channel)

**Kiểm tra version**:
```powershell
flutter --version
# Nên thấy: Flutter 3.x.x • channel stable
```

**Cài đặt** (nếu chưa có):
1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Giải nén vào thư mục (ví dụ: `C:\src\flutter`)
3. Thêm vào PATH:
   - System Properties → Environment Variables
   - Thêm `C:\src\flutter\bin` vào **Path**
4. Restart terminal

**Verify**:
```powershell
flutter doctor
# Kiểm tra tất cả checkmarks (✓)
```

**Cài thêm dependencies cho Flutter**:
```powershell
# Android Studio (nếu develop cho Android)
# Download: https://developer.android.com/studio

# Chrome (nếu develop cho Web)
# Flutter web đã support sẵn Chrome
```

---

### 4. IDE/Editor

**Backend (.NET)**:
- **Visual Studio 2022** (Community/Professional)
- Hoặc **Visual Studio Code** + C# extension

**Frontend (Flutter)**:
- **Visual Studio Code** + Flutter/Dart extensions
- Hoặc **Android Studio** + Flutter plugin

**Recommended Extensions cho VS Code**:
```
# Backend
- C# (Microsoft)
- C# Dev Kit
- NuGet Package Manager

# Frontend
- Flutter
- Dart
- Flutter Widget Snippets
```

---

### 5. Git

```powershell
git --version
# Nếu chưa cài, download: https://git-scm.com/downloads
```

---

## 📥 Clone Project từ GitHub

```powershell
# Clone repository
git clone https://github.com/your-username/CollabTask.git

# Navigate to project
cd CollabTask

# Kiểm tra cấu trúc
dir
# Nên thấy: backend/, frontend/, README.md
```

---

## 🔧 Backend Setup (.NET API)

### Bước 1: Navigate to Backend

```powershell
cd backend\CollabTask.Api
```

### Bước 2: Environment Configuration

**Backend KHÔNG cần file `.env`** - tất cả config nằm trong `appsettings.json`

**File config chính**:
- `appsettings.json` - Production settings (generic)
- `appsettings.Development.json` - Development settings (local)

**Kiểm tra appsettings.Development.json**:
```powershell
notepad appsettings.Development.json
```

**Nội dung mẫu**:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=CollabTaskDb;Trusted_Connection=true;MultipleActiveResultSets=true;TrustServerCertificate=true"
  },
  "AppSettings": {
    "Token": "my super secret key for jwt authentication and authorization in collabtask api project 2024"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

**✅ Không cần sửa gì** - config mặc định đã hoạt động cho local development.

**Nếu muốn đổi database**:
- Sửa `ConnectionStrings:DefaultConnection`
- Ví dụ SQL Server instance khác: `Server=localhost;Database=CollabTaskDb;...`

### Bước 3: Restore Dependencies

```powershell
# Restore NuGet packages
dotnet restore

# Hoặc build luôn (sẽ restore tự động)
dotnet build
```

**Packages sẽ được cài**:
- `Microsoft.EntityFrameworkCore.SqlServer` - ORM cho SQL Server
- `Microsoft.AspNetCore.Authentication.JwtBearer` - JWT auth
- `BCrypt.Net-Next` - Password hashing
- `Swashbuckle.AspNetCore` - Swagger documentation

### Bước 4: Database Migration

**TRẢ LỜI CÂU HỎI: "Có cần chạy migration không?"**

✅ **KHÔNG CẦN** chạy migration thủ công!

**Backend đã tự động xử lý khi start:**

```csharp
// Program.cs đã có code này:
await context.Database.MigrateAsync();
// → Tự động apply migrations khi run lần đầu
```

**Khi bạn chạy `dotnet run` lần đầu**:
1. Backend check xem database `CollabTaskDb` đã tồn tại chưa
2. Nếu chưa → **Tự động tạo database**
3. **Tự động apply tất cả migrations** (5 migration files)
4. Database ready để dùng!

**Logs bạn sẽ thấy**:
```
✅ Database connection successful
Applying 5 pending migrations...
✅ Migrations applied successfully
```

**Nếu muốn chạy migration thủ công** (optional):
```powershell
# Apply migrations manually
dotnet ef database update

# Xem danh sách migrations
dotnet ef migrations list

# Rollback migration
dotnet ef database update PreviousMigrationName

# Create new migration (khi bạn sửa Models)
dotnet ef migrations add YourMigrationName
```

### Bước 5: Run Backend

```powershell
# Chạy backend
dotnet run

# Hoặc dùng watch mode (auto-reload khi code thay đổi)
dotnet watch run
```

**Server sẽ start tại**:
- API: http://localhost:5131
- Swagger UI: http://localhost:5131/swagger

**Kiểm tra backend đang chạy**:
```powershell
# Test API health
curl http://localhost:5131/api/auth/login
# Hoặc mở Swagger: http://localhost:5131/swagger
```

### Bước 6: Seed Database (Optional)

Backend có sẵn **6,000 tasks demo data** để test.

**Cách seed data**:

1. Mở Swagger: http://localhost:5131/swagger
2. Click **POST /api/seed/seed-all**
3. Click "Try it out" → "Execute"

**Hoặc dùng PowerShell**:
```powershell
curl http://localhost:5131/api/seed/seed-all -Method POST
```

**Data được tạo**:
- 6 users (alice@, bob@, charlie@, diana@, eve@, frank@example.com)
- 6 workspaces
- 6,000 tasks (1,000 tasks/user)
- 6 tháng historical data (June-Dec 2025)

**Demo accounts** (password: `Password123`):
```
alice@example.com
bob@example.com
charlie@example.com
diana@example.com
eve@example.com
frank@example.com
```

---

## 📱 Flutter Frontend Setup

**Note**: Phần này cần có project Flutter trong repo. Nếu repo chỉ có backend, bỏ qua phần này.

### Bước 1: Navigate to Frontend

```powershell
cd ..\..  # Về root project
cd frontend  # Hoặc tên folder Flutter app
```

### Bước 2: Configuration

**TRẢ LỜI CÂU HỎI: "Flutter có cần config gì đặc biệt?"**

✅ **Chỉ cần config API URL**

**File cần sửa**: `lib/constants/api_constants.dart` (hoặc tương tự)

```dart
class ApiConstants {
  // Development
  static const String baseUrl = 'http://localhost:5131/api';
  
  // Production
  // static const String baseUrl = 'https://api.collabtask.com/api';
}
```

**Các platform khác nhau**:
```dart
// Android Emulator
static const String baseUrl = 'http://10.0.2.2:5131/api';

// iOS Simulator
static const String baseUrl = 'http://localhost:5131/api';

// Real device (same WiFi)
static const String baseUrl = 'http://192.168.1.x:5131/api';
// (Thay 192.168.1.x bằng IP máy của bạn)
```

**Kiểm tra IP máy** (để real device connect):
```powershell
ipconfig
# Tìm IPv4 Address của WiFi adapter
```

### Bước 3: Install Dependencies

```powershell
# Get Flutter packages
flutter pub get
```

**Packages trong pubspec.yaml** (ví dụ):
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0  # API calls
  provider: ^6.1.0  # State management
  shared_preferences: ^2.2.0  # Token storage
  # ... other packages
```

### Bước 4: Run Flutter App

```powershell
# List available devices
flutter devices

# Run on Chrome (web)
flutter run -d chrome

# Run on Android emulator
flutter run -d emulator-5554

# Run on connected phone
flutter run -d <device-id>
```

**Hot reload**: Nhấn `r` trong terminal sau khi sửa code

**Hot restart**: Nhấn `R` để restart app

---

## ✅ Testing & Verification

### 1. Test Backend API

**Option 1: Swagger UI**
```
http://localhost:5131/swagger
```

**Test login**:
1. Click **POST /api/auth/login**
2. Try it out
3. Request body:
```json
{
  "email": "alice@example.com",
  "password": "Password123"
}
```
4. Execute → Nên nhận được token

**Option 2: PowerShell**
```powershell
# Test login
$body = @{
    email = "alice@example.com"
    password = "Password123"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:5131/api/auth/login" `
    -Method POST -Body $body -ContentType "application/json"

$response.token
# Nên hiển thị JWT token
```

**Option 3: Test Script**
```powershell
# Chạy test script có sẵn
.\restart-and-test.ps1
```

### 2. Test Database Connection

```powershell
# Connect to LocalDB
sqlcmd -S "(localdb)\mssqllocaldb" -d CollabTaskDb

# Query trong SQL
SELECT COUNT(*) as UserCount FROM Users;
SELECT COUNT(*) as TaskCount FROM Tasks;
GO

# Exit
exit
```

**Hoặc dùng SQL Server Management Studio**:
- Server name: `(localdb)\mssqllocaldb`
- Authentication: Windows Authentication
- Database: `CollabTaskDb`

### 3. Test Flutter App

```powershell
# Verify Flutter app can call API
# Trong app, thử login với alice@example.com / Password123
# Nên thấy danh sách tasks load được
```

---

## 🔍 Troubleshooting

### ❌ Backend: "Cannot connect to LocalDB"

**Solution 1: Start LocalDB**
```powershell
sqllocaldb start mssqllocaldb
sqllocaldb info mssqllocaldb  # Check Running state
```

**Solution 2: Create instance nếu chưa có**
```powershell
sqllocaldb create mssqllocaldb
sqllocaldb start mssqllocaldb
```

**Solution 3: Recreate database**
```powershell
# Delete database
dotnet ef database drop --force

# Run app lại (auto tạo database mới)
dotnet run
```

---

### ❌ Backend: "Build failed - file locked by process"

**Solution**:
```powershell
# Tìm process đang chạy
Get-Process | Where-Object {$_.ProcessName -like "*CollabTask*"}

# Stop process
Stop-Process -Name "CollabTask.Api" -Force

# Build lại
dotnet build
```

---

### ❌ Backend: "JWT token invalid / 401 Unauthorized"

**Nguyên nhân**: Token hết hạn (7 ngày) hoặc sai JWT secret key

**Solution**:
```powershell
# 1. Login lại để get token mới
# 2. Kiểm tra appsettings.Development.json → AppSettings:Token
# 3. Đảm bảo frontend dùng đúng token từ login response
```

---

### ❌ Flutter: "Connection refused / Failed to connect"

**Nguyên nhân**: Backend chưa chạy hoặc sai API URL

**Solution**:
```powershell
# 1. Kiểm tra backend đang chạy
curl http://localhost:5131/api/auth/login

# 2. Kiểm tra API URL trong Flutter
# Android emulator: http://10.0.2.2:5131/api
# iOS simulator: http://localhost:5131/api
# Real device: http://<your-ip>:5131/api
```

**Cho phép external connections**:
```powershell
# Chạy backend với external host
dotnet run --urls "http://0.0.0.0:5131"
```

**Firewall**:
```powershell
# Windows Firewall cho phép port 5131
New-NetFirewallRule -DisplayName "CollabTask API" -Direction Inbound -LocalPort 5131 -Protocol TCP -Action Allow
```

---

### ❌ Flutter: "pub get failed"

**Solution**:
```powershell
# Clear cache
flutter clean
flutter pub get

# Nếu vẫn lỗi, upgrade Flutter
flutter upgrade
```

---

### ❌ Migration: "Cannot apply migration - database in use"

**Solution**:
```powershell
# Stop backend
# Close SQL Server Management Studio / Azure Data Studio
# Clear connections
dotnet ef database drop --force
dotnet run  # Auto recreate
```

---

## 📚 Helpful Commands Summary

### Backend Commands
```powershell
# Build
dotnet build

# Run
dotnet run

# Run with watch (auto-reload)
dotnet watch run

# Migration commands
dotnet ef migrations add MigrationName
dotnet ef migrations list
dotnet ef database update
dotnet ef database drop

# Test
.\restart-and-test.ps1
.\test-complete.ps1
```

### Flutter Commands
```powershell
# Get packages
flutter pub get

# Run
flutter run

# Build
flutter build apk  # Android
flutter build web  # Web

# Clean
flutter clean

# Analyze code
flutter analyze
```

### Database Commands
```powershell
# LocalDB management
sqllocaldb info
sqllocaldb start mssqllocaldb
sqllocaldb stop mssqllocaldb

# SQL Query
sqlcmd -S "(localdb)\mssqllocaldb" -d CollabTaskDb -Q "SELECT * FROM Users"
```

---

## 🎯 Quick Start Checklist

Sau khi cài đặt xong prerequisites, làm theo checklist này:

- [ ] Clone repo từ GitHub
- [ ] `cd backend/CollabTask.Api`
- [ ] Kiểm tra `appsettings.Development.json` (không cần sửa)
- [ ] `dotnet restore`
- [ ] `dotnet run` (database tự động tạo + migrate)
- [ ] Mở http://localhost:5131/swagger
- [ ] Seed data: `POST /api/seed/seed-all`
- [ ] Test login với `alice@example.com` / `Password123`
- [ ] ✅ Backend done!
- [ ] `cd ../frontend` (nếu có)
- [ ] Sửa API URL trong constants
- [ ] `flutter pub get`
- [ ] `flutter run`
- [ ] Test login trong app
- [ ] ✅ Frontend done!

---

## 🔗 Additional Resources

- **Backend Guide**: [BACKEND-COMPLETE-GUIDE.md](BACKEND-COMPLETE-GUIDE.md)
- **API Documentation**: Swagger UI tại http://localhost:5131/swagger
- **Frontend Guide**: [FRONTEND-API-GUIDE.md](FRONTEND-API-GUIDE.md) (nếu có)
- **.NET Documentation**: https://learn.microsoft.com/en-us/dotnet/
- **Flutter Documentation**: https://docs.flutter.dev/

---

## 💡 Development Tips

### 1. Recommended Workflow

```
Terminal 1: Backend
cd backend/CollabTask.Api
dotnet watch run

Terminal 2: Flutter
cd frontend
flutter run

Terminal 3: Git/Commands
git status
# ... other commands
```

### 2. Backend Hot Reload

Dùng `dotnet watch run` thay vì `dotnet run` để tự động reload khi sửa code.

### 3. Database Seeding

Chỉ seed 1 lần đầu. Nếu muốn reset data:
```powershell
dotnet ef database drop --force
dotnet run  # Auto recreate
# Seed lại qua Swagger
```

### 4. Debug Mode

**Backend**: F5 trong Visual Studio hoặc VS Code (với launch.json)

**Flutter**: F5 trong VS Code hoặc `flutter run --debug`

### 5. API Testing Tools

- **Swagger UI**: Built-in, best cho testing nhanh
- **Postman**: Good cho save collections
- **curl/PowerShell**: Good cho automation

---

## ❓ FAQ

### Q: Tôi có cần cài SQL Server đầy đủ không?

**A**: Không! **LocalDB** (nhẹ hơn) là đủ cho development. LocalDB đi kèm Visual Studio hoặc cài riêng.

---

### Q: File .env để ở đâu?

**A**: Backend **KHÔNG dùng .env**. Tất cả config trong `appsettings.json` và `appsettings.Development.json`.

---

### Q: Database tự tạo hay phải chạy migration?

**A**: **TỰ ĐỘNG TẠO**! Chỉ cần `dotnet run`, backend sẽ:
1. Tạo database nếu chưa có
2. Apply tất cả migrations
3. Ready để dùng

---

### Q: Port 5131 bị conflict, đổi được không?

**A**: Được! Sửa `Properties/launchSettings.json`:
```json
"applicationUrl": "http://localhost:YOUR_PORT"
```

Hoặc chạy với custom port:
```powershell
dotnet run --urls "http://localhost:YOUR_PORT"
```

---

### Q: Flutter SDK version cụ thể là gì?

**A**: Project dùng **Flutter 3.x stable channel**. Kiểm tra bằng `flutter --version`. Nếu cần upgrade:
```powershell
flutter upgrade
flutter doctor
```

---

### Q: Backend có cần cài thêm SQL Server tools?

**A**: Không bắt buộc. Nhưng nếu muốn query database:
- **SQL Server Management Studio (SSMS)** - GUI tool
- **Azure Data Studio** - Cross-platform
- **sqlcmd** - Command line (đi kèm LocalDB)

---

### Q: Tôi dùng Mac/Linux được không?

**A**: 
- **Backend**: ✅ Được (dùng PostgreSQL/MySQL thay LocalDB, sửa connection string)
- **Flutter**: ✅ Được (cross-platform)
- **LocalDB**: ❌ Chỉ Windows (dùng Docker SQL Server hoặc PostgreSQL)

---

## 📞 Support

Nếu gặp lỗi không có trong guide:

1. Kiểm tra logs trong console
2. Kiểm tra [TROUBLESHOOTING](#troubleshooting) section
3. Check GitHub Issues
4. Ask team lead

---

**Happy Coding! 🚀**

**Last Updated**: December 19, 2025
