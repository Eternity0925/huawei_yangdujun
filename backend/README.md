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
$env:KINGBASE_URL="jdbc:kingbase8://101.42.99.139:54321/smart_greenhouse"
$env:KINGBASE_USERNAME="system"
$env:KINGBASE_PASSWORD="123456"
```

## 3. Configure Huawei Cloud

The HarmonyOS app calls this backend proxy. IoT data and commands use the `why`
Huawei Cloud account by default.

Optional overrides:

```powershell
$env:HUAWEI_IOT_USERNAME="why"
$env:HUAWEI_IOT_PASSWORD="why123456"
$env:HUAWEI_IOT_DOMAIN="why66665"
$env:HUAWEI_IOT_PROJECT_NAME="cn-north-4"
$env:HUAWEI_IOT_PROJECT_ID="0e7c5e04a662439c813433f94d7ad4e7"
$env:HUAWEI_IOT_DEVICE_ID="6a3a6da1cbb0cf6bb96829a4_WHYwhy"
$env:HUAWEI_IOT_SERVICE_ID="王昊洋"
```

## 4. Run

```powershell
cd E:\work\backend
.\run.ps1
```

## 5. Test

```powershell
Invoke-RestMethod http://localhost:8080/health
Invoke-RestMethod http://localhost:8080/db/health
```

The HarmonyOS app should use:

```text
http://192.168.43.65:8080
```

Replace `192.168.43.65` with your current computer IP if it changes.
