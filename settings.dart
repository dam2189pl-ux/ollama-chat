class AppSettings {
  String baseUrl;
  String apiKey;
  String model;
  String systemPrompt;

  // Context / generation limits
  int numCtx;
  int numPredict;

  // Samplers
  double temperature;
  int topK;
  double topP;
  double minP;
  double typicalP;
  double repetitionPenalty; // maps to repeat_penalty
  double presencePenalty;
  double frequencyPenalty;

  AppSettings({
    this.baseUrl = 'http://localhost:11434',
    this.apiKey = '',
    this.model = 'llama3.2',
    this.systemPrompt =
        'Jesteś pomocnym asystentem AI. Odpowiadaj po polsku, chyba że użytkownik napisze inaczej.',
    this.numCtx = 4096,
    this.numPredict = 1024,
    this.temperature = 0.8,
    this.topK = 40,
    this.topP = 0.9,
    this.minP = 0.0,
    this.typicalP = 1.0,
    this.repetitionPenalty = 1.1,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
  });

  Map<String, dynamic> toOptionsJson() {
    return {
      'num_ctx': numCtx,
      'num_predict': numPredict,
      'temperature': temperature,
      'top_k': topK,
      'top_p': topP,
      'min_p': minP,
      'typical_p': typicalP,
      'repeat_penalty': repetitionPenalty,
      'presence_penalty': presencePenalty,
      'frequency_penalty': frequencyPenalty,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'systemPrompt': systemPrompt,
      'numCtx': numCtx,
      'numPredict': numPredict,
      'temperature': temperature,
      'topK': topK,
      'topP': topP,
      'minP': minP,
      'typicalP': typicalP,
      'repetitionPenalty': repetitionPenalty,
      'presencePenalty': presencePenalty,
      'frequencyPenalty': frequencyPenalty,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      baseUrl: json['baseUrl'] as String? ?? 'http://localhost:11434',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? 'llama3.2',
      systemPrompt: json['systemPrompt'] as String? ??
          'Jesteś pomocnym asystentem AI. Odpowiadaj po polsku, chyba że użytkownik napisze inaczej.',
      numCtx: json['numCtx'] as int? ?? 4096,
      numPredict: json['numPredict'] as int? ?? 1024,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.8,
      topK: json['topK'] as int? ?? 40,
      topP: (json['topP'] as num?)?.toDouble() ?? 0.9,
      minP: (json['minP'] as num?)?.toDouble() ?? 0.0,
      typicalP: (json['typicalP'] as num?)?.toDouble() ?? 1.0,
      repetitionPenalty: (json['repetitionPenalty'] as num?)?.toDouble() ?? 1.1,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
    );
  }

  AppSettings copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    String? systemPrompt,
    int? numCtx,
    int? numPredict,
    double? temperature,
    int? topK,
    double? topP,
    double? minP,
    double? typicalP,
    double? repetitionPenalty,
    double? presencePenalty,
    double? frequencyPenalty,
  }) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      numCtx: numCtx ?? this.numCtx,
      numPredict: numPredict ?? this.numPredict,
      temperature: temperature ?? this.temperature,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      minP: minP ?? this.minP,
      typicalP: typicalP ?? this.typicalP,
      repetitionPenalty: repetitionPenalty ?? this.repetitionPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
    );
  }
}
