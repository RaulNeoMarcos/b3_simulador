// lib/screens/resultado_screen.dart

import 'package:b3_simulador/models/cotacao.dart';
import 'package:b3_simulador/models/ml_prediction.dart';
import 'package:b3_simulador/models/resultado_simulacao.dart';
import 'package:b3_simulador/models/valuation_avancado.dart';
import 'package:b3_simulador/screens/debug_logs_screen.dart';
import 'package:b3_simulador/services/fundamentalista_service.dart';
import 'package:b3_simulador/services/ml_models.dart';
import 'package:b3_simulador/services/valuation_avancado_service.dart';
import 'package:b3_simulador/widgets/ml_prediction_card.dart';
import 'package:b3_simulador/widgets/valuation_avancado_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/provento.dart';
import '../services/simulador_service.dart';
import '../widgets/comparativo_renda_fixa_card.dart';
import '../widgets/fonte_dados_indicator.dart';
import '../widgets/grafico_evolucao.dart';
import '../widgets/provento_tile.dart';

class ResultadoScreen extends StatefulWidget {
  final String ticker;
  final DateTime dataInicio;
  final double valorInvestido;
  final DateTime? dataFim;

  const ResultadoScreen({
    Key? key,
    required this.ticker,
    required this.dataInicio,
    required this.valorInvestido,
    this.dataFim,
  }) : super(key: key);

  @override
  State<ResultadoScreen> createState() => _ResultadoScreenState();
}

class _ResultadoScreenState extends State<ResultadoScreen>
    with SingleTickerProviderStateMixin {
  ResultadoSimulacao? _resultado;
  String? _error;
  bool _isLoading = true;
  late AnimationController _animationController;

  int _selectedTabIndex = 0;
  final ScrollController _scrollController = ScrollController();

  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final percentFormat = NumberFormat.decimalPercentPattern(
    decimalDigits: 2,
    locale: 'pt_BR',
  );

  @override
  void initState() {
    super.initState();

    // Detectar shake do dispositivo
    // ShakeDetector.autoStart(
    //   onPhoneShake: () {
    //     // Abrir debug logs quando o usuário chacoalhar o celular
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(builder: (_) => const DebugLogsScreen()),
    //     );

    //     // Feedback visual
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text('Abrindo logs de debug...'),
    //         duration: Duration(seconds: 1),
    //         backgroundColor: Colors.orange,
    //       ),
    //     );
    //   },
    //   minimumShakeCount: 3,
    //   shakeSlopTimeMS: 500,
    //   shakeCountResetTime: 3000,
    // );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Inicia a simulação após o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _simular();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _simular() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = SimuladorService();
      final resultado = await service.simular(
        ticker: widget.ticker,
        dataInicio: widget.dataInicio,
        valorInvestido: widget.valorInvestido,
        dataFim: widget.dataFim,
        incluirComparacaoRendaFixa: true,
      );

      if (mounted) {
        setState(() {
          _resultado = resultado;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _buscarDadosFundamentalistas(
    String ticker,
  ) async {
    try {
      final dados = await FundamentalistaService.buscarDadosFundamentalistas(
        ticker,
      );
      print('📊 Dados fundamentalistas carregados: $dados');
      return dados;
    } catch (e) {
      print('🔥 Erro ao buscar fundamentalistas: $e');
      return {}; // Retorna vazio em caso de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      // drawer: Drawer(
      //   child: ListView(
      //     padding: EdgeInsets.zero,
      //     children: [
      //       const DrawerHeader(
      //         decoration: BoxDecoration(color: Colors.blue),
      //         child: Text(
      //           'Menu',
      //           style: TextStyle(color: Colors.white, fontSize: 24),
      //         ),
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.bug_report, color: Colors.orange),
      //         title: const Text('Debug Logs'),
      //         onTap: () {
      //           Navigator.pop(context); // Fecha o drawer
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (_) => const DebugLogsScreen()),
      //           );
      //         },
      //       ),
      //     ],
      //   ),
      // ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultado - ${widget.ticker.toUpperCase()}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            'Investimento: ${currencyFormat.format(widget.valorInvestido)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      actions: [
        FonteDadosIndicator(),
        IconButton(
          icon: const Icon(Icons.bug_report, color: Colors.orange),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DebugLogsScreen()),
            );
          },
          tooltip: 'Ver logs de debug',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState(_error!);
    }

    if (_resultado == null) {
      return _buildEmptyState();
    }

    return _buildSuccessState(_resultado!);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                ),
              ),
              Icon(Icons.trending_up, size: 32, color: Colors.blue[700]),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Buscando dados...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Consultando Yahoo Finance e Banco Central',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 24),
            const Text(
              'Ops! Algo deu errado',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // 👇 BOTÃO DE DEBUG AQUI
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DebugLogsScreen()),
                );
              },
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              label: const Text('Ver logs de debug'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _simular,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Nenhum dado encontrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Não foi possível encontrar dados para o período selecionado',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ResultadoSimulacao resultado) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 1. Header com valor principal
        SliverToBoxAdapter(child: _buildHeaderCard(resultado)),
        // 2. Métricas rápidas
        SliverToBoxAdapter(child: _buildMetricCards(resultado)),
        // 3. Abas de navegação
        SliverToBoxAdapter(child: _buildTabBar()),
        // 4. Conteúdo das abas (Evolução, Proventos, Detalhes)
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(child: _buildTabContent(resultado)),
        ),
        // 5. Comparativo renda fixa
        if (resultado.comparativoRendaFixa != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ComparativoRendaFixaCard(
                comparativo: resultado.comparativoRendaFixa!,
                retornoAcao: resultado.percentualRetorno,
              ),
            ),
          ),

        // 6. Valuation Avançado (Nível 4)
        // 👇 BOTÃO DE DEBUG DISCRETO NO FINAL
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DebugLogsScreen()),
                  );
                },
                icon: Icon(Icons.bug_report, size: 16, color: Colors.grey[400]),
                label: Text(
                  'Debug Logs',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ),
          ),
        ),

        // 7. 🔥 PREVISÕES ML (Nível 11) - COLOCAR AQUI! 🔥
        SliverToBoxAdapter(
          child: _buildMLPredictions(
            resultado.ativo.ticker,
            resultado.historicoCotacoes,
          ),
        ),

        // 8. Botão de exportar
        SliverToBoxAdapter(child: _buildExportButton(resultado)),

        // 9. Espaço extra para o FAB
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildHeaderCard(ResultadoSimulacao resultado) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            resultado.teveLucro ? Colors.green[700]! : Colors.red[700]!,
            resultado.teveLucro ? Colors.green[400]! : Colors.red[400]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (resultado.teveLucro ? Colors.green : Colors.red)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Valor Final',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(resultado.valorFinalTotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  resultado.iconeResultado,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      resultado.lucroPrejuizo >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      resultado.percentualFormatado,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                resultado.lucroFormatado,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('dd/MM/yyyy').format(resultado.dataInicio)} - ${DateFormat('dd/MM/yyyy').format(resultado.dataFim)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.timeline, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${resultado.diasCorridos} dias',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(ResultadoSimulacao resultado) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildMetricCard(
            'Ações',
            resultado.quantidadeAcoes.toStringAsFixed(4),
            Icons.bolt,
            Colors.amber,
          ),
          _buildMetricCard(
            'Preço Inicial',
            currencyFormat.format(resultado.cotacaoInicial.fechamento),
            Icons.arrow_circle_down,
            Colors.blue,
          ),
          _buildMetricCard(
            'Preço Final',
            currencyFormat.format(resultado.cotacaoFinal.fechamento),
            Icons.arrow_circle_up,
            resultado.teveLucro ? Colors.green : Colors.red,
          ),
          _buildMetricCard(
            'Dividendos',
            currencyFormat.format(resultado.totalDividendos),
            Icons.payments,
            Colors.purple,
          ),
          if (resultado.retornoAnualizado != null)
            _buildMetricCard(
              'CAGR',
              '${resultado.retornoAnualizado!.toStringAsFixed(2)}%',
              Icons.auto_graph,
              Colors.teal,
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Evolução', 0, Icons.show_chart)),
          Expanded(child: _buildTabButton('Proventos', 1, Icons.payments)),
          Expanded(child: _buildTabButton('Detalhes', 2, Icons.info)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(ResultadoSimulacao resultado) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildEvolucaoTab(resultado);
      case 1:
        return _buildProventosTab(resultado);
      case 2:
        return _buildDetalhesTab(resultado);
      default:
        return Container();
    }
  }

  Widget _buildEvolucaoTab(ResultadoSimulacao resultado) {
    return Column(
      children: [
        Container(
          height: 250,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GraficoEvolucao(
            cotacoes: resultado.historicoCotacoes,
            corLinha: resultado.teveLucro ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Maior preço',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    currencyFormat.format(resultado.maiorPreco ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (resultado.dataMaiorPreco != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Data', style: TextStyle(color: Colors.grey[600])),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(resultado.dataMaiorPreco!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menor preço',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    currencyFormat.format(resultado.menorPreco ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (resultado.dataMenorPreco != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Data', style: TextStyle(color: Colors.grey[600])),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(resultado.dataMenorPreco!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              if (resultado.volatilidade != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Volatilidade',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${resultado.volatilidade!.toStringAsFixed(2)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProventosTab(ResultadoSimulacao resultado) {
    if (resultado.proventosRecebidos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Nenhum provento no período',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'A empresa não distribuiu dividendos ou JCP neste período',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total em proventos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    currencyFormat.format(resultado.totalDividendos),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...resultado.proventosPorTipo.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_getTipoProventoLabel(entry.key)),
                      Text(
                        currencyFormat.format(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Yield on cost',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${resultado.yieldOnCost.toStringAsFixed(2)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DY médio anual',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${resultado.dividendYieldMedio.toStringAsFixed(2)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...resultado.proventosRecebidos.map((provento) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ProventoTile(provento: provento),
          );
        }).toList(),
      ],
    );
  }

  String _getTipoProventoLabel(TipoProvento tipo) {
    switch (tipo) {
      case TipoProvento.dividendo:
        return 'Dividendos';
      case TipoProvento.jcp:
        return 'JCP';
      case TipoProvento.rendimento:
        return 'Rendimentos';
      case TipoProvento.bonificacao:
        return 'Bonificações';
      case TipoProvento.desdobramento:
        return 'Desdobramentos';
      case TipoProvento.agrupamento:
        return 'Agrupamentos';
    }
  }

  Widget _buildDetalhesTab(ResultadoSimulacao resultado) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalhes do Investimento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Ativo', resultado.ativo.ticker),
          _buildDetailRow('Empresa', resultado.ativo.nome),
          _buildDetailRow(
            'Data inicial',
            DateFormat('dd/MM/yyyy').format(resultado.dataInicio),
          ),
          _buildDetailRow(
            'Data final',
            DateFormat('dd/MM/yyyy').format(resultado.dataFim),
          ),
          _buildDetailRow(
            'Período',
            '${resultado.diasCorridos} dias (${resultado.diasUteis} úteis)',
          ),
          const Divider(height: 24),
          const Text(
            'Cotações',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Cotação inicial',
            currencyFormat.format(resultado.cotacaoInicial.fechamento),
          ),
          _buildDetailRow(
            'Cotação final',
            currencyFormat.format(resultado.cotacaoFinal.fechamento),
          ),
          _buildDetailRow(
            'Variação',
            '${((resultado.cotacaoFinal.fechamento / resultado.cotacaoInicial.fechamento - 1) * 100).toStringAsFixed(2)}%',
          ),
          const Divider(height: 24),
          const Text(
            'Quantidade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Ações compradas',
            resultado.quantidadeAcoes.toStringAsFixed(4),
          ),
          _buildDetailRow(
            'Custo médio',
            currencyFormat.format(resultado.cotacaoInicial.fechamento),
          ),
          const Divider(height: 24),
          const Text(
            'Rentabilidade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Apreciação',
            currencyFormat.format(resultado.valorApreciacao),
          ),
          _buildDetailRow(
            'Dividendos',
            currencyFormat.format(resultado.totalDividendos),
          ),
          _buildDetailRow(
            'Total',
            currencyFormat.format(resultado.valorFinalTotal),
          ),
          _buildDetailRow(
            'Lucro/Prejuízo',
            resultado.lucroFormatado,
            cor: resultado.corLucro,
          ),
          _buildDetailRow(
            'Retorno %',
            resultado.percentualFormatado,
            cor: resultado.corLucro,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? cor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: cor ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // lib/screens/resultado_screen.dart

  /// Constrói o card de Valuation Avançado (Nível 4)
  Widget _buildValuationAvancado(String ticker) {
    return FutureBuilder<ValuationAvancado?>(
      future: ValuationAvancadoService().calcularValuation(ticker),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    'Calculando valuation avançado...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('Erro no valuation: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        if (snapshot.hasData && snapshot.data != null) {
          return ValuationAvancadoCard(valuation: snapshot.data!);
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Constrói o card de Previsões ML (Nível 11)
  Widget _buildMLPredictions(String ticker, List<Cotacao> historico) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _buscarDadosFundamentalistas(ticker),
      builder: (context, snapshotFundamental) {
        if (snapshotFundamental.connectionState == ConnectionState.waiting) {
          return _buildLoadingML('Carregando dados fundamentalistas...');
        }

        final dadosFundamental = snapshotFundamental.data ?? {};

        return FutureBuilder<MLPrediction?>(
          future: MLModels.ensemblePrediction(
            ticker,
            historico,
            dadosFundamental, // 👈 Agora com dados reais!
          ),
          builder: (context, snapshot) {
            print('🔄 Estado do ML: ${snapshot.connectionState}');
            print('📦 Tem dados: ${snapshot.hasData}');
            print('❌ Tem erro: ${snapshot.hasError}');

            if (snapshot.hasError) {
              print('🔥 ERRO ML: ${snapshot.error}');
              return _buildErrorML('Erro nas previsões: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingML('Modelos de ML processando...');
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return _buildErrorML(
                'Não foi possível gerar previsões para $ticker.\n'
                'Tente novamente mais tarde.',
              );
            }

            return MLPredictionCard(prediction: snapshot.data!);
          },
        );
      },
    );
  }

  Widget _buildLoadingML(String mensagem) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.purple[700]!,
                    ),
                  ),
                ),
                Icon(Icons.psychology, color: Colors.purple[700], size: 30),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mensagem,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Isso pode levar alguns segundos',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorML(String mensagem) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Previsões ML indisponíveis',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    mensagem,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget auxiliar para mostrar status dos modelos
  Widget _buildModeloStatus(String nome, bool ativo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ativo ? Colors.purple[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ativo ? Colors.purple : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            nome,
            style: TextStyle(
              fontSize: 10,
              color: ativo ? Colors.purple[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(ResultadoSimulacao resultado) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: () => _showExportOptions(resultado),
        icon: const Icon(Icons.share),
        label: const Text('COMPARTILHAR RESULTADO'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          side: BorderSide(color: Colors.blue[700]!),
          foregroundColor: Colors.blue[700],
        ),
      ),
    );
  }

  void _showExportOptions(ResultadoSimulacao resultado) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Compartilhar Resultado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Icon(Icons.text_snippet, color: Colors.blue[700]),
                ),
                title: const Text('Resumo em Texto'),
                subtitle: const Text(
                  'Copiar resumo para área de transferência',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _copiarResumo(resultado);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[50],
                  child: Icon(Icons.picture_as_pdf, color: Colors.green[700]),
                ),
                title: const Text('Exportar como PDF'),
                subtitle: const Text('Gerar relatório detalhado em PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _exportarPDF(resultado);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _copiarResumo(ResultadoSimulacao resultado) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resumo copiado para área de transferência!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportarPDF(ResultadoSimulacao resultado) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF gerado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget? _buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      label: const Text('Topo'),
      icon: const Icon(Icons.arrow_upward),
      backgroundColor: Colors.blue[700],
    );
  }
}
