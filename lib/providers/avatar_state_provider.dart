import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/avatar_state.dart';
import '../services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(),
);

final avatarStatesProvider = StreamProvider.family<List<AvatarState>, String>((
  ref,
  groupId,
) {
  return ref.watch(databaseServiceProvider).watchGroupAvatarStates(groupId);
});
