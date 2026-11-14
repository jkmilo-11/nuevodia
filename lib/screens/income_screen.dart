import 'package:material_ui/material_ui.dart';

import '../services/income_service.dart';
import '../widgets/currency_input_formatter.dart';

class IncomeScreen extends StatefulWidget {
  final int userId;

  const IncomeScreen({super.key, required this.userId});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final IncomeService _service = IncomeService();

  final TextEditingController _grossController = TextEditingController();
  final TextEditingController _deductionsController = TextEditingController();

  late final TextEditingController _monthController;

  List<Map<String, dynamic>> _incomes = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _monthController = TextEditingController(
      text: '${now.year}-${now.month.toString().padLeft(2, '0')}',
    );

    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    setState(() => _loading = true);

    try {
      final data = await _service.getIncomes(widget.userId);

      if (!mounted) return;

      setState(() {
        _incomes = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('No se pudieron cargar los ingresos: $e');
    }
  }

  Future<void> _saveIncome() async {
    final gross = parseCurrencyText(_grossController.text);
    final deductions = parseCurrencyText(_deductionsController.text);

    final month = _monthController.text.trim();

    if (gross == null || deductions == null) {
      _showMessage('Ingresa valores numéricos válidos.');
      return;
    }

    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month)) {
      _showMessage('El mes debe tener el formato AAAA-MM.');
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.saveIncome(
        userId: widget.userId,
        month: month,
        grossIncome: gross,
        deductions: deductions,
      );

      _grossController.clear();
      _deductionsController.clear();

      await _loadIncomes();

      if (!mounted) return;
      _showMessage('Ingreso guardado correctamente.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Invalid argument(s): ', ''));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _editIncome(Map<String, dynamic> income) async {
    final monthController = TextEditingController(
      text: income['month'] as String,
    );
    final grossController = TextEditingController(
      text: formatCurrencyText('${income['gross_income']}'),
    );
    final deductionsController = TextEditingController(
      text: formatCurrencyText('${income['deductions']}'),
    );

    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar ingreso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: monthController,
              decoration: const InputDecoration(
                labelText: 'Mes (AAAA-MM)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: grossController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Ingreso bruto',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deductionsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Deducciones',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, [
              monthController.text,
              grossController.text,
              deductionsController.text,
            ]),
            child: const Text('Guardar cambios'),
          ),
        ],
      ),
    );

    monthController.dispose();
    grossController.dispose();
    deductionsController.dispose();

    if (values == null) return;

    final month = values[0].trim();
    final gross = parseCurrencyText(values[1]);
    final deductions = parseCurrencyText(values[2]);
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month) ||
        gross == null ||
        deductions == null) {
      _showMessage('Ingresa un mes y valores numéricos válidos.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.updateIncome(
        userId: widget.userId,
        incomeId: income['id'] as int,
        month: month,
        grossIncome: gross,
        deductions: deductions,
      );
      await _loadIncomes();
      if (!mounted) return;
      _showMessage('Ingreso actualizado correctamente.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Invalid argument(s): ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteIncome(Map<String, dynamic> income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar ingreso'),
        content: Text('¿Quieres eliminar el ingreso de ${income['month']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteIncome(
        userId: widget.userId,
        incomeId: income['id'] as int,
      );
      await _loadIncomes();
      if (!mounted) return;
      _showMessage('Ingreso eliminado correctamente.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo eliminar el ingreso: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatMoney(dynamic value) {
    final amount = (value as num).toDouble();
    return '\$ ${amount.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _grossController.dispose();
    _deductionsController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresos mensuales')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Registrar ingreso',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _monthController,
            decoration: const InputDecoration(
              labelText: 'Mes (AAAA-MM)',
              hintText: '2026-11',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _grossController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [CurrencyInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Ingreso bruto',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _deductionsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [CurrencyInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Deducciones',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          FilledButton(
            onPressed: _saving ? null : _saveIncome,
            child: Text(_saving ? 'Guardando...' : 'Guardar ingreso'),
          ),

          const SizedBox(height: 30),
          const Text(
            'Historial de ingresos',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_incomes.isEmpty)
            const Text('Todavía no tienes ingresos registrados.')
          else
            ..._incomes.map((income) {
              return Card(
                child: ListTile(
                  title: Text('Mes: ${income['month']}'),
                  subtitle: Text(
                    'Bruto: ${_formatMoney(income['gross_income'])}\n'
                    'Deducciones: ${_formatMoney(income['deductions'])}\n'
                    'Neto: ${_formatMoney(income['net_income'])}',
                  ),
                  isThreeLine: true,
                  leading: const Icon(Icons.account_balance_wallet),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') {
                        _editIncome(income);
                      } else {
                        _deleteIncome(income);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 12),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline),
                            SizedBox(width: 12),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
