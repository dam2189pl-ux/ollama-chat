import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../services/chat_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _baseUrlCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _systemPromptCtrl;

  late int _numCtx;
  late int _numPredict;
  late double _temperature;
  late int _topK;
  late double _topP;
  late double _minP;
  late double _typicalP;
  late double _repetitionPenalty;
  late double _presencePenalty;
  late double _frequencyPenalty;

  bool _checking = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    final s = context.read<ChatProvider>().settings;
    _baseUrlCtrl = TextEditingController(text: s.baseUrl);
    _apiKeyCtrl = TextEditingController(text: s.apiKey);
    _modelCtrl = TextEditingController(text: s.model);
    _systemPromptCtrl = TextEditingController(text: s.systemPrompt);
    _numCtx = s.numCtx;
    _numPredict = s.numPredict;
    _temperature = s.temperature;
    _topK = s.topK;
    _topP = s.topP;
    _minP = s.minP;
    _typicalP = s.typicalP;
    _repetitionPenalty = s.repetitionPenalty;
    _presencePenalty = s.presencePenalty;
    _frequencyPenalty = s.frequencyPenalty;
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    _systemPromptCtrl.dispose();
    super.dispose();
  }

  AppSettings _buildSettings() {
    return AppSettings(
      baseUrl: _baseUrlCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      systemPrompt: _systemPromptCtrl.text,
      numCtx: _numCtx,
      numPredict: _numPredict,
      temperature: _temperature,
      topK: _topK,
      topP: _topP,
      minP: _minP,
      typicalP: _typicalP,
      repetitionPenalty: _repetitionPenalty,
      presencePenalty: _presencePenalty,
      frequencyPenalty: _frequencyPenalty,
    );
  }

  Future<void> _save() async {
    final provider = context.read<ChatProvider>();
    await provider.updateSettings(_buildSettings());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ustawienia zapisane'),
        backgroundColor: Color(0xFF10A37F),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _checking = true;
      _connectionStatus = null;
    });
    final provider = context.read<ChatProvider>();
    // Tymczasowo zastosuj bieżące wartości formularza
    await provider.updateSettings(_buildSettings());
    await provider.checkConnection();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _connectionStatus = provider.error ??
          'Połączenie OK – ${provider.availableModels.length} modeli';
    });
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String Function(double)? format,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Text(
              format != null ? format(value) : value.toStringAsFixed(2),
              style: TextStyle(color: Colors.greenAccent.shade200),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: const Color(0xFF10A37F),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final models = context.watch<ChatProvider>().availableModels;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Zapisz'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === API ===
          _sectionTitle('Połączenie z Ollama'),
          TextField(
            controller: _baseUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'Adres API (Base URL)',
              hintText: 'http://192.168.1.10:11434',
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyCtrl,
            decoration: const InputDecoration(
              labelText: 'Klucz API (opcjonalny)',
              hintText: 'Zostaw puste dla lokalnej Ollamy',
              prefixIcon: Icon(Icons.key),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),

          // Model – lista z serwera + ręczne wpisanie
          if (models.isNotEmpty) ...[
            const Text('Model (z serwera)', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: models.contains(_modelCtrl.text) ? _modelCtrl.text : null,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.model_training),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: Text(_modelCtrl.text.isEmpty ? 'Wybierz model' : _modelCtrl.text),
              items: models
                  .map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _modelCtrl.text = v);
                }
              },
            ),
            const SizedBox(height: 8),
            const Text('lub wpisz ręcznie:', style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 4),
          ],
          TextField(
            controller: _modelCtrl,
            decoration: const InputDecoration(
              labelText: 'Nazwa modelu',
              hintText: 'gemma3, llama3.2, mistral...',
              prefixIcon: Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _checking ? null : _testConnection,
            icon: _checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering),
            label: Text(_checking ? 'Sprawdzam...' : 'Sprawdź połączenie / odśwież modele'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10A37F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (_connectionStatus != null) ...[
            const SizedBox(height: 8),
            Text(
              _connectionStatus!,
              style: TextStyle(
                color: _connectionStatus!.startsWith('Połączenie OK')
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // === System prompt ===
          _sectionTitle('System Prompt'),
          TextField(
            controller: _systemPromptCtrl,
            decoration: const InputDecoration(
              labelText: 'System prompt',
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            minLines: 3,
          ),
          const SizedBox(height: 24),

          // === Context / generation ===
          _sectionTitle('Kontekst i długość odpowiedzi'),
          _slider(
            label: 'num_ctx (rozmiar kontekstu)',
            value: _numCtx.toDouble(),
            min: 1024,
            max: 32768,
            divisions: 31,
            format: (v) => v.round().toString(),
            onChanged: (v) => setState(() => _numCtx = v.round()),
          ),
          _slider(
            label: 'num_predict (max tokenów odpowiedzi)',
            value: _numPredict.toDouble(),
            min: 64,
            max: 4096,
            divisions: 63,
            format: (v) => v.round().toString(),
            onChanged: (v) => setState(() => _numPredict = v.round()),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gdy rozmowa jest długa i pojawia się „ucięcie” odpowiedzi – zwiększ num_ctx.\n'
            'Gdy model urywa zdanie w połowie – zwiększ num_predict.',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 24),

          // === Samplers ===
          _sectionTitle('Parametry samplera'),
          _slider(
            label: 'Temperature',
            value: _temperature,
            min: 0.0,
            max: 2.0,
            divisions: 40,
            onChanged: (v) => setState(() => _temperature = v),
          ),
          _slider(
            label: 'Top K',
            value: _topK.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            format: (v) => v.round().toString(),
            onChanged: (v) => setState(() => _topK = v.round()),
          ),
          _slider(
            label: 'Top P',
            value: _topP,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (v) => setState(() => _topP = v),
          ),
          _slider(
            label: 'Min P',
            value: _minP,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (v) => setState(() => _minP = v),
          ),
          _slider(
            label: 'Typical P',
            value: _typicalP,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (v) => setState(() => _typicalP = v),
          ),
          _slider(
            label: 'Repetition Penalty (repeat_penalty)',
            value: _repetitionPenalty,
            min: 0.5,
            max: 2.0,
            divisions: 30,
            onChanged: (v) => setState(() => _repetitionPenalty = v),
          ),
          _slider(
            label: 'Presence Penalty',
            value: _presencePenalty,
            min: -2.0,
            max: 2.0,
            divisions: 40,
            onChanged: (v) => setState(() => _presencePenalty = v),
          ),
          _slider(
            label: 'Frequency Penalty',
            value: _frequencyPenalty,
            min: -2.0,
            max: 2.0,
            divisions: 40,
            onChanged: (v) => setState(() => _frequencyPenalty = v),
          ),
          const SizedBox(height: 32),
          const Text(
            'Ustawienia (API, model, samplery, system prompt) są zapisywane na stałe.\n'
            'Rozmowa istnieje tylko w pamięci RAM – po zamknięciu aplikacji znika.\n'
            'Zero logów, zero telemetrii.',
            style: TextStyle(fontSize: 12, color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF10A37F),
        ),
      ),
    );
  }
}
