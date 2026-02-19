// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/resultado_screen.dart';

// Services
import 'services/yahoo_finance_service.dart';
import 'services/dados_historicos_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializa o sistema de internacionalização para português
    await initializeDateFormatting('pt_BR', null);

    // Configura o locale padrão
    Intl.defaultLocale = 'pt_BR';

    print('✅ Sistema de formatação de datas inicializado com sucesso');
  } catch (e) {
    print('⚠️ Erro ao inicializar formatação de datas: $e');
    // Fallback para inglês
    Intl.defaultLocale = 'en_US';
  }

  // Inicializa o app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Providers para gerenciamento de estado
        ChangeNotifierProvider(create: (_) => SimulacaoProvider()),

        // Providers singleton para serviços
        Provider(create: (_) => YahooFinanceService()),
        Provider(create: (_) => DadosHistoricosService()),
      ],
      child: MaterialApp(
        title: 'Simulador B3',
        debugShowCheckedModeBanner: false,

        // Configuração de localização
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // Tema claro
        theme: _buildLightTheme(),

        // Tema escuro (opcional)
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system, // Usa a preferência do sistema
        // Rotas do app
        initialRoute: '/',
        routes: {'/': (context) => const HomeScreen()},
        onGenerateRoute: _onGenerateRoute,

        // Tratamento de erros
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: true, overscroll: false),
            child: child!,
          );
        },
      ),
    );
  }

  /// Configura o tema claro do app
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Cores principais
      primaryColor: const Color(0xFF1E3A8A),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1E3A8A),
        secondary: Color(0xFF10B981),
        error: Color(0xFFEF4444),
        surface: Colors.white,
        background: Color(0xFFF3F4F6),
      ),

      scaffoldBackgroundColor: const Color(0xFFF3F4F6),

      // AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2937),
        titleTextStyle: TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),

      // Botões elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Botões outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1E3A8A),
          side: const BorderSide(color: Color(0xFF1E3A8A)),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),

      // Tipografia
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.copyWith(
          headlineLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          headlineMedium: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFF4B5563)),
          bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey[200],
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Configura o tema escuro do app
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      primaryColor: const Color(0xFF3B82F6),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6),
        secondary: Color(0xFF10B981),
        error: Color(0xFFEF4444),
        surface: Color(0xFF1F2937),
        background: Color(0xFF111827),
      ),

      scaffoldBackgroundColor: const Color(0xFF111827),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFF1F2937),
        foregroundColor: Colors.white,
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF1F2937),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey[400]),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),

      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          headlineLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFFD1D5DB)),
        ),
      ),
    );
  }

  /// Gera rotas dinâmicas com parâmetros
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    if (settings.name == '/resultado') {
      final args = settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        return MaterialPageRoute(
          builder: (context) => ResultadoScreen(
            ticker: args['ticker'] ?? '',
            dataInicio: args['dataInicio'] ?? DateTime.now(),
            valorInvestido: (args['valorInvestido'] ?? 0).toDouble(),
            dataFim: args['dataFim'],
          ),
        );
      }
    }

    return null;
  }
}

/// Classe para gerenciar o estado da simulação (Provider)
class SimulacaoProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    _error = null;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Extensão para facilitar a navegação
extension NavigationExtension on BuildContext {
  void navigateToResultado({
    required String ticker,
    required DateTime dataInicio,
    required double valorInvestido,
    DateTime? dataFim,
  }) {
    Navigator.pushNamed(
      this,
      '/resultado',
      arguments: {
        'ticker': ticker,
        'dataInicio': dataInicio,
        'valorInvestido': valorInvestido,
        'dataFim': dataFim,
      },
    );
  }
}
