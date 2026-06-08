# Firebase Setup & Firestore Structure

The app runs fully **offline by default**. Follow this only to enable cloud
sync, real authentication and document storage.

## 1. Create the project
1. Go to the [Firebase Console](https://console.firebase.google.com/) → **Add project** → name it `carcare-pro`.
2. Enable **Authentication** → Sign‑in methods: **Email/Password**, **Google**, and (for iOS) **Apple**.
3. Create a **Cloud Firestore** database (start in *production* mode, rules below).
4. Enable **Storage**.

## 2. Wire it into the app
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=carcare-pro
```
This regenerates `lib/firebase_options.dart` and adds the platform files
(`google-services.json`, `GoogleService-Info.plist`). Then run with the flag:
```bash
flutter run --dart-define=ENABLE_FIREBASE=true
```
> Tip: to make it the default, set `enableFirebase` to `true` in
> `lib/core/app_config.dart`.

### Google Sign‑In
- **Android:** add your debug & release SHA‑1/SHA‑256 to the Firebase Android app, then re‑download `google-services.json`.
- **iOS:** add the reversed client id URL scheme to `Info.plist` (FlutterFire prints it).

### Apple Sign‑In
- Enable **Sign in with Apple** capability in Xcode and in your Apple Developer account.
- Enable the **Apple** provider in Firebase Auth.

## 3. Firestore structure

```
users/{uid}                         ← profile mirror (AppUser.toJson)
   ├── name, email, photoUrl, emailVerified, createdAt
   │
   ├── vehicles/{vehicleId}         ← Vehicle.toJson
   │      brand, model, year, trim, engine, fuelType, transmission,
   │      plateNumber, vin, currentMileage, imageUrl, colorHex,
   │      insuranceExpiry, licenseExpiry, inspectionDate, isPrimary, createdAt
   │
   ├── maintenance/{recordId}       ← MaintenanceRecord.toJson
   │      vehicleId, type, changeDate, changeMileage,
   │      nextDueMileage, nextDueDate, cost, notes, invoiceImages[], createdAt
   │
   ├── fuel/{logId}                 ← FuelLog.toJson
   │      vehicleId, date, odometer, liters, cost, station, fullTank, createdAt
   │
   ├── expenses/{expenseId}         ← Expense.toJson
   │      vehicleId, category, amount, date, title, notes, createdAt
   │
   └── documents/{documentId}       ← VehicleDocument.toJson
          vehicleId, type, title, fileUrl, expiryDate, issueDate, notes, createdAt
```

Document binaries live in **Storage** at `users/{uid}/documents/{documentId}`.

## 4. Security rules

`firestore.rules` (also at the project root):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /{collection}/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```

`storage.rules` (also at the project root):
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{uid}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

Deploy:
```bash
firebase deploy --only firestore:rules,storage
```

## 5. Recommended Firestore indexes
The app reads per‑collection and filters by `vehicleId` client‑side, so no
composite indexes are required for the default queries. If you move filtering
server‑side, add an index on `(vehicleId, date)` per collection.
