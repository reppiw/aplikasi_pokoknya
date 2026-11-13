class AppUser {
  final String id;
  final String displayName;
  final String username;
  final String avatarUrl;
  final String bio;
  final String email;

  const AppUser({
    required this.id,
    required this.displayName,
    this.username = '',
    this.avatarUrl = '',
    this.bio = '',
    this.email = '',
  });

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) {
    return AppUser(
      id: uid,
      displayName: (data['name'] as String? ?? '').trim(),
      username: (data['username'] as String? ?? '').trim(),
      avatarUrl: (data['photoUrl'] as String? ?? '').trim(),
      bio: (data['bio'] as String? ?? '').trim(),
      email: (data['email'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': displayName,
        'username': username,
        'photoUrl': avatarUrl,
        'bio': bio,
        'email': email,
      };

  AppUser copyWith({
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? email,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      email: email ?? this.email,
    );
  }
}