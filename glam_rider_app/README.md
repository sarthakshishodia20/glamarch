# GLAM Rider App — Flutter

GLAM rider-side mobile app built with Flutter. Connects to the GLAM Node.js backend.

## Setup Steps (Apne system mein karo)

### Step 1: Flutter Create (Platform files generate hogi)
```bash
cd glam-backend
flutter create --org com.glam --project-name glam_rider_app glam_rider_app
```
> Note: Ye command existing files ko overwrite nahi karega — bas android/, ios/ etc. folders add karega.

### Step 2: Dependencies install karo
```bash
cd glam_rider_app
flutter pub get
```

### Step 3: Run on device ya browser
```bash
# Android Emulator ya USB device
flutter run

# Chrome browser (quick preview)
flutter run -d chrome
```

## Backend Connection
- **Production:** `https://glam-backend-a2pc.onrender.com/api`
- **Android Emulator:** `http://10.0.2.2:5000/api`
- **Real Device (same WiFi):** `http://YOUR_LAPTOP_IP:5000/api`
  - Laptop IP dekhne ke liye: `ip addr show` (Linux) / `ipconfig` (Windows)

## Screens (Phase 1)
| # | Screen | File |
|---|--------|------|
| 1 | Language Selection | `lib/screens/language_selection_screen.dart` |
| 2 | Registration + Profile | *Coming next* |
| 3 | Client Selection | *Coming next* |
| 4 | Document Upload | *Coming next* |
| 5 | BGV Tracker | *Coming next* |
