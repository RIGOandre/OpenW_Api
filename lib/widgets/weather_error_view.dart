import 'package:flutter/material.dart';

/// Tela de erro com botão de nova tentativa.
///
/// O nome leva o prefixo `Weather` porque `ErrorWidget` já existe no Flutter e
/// é reexportado por `material.dart`: com o nome curto, todo arquivo que
/// importasse os dois precisaria de prefixo.
class WeatherErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  /// Ícone e título mudam conforme o tipo do erro; os padrões valem para o
  /// caso genérico.
  final IconData icon;
  final String title;

  const WeatherErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline,
    this.title = 'Oops!',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      // Em janela baixa (desktop e web, onde travar a orientação não tem
      // efeito) a coluna estoura e o botão fica pintado fora do pai, visível
      // mas sem responder ao toque. Com o scroll ele continua alcançável.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
