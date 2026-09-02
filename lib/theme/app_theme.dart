import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta e tema compartilhados por toda a aplicação.
class AppTheme {
  const AppTheme._();

  static const Color deepBlue = Color(0xFF1E3A8A);
  static const Color appBarBlue = Color(0xFF1E40AF);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color night = Color(0xFF0F172A);
  static const Color nightSoft = Color(0xFF1E293B);

  static ThemeData build() {
    return ThemeData(
      // Já é o padrão do Flutter desde a 3.16; aqui só fica explícito.
      useMaterial3: true,
      primarySwatch: Colors.blue,
      textTheme: GoogleFonts.poppinsTextTheme(),
      scaffoldBackgroundColor: deepBlue,
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Fundo da tela, mais escuro durante a noite.
  static LinearGradient background({required bool isDay}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDay
          ? const <Color>[deepBlue, accentBlue]
          : const <Color>[night, nightSoft],
    );
  }

  /// Gradiente da barra superior.
  static LinearGradient get appBar => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Colors.blue.shade800, Colors.blue.shade600],
      );

  /// Gradiente do menu lateral.
  static LinearGradient get drawer => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Colors.blue.shade800, Colors.blue.shade600],
      );

  /// Gradiente do cabeçalho do menu lateral.
  static LinearGradient get drawerHeader => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Colors.blue.shade900, Colors.blue.shade700],
      );

  /// Cartão translúcido usado sobre o gradiente de fundo.
  static BoxDecoration glassCard({double radius = 16}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
    );
  }
}
