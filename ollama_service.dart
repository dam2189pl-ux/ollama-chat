import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../models/settings.dart';

class OllamaService {
  final AppSettings settings;

  OllamaService(this.settings);

  Uri _uri(String path) {
    // Akceptuje zarówno http://host:11434 jak i http://host:11434/api
    var base = settings.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith('/api')) {
      base = base.substring(0, base.length - 4);
    }
    return Uri.parse('$base$path');
  }

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (settings.apiKey.isNotEmpty) {
      h['Authorization'] = 'Bearer ${settings.apiKey}';
    }
    return h;
  }

  /// Check connection to Ollama API (GET /api/tags)
  Future<({bool ok, String message, List<String> models})> checkConnection() async {
    try {
      final response = await http
          .get(_uri('/api/tags'), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final modelsList = (data['models'] as List<dynamic>?)
                ?.map((m) => (m as Map)['name'] as String? ?? '')
                .where((n) => n.isNotEmpty)
                .toList() ??
            [];
        return (
          ok: true,
          message: 'Połączono! Znaleziono ${modelsList.length} modeli.',
          models: modelsList,
        );
      } else {
        return (
          ok: false,
          message: 'Błąd HTTP ${response.statusCode}: ${response.body}',
          models: <String>[],
        );
      }
    } on TimeoutException {
      return (ok: false, message: 'Timeout – sprawdź adres API i czy Ollama działa.', models: <String>[]);
    } catch (e) {
      return (ok: false, message: 'Błąd połączenia: $e', models: <String>[]);
    }
  }

  /// Stream chat completion from /api/chat
  Stream<String> chatStream({
    required List<ChatMessage> history,
    required String userMessage,
  }) async* {
    final messages = <Map<String, dynamic>>[];

    // System prompt first (if set)
    if (settings.systemPrompt.trim().isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': settings.systemPrompt.trim(),
      });
    }

    // History (only user + assistant)
    for (final m in history) {
      if (m.role == MessageRole.user || m.role == MessageRole.assistant) {
        messages.add(m.toApiJson());
      }
    }

    // Current user message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    final body = {
      'model': settings.model,
      'messages': messages,
      'stream': true,
      'options': settings.toOptionsJson(),
    };

    final request = http.Request('POST', _uri('/api/chat'));
    request.headers.addAll(_headers);
    request.body = jsonEncode(body);

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Timeout przy starcie requestu'),
          );

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('HTTP ${streamedResponse.statusCode}: $errorBody');
      }

      // Ollama streams NDJSON lines
      await for (final chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (chunk.trim().isEmpty) continue;
        try {
          final json = jsonDecode(chunk) as Map<String, dynamic>;
          final message = json['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String? ?? '';
          final done = json['done'] as bool? ?? false;

          if (content.isNotEmpty) {
            yield content;
          }

          if (done) break;
        } catch (_) {
          // ignore malformed lines
        }
      }
    } finally {
      client.close();
    }
  }
}
