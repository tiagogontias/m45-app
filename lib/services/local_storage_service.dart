import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/user_model.dart';

class LocalStorageService {
  static const String _userBoxName = 'm45_user';
  static const String _pendingBoxName = 'm45_pending';

  Future<void> init() async {
    String dirPath;
    try {
      // Usar diretório de dados do app (não Documents)
      final dir = await getApplicationSupportDirectory();
      dirPath = '${dir.path}/hive_data';
    } catch (_) {
      dirPath = Directory.systemTemp.path;
    }
    
    // Criar diretório se não existir
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    Hive.init(dirPath);
    await Hive.openBox(_userBoxName);
    await Hive.openBox(_pendingBoxName);
  }

  Future<void> saveUser(UserModel user) async {
    final box = Hive.box(_userBoxName);
    await box.put('user', jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final box = Hive.box(_userBoxName);
    final data = box.get('user');
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  Future<void> clearUser() async {
    final box = Hive.box(_userBoxName);
    await box.clear();
  }

  Future<void> savePendingCheckin(Map<String, dynamic> checkin) async {
    final box = Hive.box(_pendingBoxName);
    final pending = box.get('checkins', defaultValue: <dynamic>[]) as List;
    pending.add(checkin);
    await box.put('checkins', pending);
  }

  List<Map<String, dynamic>> getPendingCheckins() {
    final box = Hive.box(_pendingBoxName);
    final pending = box.get('checkins', defaultValue: <dynamic>[]) as List;
    return pending.cast<Map<String, dynamic>>();
  }

  Future<void> setPendingCheckins(List<Map<String, dynamic>> checkins) async {
    final box = Hive.box(_pendingBoxName);
    await box.put('checkins', checkins);
  }

  Future<void> clearPendingCheckins() async {
    final box = Hive.box(_pendingBoxName);
    await box.put('checkins', <dynamic>[]);
  }
}
