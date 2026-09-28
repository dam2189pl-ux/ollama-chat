import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/message.dart';
import '../models/settings.dart';
import 'ollama_service.dart';

/// Rozmowa TYLKO w RAM.
/// Ustawienia (API, model, samplery, system prompt) zapisywane na dysku.
class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  AppSettings _settings = AppSettings();
  bool _isGenerating = false;
  bool _settingsLoaded = false;
  String? _error;
  List<String> _availableModels = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  AppSettings get settings => _settings;
  bool get isGenerating => _isGenerating;
  bool get settingsLoaded => _settingsLoaded;
  String? get error => _error;
  List<String> get availableModels => List.unmodifiable(_availableModels);

  static const _prefsKey = 'ollama_chat_settings';

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(map);
      }
    } catch (_) {}
    _settingsLoaded = true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_settings.toJson()));
    } catch (_) {}
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _saveSettings();
  }

  void clearConversation() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> checkConnection() async {
    _error = null;
    notifyListeners();
    final service = OllamaService(_settings);
    final result = await service.checkConnection();
    if (result.ok) {
      _availableModels = result.models;
      _error = null;
    } else {
      _error = result.message;
      _availableModels = [];
    }
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isGenerating) return;

    final userMsg = ChatMessage(role: MessageRole.user, content: text.trim());
    _messages.add(userMsg);
    _error = null;
    _isGenerating = true;
    notifyListeners();

    await WakelockPlus.enable();

    final assistantMsg = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );
    _messages.add(assistantMsg);
    notifyListeners();

    try {
      final service = OllamaService(_settings);
      final buffer = StringBuffer();
      DateTime lastNotify = DateTime.now();

      await for (final chunk in service.chatStream(
        history: _messages.sublist(0, _messages.length - 2),
        userMessage: text.trim(),
      )) {
        buffer.write(chunk);
        final now = DateTime.now();
        // Throttle UI updates – max ~12 razy na sekundę
        if (now.difference(lastNotify).inMilliseconds >= 80) {
          lastNotify = now;
          final idx = _messages.length - 1;
          _messages[idx] = assistantMsg.copyWith(
            content: buffer.toString(),
            isStreaming: true,
          );
          notifyListeners();
        }
      }

      // Finalna aktualizacja
      final idx = _messages.length - 1;
      _messages[idx] = assistantMsg.copyWith(
        content: buffer.toString(),
        isStreaming: false,
      );
    } catch (e) {
      _error = e.toString();
      if (_messages.isNotEmpty && _messages.last.isStreaming) {
        _messages.removeLast();
      }
    } finally {
      _isGenerating = false;
      await WakelockPlus.disable();
      notifyListeners();
    }
  }
}
