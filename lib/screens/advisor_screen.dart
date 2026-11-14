import 'package:material_ui/material_ui.dart';

import '../services/financial_advisor_service.dart';

class AdvisorScreen extends StatefulWidget {
  final int userId;

  const AdvisorScreen({super.key, required this.userId});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final FinancialAdvisorService _service = FinancialAdvisorService();

  Map<String, dynamic>? _report;
  List<String> _recommendations = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  String _money(double amount) {
    return '\$${amount.toStringAsFixed(0)}';
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await _service.getMonthlyReport(widget.userId);
      final recommendations = _service.generateRecommendations(report);

      if (!mounted) return;

      setState(() {
        _report = report;
        _recommendations = recommendations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudo generar el análisis: $e';
        _loading = false;
      });
    }
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 5),
                  Text(
                    _money(amount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationCard(String recommendation, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF168B70).withValues(alpha: 0.12),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Color(0xFF168B70),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(recommendation),
      ),
    );
  }

  Widget _buildCategoryExpenses() {
    final categories =
        _report!['categoryExpenses'] as List<Map<String, Object?>>;

    if (categories.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Todavía no hay gastos registrados este mes.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: categories.map((category) {
            final name = category['category'] as String;
            final amount = (category['total'] as num).toDouble();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(name)),
                  Text(
                    _money(amount),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final report = _report!;

    final netIncome = report['netIncome'] as double;
    final expenses = report['totalExpenses'] as double;
    final available = report['availableMoney'] as double;
    final totalSaved = report['totalSaved'] as double;
    final goalCount = report['goalCount'] as int;
    final completedGoals = report['completedGoals'] as int;

    final month = report['month'] as String;
    final balanceColor = available < 0 ? Colors.red : const Color(0xFF168B70);

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Análisis de $month',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _summaryCard(
            title: 'Ingresos netos',
            amount: netIncome,
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.blue,
          ),

          _summaryCard(
            title: 'Gastos del mes',
            amount: expenses,
            icon: Icons.receipt_long,
            color: Colors.orange,
          ),

          _summaryCard(
            title: 'Dinero disponible',
            amount: available,
            icon: Icons.savings_outlined,
            color: balanceColor,
          ),

          const SizedBox(height: 20),

          const Text(
            'Distribución de tus gastos',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildCategoryExpenses(),

          const SizedBox(height: 20),

          const Text(
            'Tus metas de ahorro',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Metas registradas: $goalCount'),
                  const SizedBox(height: 8),
                  Text('Metas completadas: $completedGoals'),
                  const SizedBox(height: 8),
                  Text('Dinero ahorrado: ${_money(totalSaved)}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Recomendaciones de NuevoDia 🌞',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ..._recommendations.asMap().entries.map(
            (entry) => _recommendationCard(entry.value, entry.key),
          ),

          const SizedBox(height: 12),
          Text(
            'Estas recomendaciones son orientativas y se calculan '
            'con los movimientos registrados. Los gastos no registrados '
            'pueden cambiar el resultado.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asesor financiero'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadReport,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar análisis',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadReport,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : _buildContent(),
    );
  }
}
