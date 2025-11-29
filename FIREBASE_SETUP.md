# Firebase Setup Guide for Smart Car Tracker

## Overview
The Smart Car Tracker now uses Firebase Authentication for user sign-up and sign-in. This guide will walk you through setting up your Firebase project.

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"** or select an existing one
3. Name your project (e.g., "smart-car-tracker")
4. Follow the setup wizard and enable Google Analytics if desired
5. Click **"Create project"**

## Step 2: Enable Authentication

1. In the Firebase Console, go to **Build > Authentication**
2. Click **"Get Started"**
3. In the **Sign-in method** tab, click **"Email/Password"**
4. Toggle **"Enable"** and click **"Save"**

## Step 3: Configure Firebase for Windows

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click **"Your apps"** section
3. Click the **Web** icon to create a web app (this will also work for Windows in this setup)
4. Register the app with a name like "smart-car-tracker-web"
5. Copy the **Firebase configuration** that appears

## Step 4: Update Firebase Credentials

Open `lib/firebase_options.dart` and replace the placeholder values:

```dart
static const FirebaseOptions windows = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',                    // from Firebase config
  appId: 'YOUR_WEB_APP_ID',                      // from Firebase config
  messagingSenderId: 'YOUR_WEB_MESSAGING_SENDER_ID',  // from Firebase config
  projectId: 'YOUR_FIREBASE_PROJECT_ID',         // from Firebase config (e.g., "smart-car-tracker-abcd1234")
  authDomain: 'YOUR_FIREBASE_PROJECT_ID.firebaseapp.com',  // e.g., "smart-car-tracker-abcd1234.firebaseapp.com"
);
```

**Example** (replace with your actual values):
```dart
static const FirebaseOptions windows = FirebaseOptions(
  apiKey: 'AIzaSyC1234567890abcdefghijk_lmno',
  appId: '1:123456789:web:abc123def456',
  messagingSenderId: '123456789',
  projectId: 'smart-car-tracker-1a2b3c4d',
  authDomain: 'smart-car-tracker-1a2b3c4d.firebaseapp.com',
);
```

## Step 5: Run the App

```powershell
cd c:\Users\steve\smart_car_tracker
flutter pub get
flutter run -d windows
```

## Features Now Enabled

- **Sign Up**: Users can create a new account with email and password
- **Sign In**: Existing users can log in with their credentials
- **Sign Out**: Users can sign out securely
- **Per-User Data**: All devices, vehicles, and maintenance items are persisted per user in Hive
- **Firebase Auth State**: User authentication is verified with Firebase

## Security Notes

- Never commit your `firebase_options.dart` with real credentials to public repositories
- Firebase rules should be configured in the Firebase Console to restrict access
- Passwords are handled securely by Firebase Auth (never stored locally)

## Troubleshooting

### "Firebase is not initialized" Error
- Ensure `Firebase.initializeApp()` is called in `main()` before running the app
- Check that your Firebase credentials in `firebase_options.dart` are correct

### "Invalid credentials" on Sign In
- Verify the user was created in Firebase Console > Authentication > Users
- Check that the email/password combination is correct

### Android/iOS Builds
- For Android: Run `flutterfire configure` and select Android when prompted
- For iOS: Run `flutterfire configure` and select iOS when prompted
- This will auto-generate platform-specific Firebase configuration files

## Next Steps

1. Test sign-up and sign-in flows in the app
2. Add devices and vehicles to verify multi-user, multi-device persistence
3. (Optional) Set up Firestore for cloud backup of user data
4. (Optional) Enable Google Sign-In or other authentication providers
