# NotePlus

A comprehensive note-taking web application built with Flutter that includes user authentication, note management, calendar integration, and more.

## Features

### 🔐 User Authentication
- User registration with username and email
- Secure login system
- Password reset functionality

### 📝 Note Management
- Create, edit, and delete notes
- Multiple note types: Text, Drawing, Tasks, Checklists
- Rich text formatting
- Note pinning for important notes
- Color-coded notes
- Tags and categories for organization

### 📅 Calendar Integration
- View notes with reminders in calendar format
- Schedule reminders for notes
- Monthly, weekly, and daily views
- Event management

### ✅ Task Management
- Create task lists and checklists
- Track task completion
- Reorder tasks
- Task deadlines and reminders

### 🎨 Drawing & Handwriting
- Draw notes with different colors
- Handwriting support
- Save and edit drawings

### 📎 File Attachments
- Attach images and files to notes
- Image picker integration
- File management system

### 🔍 Search & Organization
- Search across all notes
- Filter by tags, categories, or date
- Advanced search functionality
- Sort and organize notes

### 🔔 Reminders & Notifications
- Set reminders for notes and tasks
- Calendar-based reminders
- Notification system

### 📱 Responsive Design
- Works on web, mobile, and desktop
- Modern Material Design 3 UI
- Dark/light theme support
- Grid and list view options

## Getting Started

### Prerequisites
- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Firebase project setup

### Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password)
3. Enable Firestore Database
4. Enable Firebase Storage
5. Download the configuration files:
   - For Android: `google-services.json` → place in `android/app/`
   - For Web: Firebase config snippet → add to `web/index.html`

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd noteplus
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run -d chrome
```

For web deployment:
```bash
flutter build web
```

## Project Structure

```
lib/
├── models/           # Data models (User, Note, TaskItem)
├── services/         # Firebase services (Auth, Notes)
├── pages/            # Main app pages
│   ├── auth/         # Authentication pages
│   ├── home/         # Home page
│   ├── notes/        # Note management
│   ├── calendar/     # Calendar integration
│   ├── drawing/      # Drawing functionality
│   └── tasks/        # Task management
├── widgets/          # Reusable UI components
└── main.dart         # App entry point
```

## Dependencies

- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `firebase_storage` - File storage
- `provider` - State management
- `table_calendar` - Calendar widget
- `flutter_signature_pad` - Drawing functionality
- `image_picker` - Image selection
- `file_picker` - File selection
- `google_fonts` - Typography
- And more...

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions, please open an issue on the GitHub repository.
