# Axora

## Project Overview

Axora is a modern Flutter application that showcases user authentication, cloud firestore integration, and dynamic theming. The application includes a meditation and wellness focus with a clean, responsive UI design that adapts to both light and dark modes.

## Features

- **Authentication System**
  - Email/Password Login and Registration
  - Google Sign-In Integration
  - Password Reset Functionality
  - Persistent User Sessions

- **Cloud Firestore**
  - Real-time Database Integration
  - User Profile Management
  - Data Synchronization Across Sessions

- **Dynamic Theming**
  - Light and Dark Mode Support
  - User Preference Persistence in Firebase
  - Custom Color Palettes:
    - Light Mode: Cream background with Green accents
    - Dark Mode: Navy background with Gold accents
  - Text Highlighters for Important Content

- **Responsive UI**
  - Cross-Platform Design (Mobile, Web, Desktop)
  - Adaptive Layouts
  - Google Fonts Integration (Poppins)

## Project Structure

### Core Directories

- **`lib/`** - Main source code
  - **`main.dart`** - Application entry point, Firebase initialization
  - **`screens/`** - All application screens
  - **`widgets/`** - Reusable UI components
  - **`providers/`** - State management
  - **`services/`** - Firebase and backend services
  - **`utils/`** - Constants and helper functions

### Key Files

#### Services

- **`lib/services/auth_service.dart`**
  - Handles all authentication functionality
  - Implements email/password and Google sign-in
  - Error handling for authentication processes

- **`lib/services/realtime_database_service.dart`**
  - Manages Firebase Realtime Database operations
  - Provides methods for saving and retrieving user data
  - Handles database connection errors gracefully

- **`lib/services/user_database_service.dart`**
  - Manages user data in Firestore
  - Handles profile updates and settings persistence

#### Screens

- **`lib/screens/login_screen.dart`**
  - Login interface with email/password and Google sign-in
  - Form validation and error handling
  - Navigation to registration and password reset

- **`lib/screens/signup_screen.dart`**
  - User registration with email/password
  - Google sign-up option
  - Form validation with real-time feedback

- **`lib/screens/home_screen.dart`**
  - Main application interface
  - Navigation between different tabs
  - User profile and settings access

- **`lib/screens/forgot_password_screen.dart`**
  - Password reset functionality
  - Email validation and error handling

#### Theme and Styling

- **`lib/providers/theme_provider.dart`**
  - Manages theme state
  - Syncs user theme preferences with Firebase
  - Provides both light and dark theme data

- **`lib/utils/constants.dart`**
  - Application colors and style definitions
  - Text styles for various screen elements
  - Input field decorations for forms

- **`lib/widgets/theme_toggle_button.dart`**
  - Animated theme switching button
  - Visual feedback for current theme

- **`lib/widgets/theme_showcase.dart`**
  - Demonstrates all theme elements
  - Preview of colors, text styles, and UI components

## Firebase Configuration

The application uses several Firebase services:

1. **Firebase Authentication**
   - Email/Password Authentication
   - Google Sign-In Provider

2. **Cloud Firestore**
   - User data storage
   - Settings persistence
   - Profile information

3. **Realtime Database**
   - Real-time user preferences
   - Online status tracking
   - App state synchronization

## Security Rules

The Firestore and Realtime Database have specific security rules:

```
// Firestore Rules
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /user_profiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Installation and Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/rehan5039/Axora
   cd axora
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password and Google Sign-In)
   - Create Cloud Firestore and Realtime Database instances
   - Add your Flutter application to the Firebase project
   - Download and add the Firebase configuration files

4. **Run the Application**
   ```bash
   flutter run
   ```

## Theme System Implementation

The theme system in Axora is carefully designed to provide a seamless experience across the application:

1. **Theme Definition**
   - Two complete themes (Light and Dark) with custom colors
   - Consistent text styling with Google Fonts
   - Shared component styles with theme-specific colors

2. **Theme Persistence**
   - User theme preferences are saved to Firebase
   - Theme setting is restored on application restart
   - Settings are synced across devices

3. **Theme Showcase**
   - A dedicated screen to showcase all theme elements
   - Direct theme toggling for testing
   - Visual comparison of theme components

## Error Handling

The application implements comprehensive error handling:

1. **Authentication Errors**
   - User-friendly error messages
   - Validation for email and password fields
   - Graceful handling of network issues

2. **Database Errors**
   - Fallback mechanisms for connection issues
   - Retry logic for failed operations
   - Error logging and user feedback

## Future Enhancements

Planned features for future versions:

1. **Offline Support**
   - Complete offline functionality with data synchronization
   - Background syncing when connection is restored

2. **Enhanced Security**
   - Two-factor authentication
   - Biometric login options

3. **UI/UX Improvements**
   - Additional animations and transitions
   - More customization options
   - Accessibility enhancements

## Dependencies

- `firebase_core: ^2.27.1`
- `firebase_auth: ^4.17.9`
- `cloud_firestore: ^4.15.9`
- `firebase_database: ^10.4.9`
- `google_sign_in: ^6.2.1`
- `google_fonts: ^6.1.0`
- `flutter_svg: ^2.0.10+1`
- `provider: ^6.1.2`
- `email_validator: ^2.1.17`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Firebase for the backend infrastructure
- Flutter team for the amazing framework
- All contributors who have helped in developing Axora

## Authors

[Saad] - [saadkalburge95@gmail.com]
[Rehan] - [gg.rehan1234@gmail.com]

---

© 2025 Axora Application. All rights reserved.
