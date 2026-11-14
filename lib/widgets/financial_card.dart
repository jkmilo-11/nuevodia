import 'package:material_ui/material_ui.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/financial_advisor_service.dart';

class FinancialCharts extends StatefulWidget {
  final int userId;

  const FinancialCharts({super.key, required this.userId});

  @override
  State<FinancialCharts> createState() => _FinancialChartsState();
}

class _FinancialChartsState extends State<FinancialCharts> {
  late Future<Map<String, dynamic>> _reportFuture;

  final List<Color> chartColors = [
    Colors.teal,
    Colors.orange,
    Colors.blue,
    Colors.purple,
    Colors.red,
    Colors.green,
    Colors.amber,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    _reportFuture = FinancialAdvisorService().getMonthlyReport(widget.userId);
  }

  void _refresh() {
    setState(() {
      _loadReport();
    });
  }

  String _money(num value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: ListTile(
              title: const Text('No se pudieron cargar las estadísticas'),
              subtitle: const Text('Comprueba los datos e inténtalo de nuevo.'),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refresh,
              ),
            ),
          );
        }

        final report = snapshot.data!;

        final income = (report['netIncome'] as num).toDouble();
        final expenses = (report['totalExpenses'] as num).toDouble();
        final saved = (report['totalSaved'] as num).toDouble();
        final goalAmount = (report['totalGoalAmount'] as num).toDouble();

        final categories =
            report['categoryExpenses'] as List<Map<String, Object?>>;

        final savingsProgress = goalAmount > 0
            ? (saved / goalAmount).clamp(0.0, 1.0)
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resumen visual',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'Actualizar gráficos',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // GRÁFICO DE INGRESOS Y GASTOS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingresos vs. gastos',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 190,
                      child: BarChart(
                        BarChartData(
                          maxY:
                              [
                                income,
                                expenses,
                                1.0,
                              ].reduce((a, b) => a > b ? a : b) *
                              1.2,
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: income,
                                  color: Colors.teal,
                                  width: 35,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: expenses,
                                  color: Colors.orange,
                                  width: 35,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ],
                            ),
                          ],
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final label = value == 0
                                      ? 'Ingresos'
                                      : value == 1
                                      ? 'Gastos'
                                      : '';

                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(label),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Ingresos: ${_money(income)}'),
                    Text('Gastos: ${_money(expenses)}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // GRÁFICO CIRCULAR DE GASTOS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribución de gastos',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (categories.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Todavía no hay gastos registrados.'),
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 35,
                            sections: categories.asMap().entries.map((entry) {
                              final index = entry.key;
                              final category = entry.value;
                              final total = (category['total'] as num)
                                  .toDouble();

                              return PieChartSectionData(
                                value: total,
                                color: chartColors[index % chartColors.length],
                                radius: 75,
                                showTitle: false,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      ...categories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        final name = category['category'] as String;
                        final total = (category['total'] as num).toDouble();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color:
                                      chartColors[index % chartColors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(name)),
                              Text(
                                _money(total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // PROGRESO DE AHORRO
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progreso de ahorro',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    LinearProgressIndicator(
                      value: savingsProgress,
                      minHeight: 13,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    Text('Ahorrado: ${_money(saved)}'),
                    Text('Objetivo total: ${_money(goalAmount)}'),
                    Text(
                      '${(savingsProgress * 100).toStringAsFixed(1)}% completado',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    if (goalAmount == 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Crea una meta de ahorro para visualizar tu progreso.',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
