import '../profile/user_model.dart';
import './../user/services/user_service.dart';
import '../follow/mutual_service.dart';

class SearchService {
  final UserService _userService;
  final MutualService _mutualService;

  SearchService({UserService? userService, MutualService? mutualService})
    : _userService = userService ?? UserService(),
      _mutualService = mutualService ?? MutualService();

  // ------------------------------------------------------------
  // SEARCH USERS (WITH OPTIONAL MUTUAL ENRICHMENT)
  // ------------------------------------------------------------
  Future<List<UserModel>> searchUsers({
    required String query,
    String? currentUid,
  }) async {
    if (query.trim().isEmpty) return [];

    // 1️⃣ Pure search (Firestore handled by UserService)
    final users = await _userService.searchUsers(query);

    // 2️⃣ No auth context → return raw results
    if (currentUid == null) {
      return users;
    }

    // 3️⃣ Enrich with mutual info (parallelized)
    return Future.wait(
      users.map((user) async {
        if (user.uid == currentUid) {
          return user;
        }

        final isMutual = await _mutualService.isMutual(
          currentUid: currentUid,
          targetUid: user.uid,
        );

        return user.copyWith(hasMutual: isMutual);
      }),
    );
  }
}
