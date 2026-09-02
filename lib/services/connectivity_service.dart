import 'package:connectivity_plus/connectivity_plus.dart';

/// Consulta de conectividade isolada em uma classe para facilitar os testes.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity}) : _injected = connectivity;

  final Connectivity? _injected;

  // Criado sob demanda: quem substitui [isOnline] nunca toca no plugin.
  late final Connectivity _connectivity = _injected ?? Connectivity();

  /// Só retorna `false` quando o sistema afirma que não existe rede.
  ///
  /// Em desktop a consulta pode falhar ou responder de forma imprecisa; nesse
  /// caso seguimos com a requisição e deixamos o próprio HTTP decidir.
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (_) {
      return true;
    }
  }
}
