import 'package:connectivity_plus/connectivity_plus.dart';

import 'local_storage_service.dart';
import 'pocketbase_service.dart';

class SyncService {
  final LocalStorageService _localStorage;
  final PocketBaseService _pocketBase;

  SyncService({
    required LocalStorageService localStorage,
    required PocketBaseService pocketBase,
  })  : _localStorage = localStorage,
        _pocketBase = pocketBase;

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  Future<void> syncPendingData() async {
    final online = await isOnline();
    if (!online) return;

    final checkins = _localStorage.getPendingCheckins();
    if (checkins.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final checkin in checkins) {
      try {
        final eventoId =
            (checkin['eventoId'] ?? checkin['evento_id'] ?? '').toString();
        final token = (checkin['token'] ?? '').toString();
        final userId = (checkin['userId'] ?? checkin['user_id'] ?? '').toString();

        if (eventoId.isEmpty || token.isEmpty) {
          remaining.add(checkin);
          continue;
        }

        await _pocketBase.realizarCheckin(eventoId, token, userId);
        // Sucesso: não adiciona à lista de pendentes
      } catch (_) {
        remaining.add(checkin);
      }
    }

    await _localStorage.setPendingCheckins(remaining);
  }
}
