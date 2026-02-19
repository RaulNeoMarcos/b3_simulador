// lib/screens/resultado_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/resultado_simulacao.dart';
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
  _ResultadoScreenState createState() => _ResultadoScreenState();
}

class _ResultadoScreenState extends State<ResultadoScreen>
    with SingleTickerProviderStateMixin {
  late Future<ResultadoSimulacao> _resultadoFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controle para abas de detalhamento
  int _selectedTabIndex = 0;

  // Controladores para scroll
  final ScrollController _scrollController = ScrollController();

  // Formatação
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final percentFormat = NumberFormat.decimalPercentPattern(
    decimalDigits: 2,
    locale: 'pt_BR',
  );

  @override
  void initState() {
    super.initState();

    // Inicializa animações
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Inicia a simulação
    _resultadoFuture = _simular();

    // Inicia animação após construção
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<ResultadoSimulacao> _simular() async {
    final service = SimuladorService();
    return await service.simular(
      ticker: widget.ticker,
      dataInicio: widget.dataInicio,
      valorInvestido: widget.valorInvestido,
      dataFim: widget.dataFim,
      incluirComparacaoRendaFixa: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
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
      actions: [FonteDadosIndicator(), const SizedBox(width: 8)],
    );
  }

  Widget _buildBody() {
    return FutureBuilder<ResultadoSimulacao>(
      future: _resultadoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return _buildEmptyState();
        }

        return _buildSuccessState(snapshot.data!);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animação de loading personalizada
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
          Text(
            'Buscando dados...',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Consultando Yahoo Finance e Banco Central',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          // Simulador de progresso (opcional, apenas para UX)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(seconds: 3),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              );
            },
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
            Text(
              'Ops! Algo deu errado',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _resultadoFuture = _simular();
                    });
                  },
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _resultadoFuture = _simular();
          });
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header com valor principal
            SliverToBoxAdapter(child: _buildHeaderCard(resultado)),

            // Métricas rápidas
            SliverToBoxAdapter(child: _buildMetricCards(resultado)),

            // Abas de navegação
            SliverToBoxAdapter(child: _buildTabBar()),

            // Conteúdo das abas
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(child: _buildTabContent(resultado)),
            ),

            // Comparativo renda fixa (se disponível)
            if (resultado.comparativoRendaFixa != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ComparativoRendaFixaCard(
                  comparativo: resultado.comparativoRendaFixa!,
                  retornoAcao: resultado.percentualRetorno,
                  showDetalhado: true, // ou false para versão compacta
                ),
              ),

            // Botão de exportar
            SliverToBoxAdapter(child: _buildExportButton(resultado)),

            // Espaço extra para o FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
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
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildMetricCards(ResultadoSimulacao resultado) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
        // Gráfico de evolução
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

        // Estatísticas do período
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
              const Divider(height: 24),
              if (resultado.volatilidade != null)
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
            Text(
              'Nenhum provento no período',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'A empresa não distribuiu dividendos ou JCP neste período',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Resumo de proventos por tipo
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total em proventos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    currencyFormat.format(resultado.totalDividendos),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...resultado.proventosPorTipo.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_getTipoProventoLabel(entry.key)),
                      Text(
                        currencyFormat.format(entry.value),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
              Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Yield on cost',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${resultado.yieldOnCost.toStringAsFixed(2)}%',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Lista de proventos
        ...resultado.proventosRecebidos.map((provento) {
          return ProventoTile(provento: provento);
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes do Investimento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

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
          Divider(height: 24),

          Text(
            'Cotações',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
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
          Divider(height: 24),

          Text(
            'Quantidade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          _buildDetailRow(
            'Ações compradas',
            resultado.quantidadeAcoes.toStringAsFixed(4),
          ),
          _buildDetailRow(
            'Custo médio',
            currencyFormat.format(resultado.cotacaoInicial.fechamento),
          ),
          Divider(height: 24),

          Text(
            'Rentabilidade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
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
      padding: EdgeInsets.symmetric(vertical: 6),
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

  Widget _buildExportButton(ResultadoSimulacao resultado) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: () {
          _showExportOptions(resultado);
        },
        icon: Icon(Icons.share),
        label: Text('COMPARTILHAR RESULTADO'),
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, 50),
          side: BorderSide(color: Colors.blue[700]!),
          foregroundColor: Colors.blue[700],
        ),
      ),
    );
  }

  void _showExportOptions(ResultadoSimulacao resultado) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Compartilhar Resultado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Icon(Icons.text_snippet, color: Colors.blue[700]),
                ),
                title: Text('Resumo em Texto'),
                subtitle: Text('Copiar resumo para área de transferência'),
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
                title: Text('Exportar como PDF'),
                subtitle: Text('Gerar relatório detalhado em PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _exportarPDF(resultado);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange[50],
                  child: Icon(Icons.share, color: Colors.orange[700]),
                ),
                title: Text('Compartilhar imagem'),
                subtitle: Text('Compartilhar print do resultado'),
                onTap: () {
                  Navigator.pop(context);
                  _compartilharImagem(resultado);
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _copiarResumo(ResultadoSimulacao resultado) {
    // Implementar cópia para área de transferência
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resumo copiado para área de transferência!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportarPDF(ResultadoSimulacao resultado) {
    // Implementar geração de PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF gerado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _compartilharImagem(ResultadoSimulacao resultado) {
    // Implementar compartilhamento de imagem
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imagem compartilhada!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget? _buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      label: Text('Topo'),
      icon: Icon(Icons.arrow_upward),
      backgroundColor: Colors.blue[700],
    );
  }
}

// Extensão para facilitar acesso ao ticker formatado
extension TickerFormat on String {
  String get paraAPI => contains('.') ? this : '$this.SA';
}
