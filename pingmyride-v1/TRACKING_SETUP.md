# Bus Tracking & QR Code Setup Guide

This guide will help you set up the bus tracking with Google Maps and QR code ticket system.

## 1. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Directions API** (required for polylines)
   - **Places API** (optional, for place search)
4. Create credentials → API Key
5. Copy your API key

## 2. Add API Key to Code

Update `/lib/core/services/tracking_service.dart`:
```dart
static const String _googleMapsApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

## 3. Configure Android

### Add API Key to Android Manifest
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest ...>
    <application ...>
        <!-- Add this inside <application> tag -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_ACTUAL_API_KEY_HERE"/>
            
        <activity ...>
        </activity>
    </application>
    
    <!-- Add these permissions before <application> tag -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-feature android:name="android.hardware.camera" android:required="false"/>
</manifest>
```

## 4. Configure iOS

### Add API Key to AppDelegate
Edit `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import GoogleMaps  // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")  // Add this line
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Add Permissions to Info.plist
Edit `ios/Runner/Info.plist`:
```xml
<dict>
    <!-- Add these entries -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location access to track your bus in real-time</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>This app needs location access to track your bus in real-time</string>
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to scan QR codes for ticket verification</string>
    
    <!-- Your other existing entries -->
    ...
</dict>
```

## 5. Register Services in main.dart

Update your `lib/main.dart`:
```dart
import 'package:provider/provider.dart';
import 'core/services/tracking_service.dart';
import 'core/services/ticket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        // Your existing providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // Add these new providers
        ChangeNotifierProvider(create: (_) => TrackingService()),
        Provider(create: (_) => TicketService()),
      ],
      child: const MyApp(),
    ),
  );
}
```

## 6. Install Dependencies

Run this command to install all new packages:
```bash
flutter pub get
```

## 7. Firestore Security Rules

Update your Firestore security rules to allow ticket operations:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Tickets collection
    match /tickets/{ticketId} {
      // Students can read their own tickets
      allow read: if request.auth != null && 
                    resource.data.userId == request.auth.uid;
      
      // Drivers can read tickets for their buses
      allow read: if request.auth != null && 
                    get(/databases/$(database)/documents/buses/$(resource.data.busId)).data.driverId == request.auth.uid;
      
      // System can create tickets
      allow create: if request.auth != null;
      
      // Drivers can update tickets (scan QR, start ride)
      allow update: if request.auth != null && 
                     get(/databases/$(database)/documents/buses/$(resource.data.busId)).data.driverId == request.auth.uid;
    }
    
    // Your other existing rules...
  }
}
```

## 8. Testing the Features

### Test Bus Tracking:
1. Open bookings page
2. Find a confirmed booking
3. Tap "Track Bus"
4. Choose "Map View" to see polyline and real-time location
5. Or choose "Simple View" for basic tracking info

### Test QR Code Tickets:
1. Student side:
   - Open bookings page
   - Tap "Ticket" on a confirmed booking
   - QR code will be generated and displayed

2. Driver side:
   - Create a QR scanner page in driver app
   - Use the same `QRScannerPage` widget
   - Scan student's QR code
   - Ride will be marked as started

## 9. Troubleshooting

### Map not showing:
- Check if API key is correct
- Ensure Directions API is enabled
- Check internet connection
- Verify Android/iOS configuration

### QR Scanner not working:
- Check camera permissions
- Test on physical device (not emulator)
- Ensure proper lighting

### Location not updating:
- Check location permissions
- Ensure GPS is enabled
- Test on physical device

### Polyline not appearing:
- Check if Directions API is enabled
- Verify API key has proper restrictions
- Check console for API errors

## 10. Cost Optimization

Google Maps API has usage limits:
- **Directions API**: Free up to 2,500 requests/day
- **Maps SDK**: Free up to 28,000 map loads/month

To optimize costs:
- Cache polylines for frequently used routes
- Implement rate limiting for location updates
- Use static maps for non-interactive views

## Project Structure

```
lib/
├── core/
│   ├── models/
│   │   └── ticket.dart              # Ticket model with QR code
│   └── services/
│       ├── tracking_service.dart     # Real-time tracking & polylines
│       └── ticket_service.dart       # QR generation & validation
├── features/
│   ├── bookings/
│   │   └── bookings_page.dart       # Main bookings with track/ticket buttons
│   ├── tracking/
│   │   └── bus_tracking_map_page.dart  # Google Maps with live tracking
│   └── tickets/
│       ├── ticket_qr_page.dart      # Display QR code ticket
│       └── qr_scanner_page.dart     # Scan QR (for drivers)
```

## Key Features Implemented

✅ **Real-time Bus Tracking**
- Live location updates every 2 seconds
- Google Maps integration with custom markers
- Speed and heading information

✅ **Route Polylines**
- Visual route display on map
- Google Directions API integration
- ETA calculations

✅ **QR Code Tickets**
- Secure QR generation with SHA-256
- One-time scan validation
- Automatic ride status updates

✅ **Driver Verification**
- QR scanner for drivers
- Ticket validation
- Ride start confirmation

✅ **Modal Bottom Sheet**
- Track bus with two view options
- Map View: Full Google Maps with polylines
- Simple View: Basic tracking info

## Next Steps

1. ✅ Add Google Maps API key
2. ✅ Configure Android/iOS permissions
3. ✅ Register providers in main.dart
4. ✅ Test tracking on confirmed bookings
5. ✅ Test QR code generation
6. ✅ Test QR scanning (driver side)
7. 🔄 Deploy and monitor API usage

---

**Need help?** Check the comments in each file for detailed implementation notes.
