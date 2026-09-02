import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/formatters.dart';
import '../utils/weather_assets.dart';

class ForecastWidget extends StatelessWidget {
  final List<DailyForecast> forecast;

  /// Hora atual na cidade consultada. Sem ela os rótulos "Hoje" e "Amanhã"
  /// caem no relógio do aparelho, que pode estar em outro fuso.
  final DateTime? reference;

  const ForecastWidget({
    super.key,
    required this.forecast,
    this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Previsão para os próximos dias',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildForecastList(),
        ],
      ),
    );
  }

  Widget _buildForecastList() {
    if (forecast.isEmpty) {
      return Text(
        'Previsão indisponível para esta cidade',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 14,
        ),
      );
    }

    return Column(
      children: forecast.map(_buildDayRow).toList(),
    );
  }

  Widget _buildDayRow(DailyForecast dayForecast) {
    final description = WeatherUtils.capitalizeFirst(dayForecast.description);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Data
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  WeatherDateUtils.getRelativeDay(
                    dayForecast.date,
                    reference: reference,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  WeatherDateUtils.formatDate(dayForecast.date),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Ícone do tempo
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(
              // forCondition troca a animação por chuva forte quando o código
              // da condição indica temporal, o que o ícone sozinho não diz.
              WeatherAssets.forCondition(
                dayForecast.icon,
                dayForecast.conditionId,
              ),
              fit: BoxFit.contain,
              semanticLabel: description.isEmpty ? null : description,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.wb_sunny,
                  color: Colors.orange[300],
                  size: 24,
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          // Temperaturas
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _buildValueCell(
                  value: TemperatureUtils.formatTemperature(dayForecast.tempMin),
                  label: 'Min',
                  valueStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                _buildValueCell(
                  value: TemperatureUtils.formatTemperature(dayForecast.tempMax),
                  label: 'Max',
                  valueStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                _buildValueCell(
                  value: WeatherUtils.formatRainChance(dayForecast.rainChance),
                  label: 'Chuva',
                  valueStyle: TextStyle(
                    color: Colors.blue[200],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCell({
    required String value,
    required String label,
    required TextStyle valueStyle,
  }) {
    return Expanded(
      child: Column(
        children: [
          // A célula fica com pouco mais de 25dp em tela estreita e "100%" não
          // tem onde quebrar: sem o scaleDown o texto sairia recortado.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: valueStyle,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
