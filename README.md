# AlyAI iOS App

**Personalized AI Health & Wellness Companion**

A SwiftUI-based iOS application that provides personalized health and wellness guidance powered by AI.

---

## 🚀 Features

- **Personalized Dashboard** - Modern card-based UI with real-time health metrics
- **AI Chat Assistant** - Conversational AI for health guidance
- **Profile Management** - Comprehensive user profile and preferences
- **Subscription Management** - Premium features with in-app purchases
- **Apple HIG Compliant** - Follows Apple's Human Interface Guidelines
- **Dark Mode Support** - Full light and dark mode compatibility

---

## 📋 Requirements

- **Xcode 15.0+**
- **iOS 15.0+**
- **Swift 5.9+**
- **OpenAI API Key** (required for AI chat features)

---

## 🛠️ Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/TentacleIT/AlyAI-iOS-App.git
cd AlyAI-iOS-App
```

### 2. Add Your OpenAI API Key

Open `AlyAI/Info.plist` and replace `YOUR_OPENAI_API_KEY_HERE` with your actual OpenAI API key:

```xml
<key>OPENAI_API_KEY</key>
<string>sk-proj-YOUR_ACTUAL_KEY_HERE</string>
```

**⚠️ Important:** Never commit your actual API key to version control. Add `Info.plist` to `.gitignore` if you plan to push changes.

### 3. Open in Xcode

```bash
open ALYAI.xcodeproj
```

### 4. Build and Run

- Select your target device or simulator
- Press `Cmd+B` to build
- Press `Cmd+R` to run

---

## 📁 Project Structure

```
AlyAI/
├── AlyAI/
│   ├── ALYAIApp.swift          # App entry point
│   ├── ContentView.swift       # Main navigation
│   ├── Dashboard.swift         # Home screen (Dashboard_Enhanced)
│   ├── ChatView.swift          # AI chat interface (ChatView_Enhanced)
│   ├── ProfileView.swift       # User profile screen
│   ├── SubscriptionView.swift  # Subscription management
│   ├── ButtonStyles.swift      # Custom button styles
│   ├── ColorTheme.swift        # Color system
│   ├── ModernUIComponents.swift # Reusable UI components
│   └── ...
├── CHANGELOG.md                # Version history
├── ERROR_FIX_REPORT.md        # Compilation fixes documentation
└── UI_UX_ENHANCEMENTS.md      # UI/UX improvements documentation

```

---

## 🎨 UI/UX Enhancements

This version includes comprehensive UI/UX improvements:

- ✅ Modern card-based layouts
- ✅ Improved visual hierarchy
- ✅ Enhanced spacing and typography
- ✅ Apple HIG-compliant button styles
- ✅ Better color contrast and accessibility
- ✅ Smooth animations and transitions

See `UI_UX_ENHANCEMENTS.md` for detailed documentation.

---

## 🐛 Recent Fixes

All compilation errors have been resolved:

- ✅ Fixed `ContentView.swift` Dashboard reference
- ✅ All struct definitions verified
- ✅ Color system intact
- ✅ No duplicate declarations
- ✅ Ready for Xcode build

See `ERROR_FIX_REPORT.md` for detailed fix documentation.

---

## 📚 Documentation

- **UI_UX_ENHANCEMENTS.md** - Complete UI/UX enhancement guide
- **ERROR_FIX_REPORT.md** - Compilation error fixes and verification
- **CHANGELOG.md** - Version history and changes

---

## 🔒 Security Notes

- **Never commit API keys** to version control
- **Use environment variables** for sensitive data in production
- **Enable App Transport Security** for network requests
- **Follow Apple's security best practices**

---

## 📱 Testing Checklist

After building, test the following:

- [ ] Splash screen displays correctly
- [ ] Onboarding flow works
- [ ] Dashboard loads with personalized content
- [ ] Chat interface sends and receives messages
- [ ] Profile screen displays user information
- [ ] Subscription screen shows pricing
- [ ] Navigation between screens works
- [ ] Light mode appearance is correct
- [ ] Dark mode appearance is correct
- [ ] All buttons are clickable and functional

---

## 🤝 Contributing

This is a private project. For questions or issues, contact the development team.

---

## 📄 License

Proprietary - All rights reserved

---

## 🔗 Links

- **Repository:** https://github.com/TentacleIT/AlyAI-iOS-App
- **Issues:** https://github.com/TentacleIT/AlyAI-iOS-App/issues

---

**Built with ❤️ using SwiftUI**
