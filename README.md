# MMMBites 🍽️

A shared dining memory app built with SwiftUI and Firebase. MMMBites lets you and your friends capture, organise, and relive your favourite food experiences together.

## Features

- **Authentication** — Email/password sign up and login with Firebase Auth
- **User Profiles** — Custom display name, username, and profile photo
- **Friends** — Add and remove friends to share experiences with
- **Shared Albums** — Create dining albums and invite friends as members
- **Memories** — Add photos, notes, location, and date to each memory
- **Custom Tags** — Tag albums with labels like "Fancy", "Outdoors", "Family"
- **Search & Filter** — Search memories and filter by tags

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Authentication | Firebase Auth |
| Database | Firebase Firestore |
| File Storage | Firebase Storage |
| Image Loading | SDWebImageSwiftUI |
| Animations | Lottie |
| Notifications | AlertKit |

## Requirements

- iOS 16+
- Xcode 15+
- A Firebase project with Auth, Firestore, and Storage enabled

## Getting Started

1. Clone the repo
```bash
git clone https://github.com/la1a19/MMMBites.git
```

2. Open `MMMBites.xcodeproj` in Xcode

3. Add your own `GoogleService-Info.plist` from your Firebase project into the root of the Xcode project — this file is not included in the repo for security reasons

4. In your Firebase console, enable:
   - Authentication → Email/Password
   - Firestore Database
   - Storage

5. Build and run on a simulator or device

## Project Structure

```
MMMBites/
├── Models/          # Data models: User, Album, Memory, Tag
├── Views/           # Screens: LoginView, SignUpView, AlbumsView etc.
├── ViewModels/      # Business logic: LoginViewModel etc.
├── Components/      # Reusable UI: AuthTextField, PrimaryButton, AvatarView etc.
└── Services/        # Firebase service layers
```

## License

This project is for educational purposes.
