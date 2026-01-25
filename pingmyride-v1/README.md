# PingMyRide

A Flutter-based ride tracking application for students, drivers, and administrators.

## Features

### 🎨 Modern UI Components
- Material Design 3 with custom theme
- Animated login transitions using animate_do
- Custom form components with validation
- Beautiful gradient cards and modern buttons

### 🔐 Multi-User Authentication
- **Student Login**: Access to bus tracking, schedules, and notifications
- **Driver Login**: Route management, student lists, and reporting
- **Admin Login**: System management, analytics, and user administration

### 📱 Bottom Navigation
Each user type has customized navigation:
- **Students**: Home, Track Bus, Schedule, Profile
- **Drivers**: Home, Routes, Students, Profile  
- **Admins**: Home, Management, Analytics, Profile

### 🚌 App Icon
Custom bus and location pin icon applied across all platforms (Android, iOS, Web, Windows, macOS, Linux)

## Getting Started

### Prerequisites
- Flutter SDK (3.9.0+)
- Dart SDK
- Android Studio / VS Code
- Device or emulator for testing

### Installation

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd pingmyride
   flutter pub get
   ```

2. **Generate app icons** (already done):
   ```bash
   dart run flutter_launcher_icons
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

### Project Structure

```
lib/
├── core/
│   ├── models/          # Data models (UserType)
│   └── theme/           # App theme and styling
├── features/
│   ├── auth/            # Login and authentication
│   ├── home/            # Dashboard pages
│   └── navigation/      # Main navigation structure
├── shared/
│   └── widgets/         # Reusable UI components
└── main.dart           # App entry point
```

### Dependencies

- **animate_do**: ^3.3.4 - Smooth animations
- **go_router**: ^14.2.7 - Navigation management  
- **provider**: ^6.1.2 - State management
- **material_symbols_icons**: ^4.2719.3 - Material icons
- **shimmer**: ^3.0.0 - Loading animations
- **flutter_launcher_icons**: ^0.14.1 - Icon generation

## Usage

### Login Process
1. Launch the app to see the login screen
2. Choose your user type (Student/Driver/Admin) using the tabs
3. Enter credentials (any valid email/password for demo)
4. Access role-specific dashboard and navigation

### User Roles

#### Student Features
- **Home**: Quick actions for tracking and schedules
- **Track Bus**: Real-time bus location (placeholder)
- **Schedule**: Bus timetables and route info
- **Profile**: Personal settings and preferences

#### Driver Features  
- **Home**: Route management and student overview
- **Routes**: Active route information and controls
- **Students**: Passenger list and notifications
- **Profile**: Driver account settings

#### Admin Features
- **Home**: System overview and management tools
- **Management**: User and route administration
- **Analytics**: Usage statistics and reports
- **Profile**: Administrator settings

## Customization

### Theme Colors
Edit `lib/core/theme/app_theme.dart` to customize:
- Primary color: Blue (#2563EB)
- Background: Light gray (#F8FAFC)
- Surface: White (#FFFFFF)

### Adding New Features
1. Create feature folder under `lib/features/`
2. Add new pages to navigation in `main_navigation.dart`
3. Update bottom navigation items as needed

## Build and Deploy

### Android
```bash
flutter build apk --release
```

### iOS  
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push branch (`git push origin feature/new-feature`)
5. Create Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
# pingmyride-v1
