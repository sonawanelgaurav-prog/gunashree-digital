import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'services.dart';

class AppState extends ChangeNotifier {
  AppState(this.api);

  final ApiService api;
  final List<PosterTemplate> templates = [];
  final List<Category> categories = [];
  final List<LocalDesign> designs = [];

  String? token;
  String? userName;
  String? phone;
  bool isLoading = false;
  String? lastError;

  bool get isSignedIn => token != null && token!.isNotEmpty;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('gd_token');
    userName = prefs.getString('gd_name');
    phone = prefs.getString('gd_phone');
    _loadDesigns(prefs);
    templates
      ..clear()
      ..addAll(demoTemplates());

    isLoading = true;
    notifyListeners();
    try {
      final remoteTemplates = await api.fetchTemplates();
      if (remoteTemplates.isNotEmpty) {
        templates
          ..clear()
          ..addAll(remoteTemplates);
      }
      final remoteCategories = await api.fetchCategories();
      categories
        ..clear()
        ..addAll(remoteCategories);
    } catch (_) {
      lastError = 'Showing starter templates while the studio is offline.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _loadDesigns(SharedPreferences prefs) {
    final raw = prefs.getString('gd_designs');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        designs
          ..clear()
          ..addAll(decoded.whereType<Map>().map(
              (item) => LocalDesign.fromJson(Map<String, dynamic>.from(item))));
      }
    } catch (_) {
      designs.clear();
    }
  }

  Future<void> saveDesign({
    required PosterTemplate template,
    required List<PosterLayer> layers,
    required String name,
    required Color background,
  }) async {
    final design = LocalDesign(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Untitled Design' : name.trim(),
      templateId: template.id,
      templateTitle: template.title,
      background: background,
      layers: layers.map((layer) => layer.copy()).toList(),
      updatedAt: DateTime.now(),
    );
    designs.removeWhere((item) => item.id == design.id);
    designs.insert(0, design);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gd_designs',
        jsonEncode(designs.map((item) => item.toJson()).toList()));

    if (isSignedIn) {
      try {
        await api.saveDesign(
          token: token!,
          name: design.name,
          templateId: design.templateId,
          data: {
            'background': colorToHex(background),
            'layers': layers.map((layer) => layer.toJson()).toList(),
          },
        );
      } catch (_) {
        lastError =
            'Saved on this device. Sync will retry when you are online.';
      }
    }
    notifyListeners();
  }

  Future<void> login(String enteredPhone, String password) async {
    final result = await api.login(enteredPhone.trim(), password);
    token = stringValue(result['token']);
    final user = result['user'] is Map
        ? Map<String, dynamic>.from(result['user'])
        : <String, dynamic>{};
    userName = stringValue(user['name'], 'Designer');
    phone = stringValue(user['phone'], enteredPhone.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gd_token', token!);
    await prefs.setString('gd_name', userName!);
    await prefs.setString('gd_phone', phone!);
    notifyListeners();
  }

  Future<void> signOut() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gd_token');
    notifyListeners();
  }
}
