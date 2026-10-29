import 'package:flutter/material.dart';

class AppTheme {
  static const Color roxo = Color(0xFF7667E8);
  static const Color azul = Color(0xFF557FE0);
  static const Color verde = Color(0xFF18B68B);

  static const Color fundo = Color(0xFFF7F8FC);
  static const Color texto = Color(0xFF20242C);
  static const Color textoSecundario = Color(0xFF737987);

  static const LinearGradient gradientePrincipal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      roxo,
      azul,
      verde,
    ],
  );

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: fundo,

      colorScheme: ColorScheme.fromSeed(
        seedColor: roxo,
        primary: roxo,
        secondary: verde,
        surface: Colors.white,
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: texto,
        ),
        bodyMedium: TextStyle(
          color: texto,
        ),
        bodySmall: TextStyle(
          color: textoSecundario,
        ),
        titleLarge: TextStyle(
          color: texto,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: texto,
          fontWeight: FontWeight.w600,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: texto,
        elevation: 0,
        centerTitle: false,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE8EAF0),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: roxo,
            width: 1.5,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFFEBEDF2),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const superficie = Color(0xFF202333);
    const fundoEscuro = Color(0xFF121521);
    const borda = Color(0xFF34394A);
    const textoClaro = Color(0xFFF2F3FA);
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: fundoEscuro,
      colorScheme: ColorScheme.fromSeed(
        seedColor: roxo,
        brightness: Brightness.dark,
        primary: const Color(0xFFB0A5FF),
        secondary: verde,
        surface: superficie,
      ),
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: fundoEscuro,
        foregroundColor: textoClaro,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borda),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficie,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borda)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: roxo, width: 1.5)),
      ),
      dividerColor: borda,
      iconTheme: const IconThemeData(color: textoClaro),
      dialogTheme: const DialogThemeData(backgroundColor: superficie),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: superficie),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF34394A),
        contentTextStyle: TextStyle(color: textoClaro),
      ),
      listTileTheme: const ListTileThemeData(textColor: textoClaro, iconColor: textoClaro),
      textTheme: base.textTheme.apply(
        bodyColor: textoClaro, displayColor: textoClaro),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: superficie,
        selectedItemColor: Color(0xFFB0A5FF),
        unselectedItemColor: Color(0xFF9CA2B6),
      ),
    );
  }
}