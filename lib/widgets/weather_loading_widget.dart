import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class WeatherLoadingWidget extends StatelessWidget {
  const WeatherLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Um Shimmer por grupo, e não um por bloco: são três controladores de
          // animação no lugar de doze, e o brilho varre o grupo inteiro em vez
          // de piscar cada bloco no seu próprio ritmo.
          _buildShimmer(
            child: Column(
              children: [
                // Temperatura
                _buildBlock(width: 200, height: 80, borderRadius: 16),
                const SizedBox(height: 16),

                // Descrição
                _buildBlock(width: 150, height: 24, borderRadius: 12),
                const SizedBox(height: 24),

                // Ícone do tempo
                _buildBlock(width: 100, height: 100, borderRadius: 50),
                const SizedBox(height: 24),

                // Localização
                _buildBlock(width: 180, height: 20, borderRadius: 10),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Previsão dos próximos dias.
          // O analisador acusa avoid_unnecessary_containers aqui, mas este
          // Container carrega padding e decoration: tirar ele apaga o fundo e o
          // respiro do cartão. Falso positivo, conferido removendo uma
          // propriedade de cada vez e vendo o aviso continuar igual.
          // ignore: avoid_unnecessary_containers
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[700]!.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            // O Shimmer fica dentro do cartão para o fundo azul não entrar na
            // máscara do brilho e virar mais um bloco branco.
            child: _buildShimmer(
              child: Column(
                children: [
                  _buildBlock(width: 200, height: 20, borderRadius: 10),
                  const SizedBox(height: 16),
                  ...List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBlock(width: 60, height: 16, borderRadius: 8),
                          _buildBlock(width: 40, height: 16, borderRadius: 8),
                          _buildBlock(width: 40, height: 16, borderRadius: 8),
                          _buildBlock(width: 40, height: 16, borderRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cartões de informação
          _buildShimmer(
            child: Row(
              children: List.generate(3, (index) => _buildInfoPlaceholder()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.3),
      highlightColor: Colors.white.withValues(alpha: 0.5),
      child: child,
    );
  }

  /// Coluna de um cartão de informação.
  ///
  /// A largura é fração da célula, e não um valor fixo: em janela estreita de
  /// desktop três blocos de 80 não cabem lado a lado.
  Widget _buildInfoPlaceholder() {
    return Expanded(
      child: Column(
        children: [
          FractionallySizedBox(
            widthFactor: 0.65,
            child: _buildBlock(height: 20, borderRadius: 10),
          ),
          const SizedBox(height: 8),
          FractionallySizedBox(
            widthFactor: 0.88,
            child: _buildBlock(height: 16, borderRadius: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildBlock({
    double width = double.infinity,
    required double height,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
