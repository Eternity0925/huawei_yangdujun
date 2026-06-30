# Smart Greenhouse Backend

This is a small local HTTP bridge for the HarmonyOS app.

Flow:

```text
HarmonyOS app -> http://<your-pc-ip>:8080 -> KingbaseES
```

## 1. Add KingbaseES driver

Copy `kingbase8.jar` to:

```text
backend/lib/kingbase8.jar
```

## 2. Configure database

PowerShell:

```powershell
$env:KINGBASE_URL="jdbc:kingbase8://192.168.43.36:54321/smart_greenhouse"
$env:KINGBASE_USERNAME="system"
$env:KINGBASE_PASSWORD="123456"
```

## 3. Run

```powershell
cd E:\work\backend
.\run.ps1
```

## 4. Test

```powershell
Invoke-RestMethod http://localhost:8080/health
Invoke-RestMethod http://localhost:8080/db/health
```

The HarmonyOS app should use:

```text
http://192.168.43.65:8080
```

Replace `192.168.43.65` with your current computer IP if it changes.
