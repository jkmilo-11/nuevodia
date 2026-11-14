import 'package:material_ui/material_ui.dart';

import '../services/budget_service.dart';

class BudgetScreen extends StatefulWidget {
  final int userId;

  const BudgetScreen({super.key, required this.userId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _service = BudgetService();

  Map<String, dynamic>? _plan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  String _money(double amount) {
    return '\$${amount.toStringAsFixed(0)}';
  }

  Future<void> _loadPlan() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getBudgetPlan(widget.userId);

      if (!mounted) return;

      setState(() {
        _plan = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudo calcular el presupuesto: $e';
        _loading = false;
      });
    }
  }

  Widget _budgetCard({
    required String title,
    required String description,
    required double spent,
    required double limit,
    required Color color,
  }) {
    final progress = limit > 0
        ? (spent / limit).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final remaining = limit - spent;
    final exceeded = remaining < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gastado: ${_money(spent)}'),
                Text('Límite: ${_money(limit)}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(10),
              color: exceeded ? Colors.red : color,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 8),
            Text(
              exceeded
                  ? 'Superaste el límite de referencia por ${_money(-remaining)}.'
                  : 'Disponible en esta categoría: ${_money(remaining)}',
              style: TextStyle(
                color: exceeded ? Colors.red : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final plan = _plan!;

    final income = plan['netIncome'] as double;
    final essentials = plan['essentialExpenses'] as double;
    final flexible = plan['flexibleExpenses'] as double;
    final unclassified = plan['unclassifiedExpenses'] as double;
    final expenses = plan['totalExpenses'] as double;
    final available = plan['availableMoney'] as double;

    final essentialLimit = plan['essentialLimit'] as double;
    final flexibleLimit = plan['flexibleLimit'] as double;
    final savingsTarget = plan['savingsTarget'] as double;
    final suggestedSavings = plan['suggestedSavings'] as double;

    final categories = plan['categoryTotals'] as List<Map<String, dynamic>>;

    return RefreshIndicator(
      onRefresh: _loadPlan,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Presupuesto de ${plan['month']}',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu ingreso neto mensual',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _money(income),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  const Text('Gastos registrados'),
                  const SizedBox(height: 4),
                  Text(
                    _money(expenses),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Dinero disponible'),
                  const SizedBox(height: 4),
                  Text(
                    _money(available),
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: available < 0
                          ? Colors.red
                          : const Color(0xFF168B70),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Distribución de referencia',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _budgetCard(
            title: 'Necesidades — 50 %',
            description: 'Gastos esenciales del presupuesto.',
            spent: essentials,
            limit: essentialLimit,
            color: const Color(0xFF168B70),
          ),

          _budgetCard(
            title: 'Deseos — 30 %',
            description: 'Entretenimiento y gastos flexibles.',
            spent: flexible,
            limit: flexibleLimit,
            color: Colors.blue,
          ),

          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ahorro — 20 %',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Objetivo orientativo de ahorro mensual.'),
                  const SizedBox(height: 12),
                  Text(
                    'Objetivo: ${_money(savingsTarget)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          if (unclassified > 0) ...[
            const SizedBox(height: 12),
            const Text(
              'Gastos sin clasificar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Otras categorías'),
                subtitle: const Text(
                  'No se incluyen en los porcentajes anteriores.',
                ),
                trailing: Text(_money(unclassified)),
              ),
            ),
          ],

          const SizedBox(height: 20),

          const Text(
            'Tu capacidad de ahorro',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Objetivo de referencia: ${_money(savingsTarget)}'),
                  const SizedBox(height: 8),
                  Text(
                    'Ahorro sugerido según tu balance actual: '
                    '${_money(suggestedSavings)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF168B70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    available <= 0
                        ? 'Por ahora no tienes dinero disponible para destinar '
                              'al ahorro según los movimientos registrados. '
                              'Revisa tus gastos y compromisos.'
                        : suggestedSavings < savingsTarget
                        ? 'Tu balance actual no permite alcanzar el '
                              'objetivo de referencia del 20 %. '
                              'Puedes ajustar los gastos o adaptar tu meta.'
                        : 'Tu balance permite cubrir el objetivo de '
                              'ahorro de referencia. Recuerda considerar '
                              'también los gastos que aún no has registrado.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Detalle por categoría',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (categories.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No hay gastos registrados este mes.'),
              ),
            )
          else
            Card(
              child: Column(
                children: categories.map((category) {
                  return ListTile(
                    title: Text(category['category'].toString()),
                    trailing: Text(
                      _money((category['total'] as num).toDouble()),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 16),
          Text(
            'El presupuesto 50/30/20 es una referencia educativa. '
            'No representa una obligación ni considera automáticamente '
            'deudas, gastos futuros o compromisos no registrados.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto inteligente'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadPlan,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar presupuesto',
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
                      onPressed: _loadPlan,
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
