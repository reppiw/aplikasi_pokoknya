# aplikasi_pokoknya

A new Flutter project.

## Firebase setup

The Android app initializes Firebase from `lib/firebase_options.dart`. Enable
Email/Password under Firebase Authentication and create a Cloud Firestore
database for the configured Firebase project. Users continue to sign in with
their username; the app maps each username to a Firebase email/password
account internally.

Deploy the included Firestore rules from the repository root with the Firebase
CLI:

```sh
firebase deploy --only firestore:rules
```

The app stores user profiles in `users/{uid}`, username reservations in
`usernames/{username}`, and office presence in
`groups/{groupId}/avatars/{uid}`. The current office screen uses the `default`
group.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
