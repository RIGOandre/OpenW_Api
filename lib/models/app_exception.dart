/// Tipos de falha que a aplicação sabe tratar e explicar para o usuário.
enum AppErrorType {
  offline,
  timeout,
  network,
  notFound,
  unauthorized,
  server,
  database,
  configuration,
  unknown,
}

/// Erro de domínio com a mensagem já pronta para ser exibida na tela.
///
/// Diferente de `Exception`, o `toString()` devolve apenas a mensagem, evitando
/// textos empilhados como "Exception: Erro ao buscar: Exception: ...".
class AppException implements Exception {
  const AppException(
    this.message, {
    this.type = AppErrorType.unknown,
    this.cause,
  });

  const AppException.offline()
      : this(
          'Sem conexão com a internet',
          type: AppErrorType.offline,
        );

  const AppException.timeout()
      : this(
          'O servidor demorou demais para responder',
          type: AppErrorType.timeout,
        );

  const AppException.unauthorized()
      : this(
          'Chave da API inválida ou ainda não ativada',
          type: AppErrorType.unauthorized,
        );

  const AppException.missingApiKey()
      : this(
          'Configure a chave da OpenWeatherMap para carregar o clima',
          type: AppErrorType.configuration,
        );

  AppException.notFound(String city)
      : this(
          'Não encontramos "$city". Confira o nome da cidade.',
          type: AppErrorType.notFound,
        );

  AppException.server(int statusCode)
      : this(
          'O servidor respondeu com erro ($statusCode)',
          type: AppErrorType.server,
        );

  AppException.database(Object cause)
      : this(
          'Falha ao acessar os dados salvos no dispositivo',
          type: AppErrorType.database,
          cause: cause,
        );

  /// Mensagem exibida ao usuário.
  final String message;

  /// Categoria da falha, usada para escolher ícone, texto e fallback de cache.
  final AppErrorType type;

  /// Erro original, mantido apenas para depuração.
  final Object? cause;

  /// Envolve qualquer erro inesperado sem perder a mensagem original.
  static AppException from(Object error, {String? message}) {
    if (error is AppException) return error;
    return AppException(
      message ?? 'Algo deu errado. Tente novamente.',
      cause: error,
    );
  }

  @override
  String toString() => message;
}
