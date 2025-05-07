<p align="center">
  <img src="https://raw.githubusercontent.com/rehan5039/Axora/main/assets/images/logo.png" alt="Axora Logo" width="180"/>
</p>

<h1 align="center">✨ AXORA ✨</h1>
<h3 align="center">Your Personal Meditation & Wellness Companion</h3>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
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
<p>

* **Day-by-day meditation journeys** that evolve with your practice
* **Personalized user profiles** that track your wellness progress
* **Flow state tracking** to maintain your meditation streak
* **Responsive design** that works perfectly across all your devices
* **Dark & light themes** that change with your mood or time of day

</p>
</details>

---

## 💫 Why Axora?

In a world filled with meditation apps, Axora stands apart with a unique approach to mindfulness:

<table>
  <tr>
    <td width="33%" align="center">
      <h3>🌊 Flow-Focused</h3>
      <p>Unlike traditional apps that simply track sessions, Axora's Flow System adapts to your consistency, rewarding regular practice and gently guiding you back when you miss days.</p>
    </td>
    <td width="33%" align="center">
      <h3>🔄 Real-Time Sync</h3>
      <p>While other apps offer basic cloud saving, Axora's Firebase integration provides true real-time experience synchronization across all your devices, picking up exactly where you left off.</p>
    </td>
    <td width="33%" align="center">
      <h3>🎭 Mood-Adaptive</h3>
      <p>Beyond basic dark/light modes, Axora's theming system responds to your state of mind, with colors and interfaces that evolve to match your wellness journey.</p>
    </td>
  </tr>
  <tr>
    <td width="33%" align="center">
      <h3>🛠️ Full Platform Support</h3>
      <p>Unlike competitors limited to mobile, Axora's Flutter foundation delivers a premium experience across mobile, web, and desktop platforms with a single codebase.</p>
    </td>
    <td width="33%" align="center">
      <h3>🧠 Progressive Journey</h3>
      <p>Instead of isolated sessions, Axora offers evolving meditation paths that build upon your growing skills, adapting difficulty and technique as you advance.</p>
    </td>
    <td width="33%" align="center">
      <h3>🔒 Privacy-Centered</h3>
      <p>Your meditation data is yours alone. Axora's thoughtful Firebase security rules ensure your practice remains private while still enabling seamless synchronization.</p>
    </td>
  </tr>
</table>

Where Headspace offers guided sessions and Calm focuses on sleep stories, Axora delivers a complete mindfulness ecosystem that grows with you, keeping you in flow state through beautiful design and intelligent progress tracking.

---

## ✨ Core Features

<table>
  <tr>
    <td width="50%">
      <h3 align="center">🔐 Seamless Authentication</h3>
      <ul>
        <li>Email/Password login with secure validation</li>
        <li>One-tap Google Sign-In integration</li>
        <li>Persistent sessions across app restarts</li>
        <li>Password reset with email verification</li>
        <li>Anonymous browsing option</li>
      </ul>
    </td>
    <td width="50%">
      <h3 align="center">☁️ Cloud Synchronization</h3>
      <ul>
        <li>Real-time Firebase data synchronization</li>
        <li>Cross-device profile consistency</li>
        <li>Secure user data storage</li>
        <li>Offline capability with background syncing</li>
        <li>Meditation progress tracking</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3 align="center">🎨 Dynamic Theming</h3>
      <ul>
        <li>Soothing light mode: Cream & Green</li>
        <li>Calming dark mode: Navy & Gold</li>
        <li>Theme preferences saved to your profile</li>
        <li>Beautiful text highlighting for focus</li>
        <li>Elegant Google Fonts integration (Poppins)</li>
      </ul>
    </td>
    <td width="50%">
      <h3 align="center">📱 Adaptive UI Design</h3>
      <ul>
        <li>Responsive layouts for any screen size</li>
        <li>Fluid animations and transitions</li>
        <li>Accessibility-focused interface</li>
        <li>Intuitive navigation patterns</li>
        <li>Cross-platform consistency</li>
      </ul>
    </td>
  </tr>
</table>

---

## 🏗️ Architecture Overview

```
lib/
├── 📱 main.dart                # App entry point & initialization
├── 🔍 screens/                  # Application views
│   ├── login_screen.dart       # User authentication 
│   ├── home_screen.dart        # Main app interface
│   ├── meditation_journey_screen.dart  # Guided meditation flows
│   └── ...                     # Other screen modules
├── 🧩 widgets/                  # Reusable components
│   ├── theme_toggle_button.dart # Theme switcher
│   ├── theme_showcase.dart     # Theme preview
│   └── ...                     # Other widget modules
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
<p>

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
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /user_profiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

</p>
</details>

---

## 🧘‍♀️ Theme System

Axora's theme system is designed to enhance your meditation experience:

<table>
  <tr>
    <td width="50%" align="center">
      <h3>☀️ Light Mode</h3>
      <p>A soothing cream backdrop with refreshing green accents to energize your daytime sessions</p>
    </td>
    <td width="50%" align="center">
      <h3>🌙 Dark Mode</h3>
      <p>Calming navy background with warm gold highlights for peaceful evening meditation</p>
    </td>
  </tr>
</table>

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
<p>

- **📊 Advanced Analytics** - Deeper insights into your meditation patterns
- **🔔 Smart Notifications** - AI-powered reminders based on your schedule
- **🔒 Enhanced Security** - Biometric authentication and 2FA
- **🌐 Social Community** - Connect with fellow meditators
- **📲 Apple Health & Google Fit** - Integration with health platforms

</p>
</details>

---

## 👨‍💻 The Minds Behind Axora

<table>
  <tr>
    <td align="center">
      <b>Saad</b><br>
      📧 <a href="mailto:saadkalburge95@gmail.com">saadkalburge95@gmail.com</a>
    </td>
    <td align="center">
      <b>Rehan</b><br>
      📧 <a href="mailto:gg.rehan1234@gmail.com">gg.rehan1234@gmail.com</a>
    </td>
  </tr>
</table>

---

<p align="center">
  <sub>© 2025 Axora Application. All rights reserved.</sub><br>
  <sub>Made with ❤️ for a calmer world</sub>
</p>
