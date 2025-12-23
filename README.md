<p align="center">
  <img src="assets/images/logo.png" alt="Axora Logo" width="200"/>
</p>

<h1 align="center">✨ AxorA ✨</h1>
<h3 align="center">Your Personal Meditation & Wellness Companion</h3>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
</p>
<p align="center">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Made%20with-Love-ff69b4?style=for-the-badge" />
</p>

<p align="center">
  <i>Find your inner peace with Axora - where modern technology meets ancient wellness practices</i>
</p>

---

## 🌟 Journey Into Tranquility

Axora takes you on a transformative meditation journey through a beautifully designed Flutter application. With seamless Firebase integration, dynamic theming that adapts to your mood, and a user experience crafted for peace of mind.

<details>
<summary><b>🔮 See What Awaits You</b></summary>

* **Day-by-day meditation journeys** that evolve with your practice
* **Personalized user profiles** that track your wellness progress
* **Flow state tracking** to maintain your meditation streak
* **Responsive design** that works perfectly across all your devices
* **Dark & light themes** that change with your mood or time of day

</details>

---

## 💫 Why Axora?

In a world filled with meditation apps, Axora stands apart with a unique approach to mindfulness:

### 🌊 Flow-Focused
Unlike traditional apps that simply track sessions, Axora's Flow System adapts to your consistency, rewarding regular practice and gently guiding you back when you miss days.

### 🔄 Real-Time Sync
While other apps offer basic cloud saving, Axora's Firebase integration provides true real-time experience synchronization across all your devices, picking up exactly where you left off.

### 🎭 Mood-Adaptive
Beyond basic dark/light modes, Axora's theming system responds to your state of mind, with colors and interfaces that evolve to match your wellness journey.

### 🛠️ Full Platform Support
Unlike competitors limited to mobile, Axora's Flutter foundation delivers a premium experience across mobile, web, and desktop platforms with a single codebase.

### 🧠 Progressive Journey
Instead of isolated sessions, Axora offers evolving meditation paths that build upon your growing skills, adapting difficulty and technique as you advance.

### 🔒 Privacy-Centered
Your meditation data is yours alone. Axora's thoughtful Firebase security rules ensure your practice remains private while still enabling seamless synchronization.

Where Headspace offers guided sessions and Calm focuses on sleep stories, Axora delivers a complete mindfulness ecosystem that grows with you, keeping you in flow state through beautiful design and intelligent progress tracking.

---

## ✨ Core Features

### 🔐 Seamless Authentication
- Email/Password login with secure validation
- One-tap Google Sign-In integration
- Persistent sessions across app restarts
- Password reset with email verification
- Anonymous browsing option

### ☁️ Cloud Synchronization
- Real-time Firebase data synchronization
- Cross-device profile consistency
- Secure user data storage
- Offline capability with background syncing
- Meditation progress tracking

### 🎨 Dynamic Theming
- Soothing light mode: Cream & Green
- Calming dark mode: Navy & Gold
- Theme preferences saved to your profile
- Beautiful text highlighting for focus
- Elegant Google Fonts integration (Poppins)

### 📱 Adaptive UI Design
- Responsive layouts for any screen size
- Fluid animations and transitions
- Accessibility-focused interface
- Intuitive navigation patterns
- Cross-platform consistency

---

## 🏗️ Architecture Overview

```
lib/
├── 📱 main.dart                # App entry point & initialization
├── 🔍 screens/                  # Application views
│   ├── login_screen.dart       # User authentication 
│   ├── home_screen.dart        # Main app interface
│   └── meditation_journey_screen.dart  # Guided meditation
├── 🧩 widgets/                  # Reusable components
│   ├── theme_toggle_button.dart # Theme switcher
│   └── theme_showcase.dart     # Theme preview
├── 🔄 providers/                # State management
├── 🛠️ services/                 # Firebase interactions
└── 📊 utils/                    # Helper functions & constants
```

---

## 🚀 Quick Setup

```bash
# Clone this peaceful repository
git clone https://github.com/rehan5039/Axora

# Enter the sanctuary
cd axora

# Gather the essentials
flutter pub get

# Begin your journey
flutter run
```

<details>
<summary><b>🔥 Firebase Configuration</b></summary>

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication, Cloud Firestore and Realtime Database
3. Add your Flutter app to the project
4. Download configuration files and add them to your project
5. Set security rules as shown below:

```
// Firestore Security Rules
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && 
                          request.auth.uid == userId;
    }
    match /user_profiles/{userId} {
      allow read, write: if request.auth != null && 
                          request.auth.uid == userId;
    }
  }
}
```

</details>

---

## 🧘‍♀️ Theme System

Axora's theme system is designed to enhance your meditation experience:

### ☀️ Light Mode
A soothing cream backdrop with refreshing green accents to energize your daytime sessions

### 🌙 Dark Mode
Calming navy background with warm gold highlights for peaceful evening meditation

Your theme preference follows you across devices through Firebase synchronization.

---

## 📚 Technical Dependencies

```yaml
dependencies:
  firebase_core: ^2.27.1
  firebase_auth: ^4.17.9
  cloud_firestore: ^4.15.9
  firebase_database: ^10.4.9
  google_sign_in: ^6.2.1
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.10+1
  provider: ^6.1.2
  email_validator: ^2.1.17
  shared_preferences: ^2.2.2
  flutter_native_splash: ^2.3.10
```

---

## 🔮 Future Enhancements

<details>
<summary><b>Coming in Future Versions</b></summary>

- **📊 Advanced Analytics** - Deeper insights into your meditation patterns
- **🔔 Smart Notifications** - AI-powered reminders based on your schedule
- **🔒 Enhanced Security** - Biometric authentication and 2FA
- **🌐 Social Community** - Connect with fellow meditators
- **📲 Apple Health & Google Fit** - Integration with health platforms

</details>

---

## 👨‍💻 The Minds Behind Axora

**Saad**  
📧 <a href="mailto:saadkalburge95@gmail.com">saadkalburge95@gmail.com</a>
---
<!--
**Rehan**  
📧 <a href="mailto:gg.rehan1234@gmail.com">gg.rehan1234@gmail.com</a>


<p align="center">
  <sub>© 2025 Axora Application. All rights reserved.</sub><br>
  <sub>Made with ❤️ for a calmer world</sub>
</p>

# Axora App

## Important Security Notes

### Sensitive Files
The following files contain sensitive information and are NOT included in the repository:

1. `android/app/axora.jks` - Release keystore file
2. `android/key.properties` - Keystore credentials
3. `android/app/google-services.json` - Firebase configuration
4. `ios/Runner/GoogleService-Info.plist` - iOS Firebase configuration

### Setting Up Development Environment

To set up your development environment, you need to:

1. Obtain the release keystore file (`axora.jks`) from the project administrator
2. Place `axora.jks` in `android/app/` directory
3. Create `android/key.properties` with the following content:
   ```properties
   storePassword=<ask_team_lead_for_password>
   keyPassword=<ask_team_lead_for_password>
   keyAlias=axora
   storeFile=axora.jks
   ```
4. Obtain `google-services.json` from Firebase Console and place it in `android/app/`

### Security Best Practices
- Never commit sensitive files to the repository
- Keep the keystore file and its passwords secure
- Store sensitive files in a secure location outside the project directory
- Use environment variables for sensitive information in CI/CD pipelines

### Release Signing
The app is signed using a release keystore with the following details:
- Keystore Location: `android/app/axora.jks`
- Key Alias: `axora`
- SHA-1: `01:DE:61:0A:71:CB:6E:2E:E6:AA:3E:58:C1:ED:95:84:98:B8:26:FD`

Contact the project administrator for access to these files.
-->
