import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/user_profile_service.dart';

final _userProfileServiceProvider = Provider<UserProfileService>(
  (ref) => UserProfileService(),
);

/// Streams the signed-in user's Firestore profile as an [AppUser].
/// Emits null while loading or when signed out.
final userProfileProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(_userProfileServiceProvider).watchCurrentUser(),
);
