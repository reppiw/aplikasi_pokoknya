class UserProfile {
  String name;
  String email;
  String role;
  String bio;
  bool notificationsEnabled;

  UserProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.bio,
    required this.notificationsEnabled,
  });
}