// // lib/models/carteira.dart

// import 'package:b3_simulador/models/ativo.dart';
// import 'package:b3_simulador/models/analise_valuation.dart';

// enum EstrategiaRebalanceamento {
//   manual,           // Usuário decide quando rebalancear
//   mensal,           // Todo mês
//   trimestral,       // A cada 3 meses
//   semestral,        // A cada 6 meses
//   anual,            // Uma vez por ano
//   porDesvio,        // Quando desvio da alocação alvo ultrapassa limite
// }

// enum MetodoRebalanceamento {
//   compraVenda,      // Vende ativos acima do peso, compra abaixo
//   apenasCompras,    // Apenas direciona novos aportes (sem vender)
//   fluxoCaixa,       // Usa dividendos para rebalancear
// }

// class PosicaoAtivo {
//   final Ativo ativo;
//   double quantidade;
//   double precoMedioCompra;
//   DateTime dataUltimaCompra;
  
//   // Alocação alvo (ex: 30%)
//   double alvoPercentual;
  
//   // Limites para rebalanceamento (ex: 5% de desvio)
//   double toleranciaDesvio;
  
//   // Flag se pode vender (para não vender ativos com prejuízo fiscal)
//   bool permitirVenda;
  
//   PosicaoAtivo({
//     required this.ativo,
//     required this.quantidade,
//     required this.precoMedioCompra,
//     required this.dataUltimaCompra,
//     required this.alvoPercentual,
//     this.toleranciaDesvio = 0.05, // 5% padrão
//     this.permitirVenda = true,
//   });
  
//   // Valor atual da posição
//   double valorAtual(double precoAtual) => quantidade * precoAtual;
  
//   // Percentual atual na carteira
//   double percentualAtual(double valorTotalCarteira) {
//     if (valorTotalCarteira == 0) return 0;
//     return (valorAtual(precoAtual) / valorTotalCarteira) * 100;
//   }
  
//   // Lucro/prejuízo não realizado
//   double lucroNaoRealizado(double precoAtual) => 
//       quantidade * (precoAtual - precoMedioCompra);
  
//   // Desvio da alocação alvo (percentual)
//   double desvioAlocacao(double precoAtual, double valorTotalCarteira) {
//     final percentualAtual = this.percentualAtual(precoAtual, valorTotalCarteira);
//     return percentualAtual - alvoPercentual;
//   }
  
//   // Se precisa rebalancear
//   bool precisaRebalancear(double precoAtual, double valorTotalCarteira) {
//     final desvio = desvioAlocacao(precoAtual, valorTotalCarteira).abs();
//     return desvio > toleranciaDesvio * 100; // Converte para percentual
//   }
  
//   // Quantidade a comprar/vender para atingir alvo
//   double quantidadeAjuste(double precoAtual, double valorTotalCarteira) {
//     final valorAlvo = valorTotalCarteira * (alvoPercentual / 100);
//     final valorAtual = this.valorAtual(precoAtual);
//     final diferenca = valorAlvo - valorAtual;
    
//     return diferenca / precoAtual;
//   }
  
//   Map<String, dynamic> toJson() => {
//     'ativo': ativo.toJson(),
//     'quantidade': quantidade,
//     'precoMedioCompra': precoMedioCompra,
//     'dataUltimaCompra': dataUltimaCompra.toIso8601String(),
//     'alvoPercentual': alvoPercentual,
//     'toleranciaDesvio': toleranciaDesvio,
//     'permitirVenda': permitirVenda,
//   };
  
//   factory PosicaoAtivo.fromJson(Map<String, dynamic> json) {
//     return PosicaoAtivo(
//       ativo: Ativo.fromJson(json['ativo']),
//       quantidade: json['quantidade'],
//       precoMedioCompra: json['precoMedioCompra'],
//       dataUltimaCompra: DateTime.parse(json['dataUltimaCompra']),
//       alvoPercentual: json['alvoPercentual'],
//       toleranciaDesvio: json['toleranciaDesvio'] ?? 0.05,
//       permitirVenda: json['permitirVenda'] ?? true,
//     );
//   }
// }

// class Carteira {
//   final String id;
//   final String nome;
//   final List<PosicaoAtivo> posicoes;
//   final DateTime dataCriacao;
//   DateTime? ultimoRebalanceamento;
  
//   // Estratégia de rebalanceamento
//   final EstrategiaRebalanceamento estrategia;
//   final MetodoRebalanceamento metodo;
  
//   // Aportes automáticos
//   double? aporteMensal;
//   DateTime? proximoAporte;
  
//   // Saldo em conta corrente (para compras)
//   double saldoDisponivel;
  
//   Carteira({
//     required this.id,
//     required this.nome,
//     required this.posicoes,
//     required this.dataCriacao,
//     this.ultimoRebalanceamento,
//     required this.estrategia,
//     required this.metodo,
//     this.aporteMensal,
//     this.proximoAporte,
//     this.saldoDisponivel = 0,
//   });
  
//   // Valor total da carteira
//   double valorTotal(Map<String, double> precosAtuais) {
//     double total = saldoDisponivel;
//     for (var posicao in posicoes) {
//       final preco = precosAtuais[posicao.ativo.ticker] ?? 0;
//       total += posicao.valorAtual(preco);
//     }
//     return total;
//   }
  
//   // Verifica se precisa rebalancear com base na estratégia
//   bool precisaRebalancearAgora() {
//     if (ultimoRebalanceamento == null) return true;
    
//     final agora = DateTime.now();
    
//     switch (estrategia) {
//       case EstrategiaRebalanceamento.mensal:
//         return _diasDesdeUltimo() >= 30;
//       case EstrategiaRebalanceamento.trimestral:
//         return _diasDesdeUltimo() >= 90;
//       case EstrategiaRebalanceamento.semestral:
//         return _diasDesdeUltimo() >= 180;
//       case EstrategiaRebalanceamento.anual:
//         return _diasDesdeUltimo() >= 365;
//       case EstrategiaRebalanceamento.porDesvio:
//         // Verifica desvio individual por ativo
//         return false; // Será verificado em método específico
//       case EstrategiaRebalanceamento.manual:
//         return false;
//     }
//   }
  
//   int _diasDesdeUltimo() {
//     if (ultimoRebalanceamento == null) return 999;
//     return DateTime.now().difference(ultimoRebalanceamento!).inDays;
//   }
  
//   // Encontra ativos com maior desvio
//   List<PosicaoAtivo> ativosComDesvio(Map<String, double> precosAtuais) {
//     final valorTotal = this.valorTotal(precosAtuais);
//     return posicoes.where((p) {
//       return p.precisaRebalancear(
//         precosAtuais[p.ativo.ticker] ?? 0,
//         valorTotal,
//       );
//     }).toList();
//   }
  
//   // Gera ordens de rebalanceamento
//   List<OrdemRebalanceamento> gerarOrdensRebalanceamento(
//     Map<String, double> precosAtuais,
//     AnaliseValuationService valuationService,
//   ) async {
//     final ordens = <OrdemRebalanceamento>[];
//     final valorTotal = this.valorTotal(precosAtuais);
    
//     for (var posicao in posicoes) {
//       final preco = precosAtuais[posicao.ativo.ticker] ?? 0;
//       final quantidadeAjuste = posicao.quantidadeAjuste(preco, valorTotal);
      
//       if (quantidadeAjuste.abs() < 0.01) continue; // Ignora ajustes muito pequenos
      
//       // Análise de valuation para decidir prioridade
//       final analise = await valuationService.calcularValuation(posicao