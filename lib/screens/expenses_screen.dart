import 'package:material_ui/material_ui.dart';

import '../services/expense_service.dart';
import '../widgets/currency_input_formatter.dart';

class ExpenseScreen extends StatefulWidget {
  final int userId;

  const ExpenseScreen({super.key, required this.userId});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseService _service = ExpenseService();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final List<String> _categories = [
    'Alimentación',
    'Transporte',
    'Vivienda',
    'Educación',
    'Salud',
    'Entretenimiento',
    'Servicios',
    'Otros',
  ];

  String? _selectedCategory = 'Alimentación';
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _expenses = [];
  double _monthlyTotal = 0;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _loading = true);

    try {
      final expenses = await _service.getExpenses(widget.userId);

      final now = DateTime.now();
      final total = await _service.getMonthlyTotal(
        widget.userId,
        now.year,
        now.month,
      );

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
        _monthlyTotal = total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Error al cargar los gastos: $e');
    }
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha del gasto',
    );

    if (selected != null && mounted) {
      setState(() => _selectedDate = selected);
    }
  }

  Future<void> _saveExpense() async {
    final description = _descriptionController.text.trim();
    final amount = parseCurrencyText(_amountController.text);

    if (_selectedCategory == null ||
        description.isEmpty ||
        amount == null ||
        amount <= 0) {
      _showMessage('Completa todos los campos con valores válidos.');
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.saveExpense(
        userId: widget.userId,
        category: _selectedCategory!,
        description: description,
        amount: amount,
        date: _selectedDate,
      );

      _descriptionController.clear();
      _amountController.clear();

      await _loadExpenses();

      if (!mounted) return;
      _showMessage('Gasto guardado correctamente.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo guardar el gasto: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _editExpense(Map<String, dynamic> expense) async {
    final descriptionController = TextEditingController(
      text: expense['description'] as String,
    );
    final amountController = TextEditingController(
      text: formatCurrencyText('${expense['amount']}'),
    );
    var category = _categories.contains(expense['category'])
        ? expense['category'] as String
        : _categories.first;
    var date = DateTime.parse(expense['date'] as String);

    final values = await showDialog<Map<String, Object>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar gasto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => category = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Valor del gasto',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: dialogContext,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      helpText: 'Selecciona la fecha del gasto',
                    );
                    if (selected != null) {
                      setDialogState(() => date = selected);
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    'Fecha: ${date.day.toString().padLeft(2, '0')}/'
                    '${date.month.toString().padLeft(2, '0')}/'
                    '${date.year}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'category': category,
                'description': descriptionController.text,
                'amount': amountController.text,
                'date': date,
              }),
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );

    descriptionController.dispose();
    amountController.dispose();

    if (values == null) return;
    final amount = parseCurrencyText(values['amount'] as String);
    if (amount == null || amount <= 0) {
      _showMessage('Ingresa un valor válido para el gasto.');
      return;
    }

    try {
      await _service.updateExpense(
        userId: widget.userId,
        expenseId: expense['id'] as int,
        category: values['category'] as String,
        description: values['description'] as String,
        amount: amount,
        date: values['date'] as DateTime,
      );
      await _loadExpenses();
      if (!mounted) return;
      _showMessage('Gasto actualizado correctamente.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo actualizar el gasto: $e');
    }
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Quieres eliminar "${expense['description']}"?'),
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
      await _service.deleteExpense(
        userId: widget.userId,
        expenseId: expense['id'] as int,
      );
      await _loadExpenses();
      if (!mounted) return;
      _showMessage('Gasto eliminado correctamente.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo eliminar el gasto: $e');
    }
  }

  String _formatMoney(dynamic value) {
    final amount = (value as num).toDouble();
    return '\$ ${amount.toStringAsFixed(0)}';
  }

  String _formatDate(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis gastos'),
        backgroundColor: const Color(0xFF168B70),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Resumen mensual
          Card(
            color: const Color(0xFFE2F2ED),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total gastado este mes',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatMoney(_monthlyTotal),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF168B70),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Registrar gasto',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value);
            },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripción del gasto',
              hintText: 'Ej. Compra de alimentos',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [CurrencyInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Valor del gasto',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_month),
            label: Text(
              'Fecha: ${_selectedDate.day.toString().padLeft(2, '0')}/'
              '${_selectedDate.month.toString().padLeft(2, '0')}/'
              '${_selectedDate.year}',
            ),
          ),

          const SizedBox(height: 16),

          FilledButton(
            onPressed: _saving ? null : _saveExpense,
            child: Text(_saving ? 'Guardando...' : 'Guardar gasto'),
          ),

          const SizedBox(height: 30),

          const Text(
            'Historial de gastos',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_expenses.isEmpty)
            const Text('Todavía no tienes gastos registrados.')
          else
            ..._expenses.map((expense) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE2F2ED),
                    child: Icon(Icons.receipt_long, color: Color(0xFF168B70)),
                  ),
                  title: Text(expense['description'] as String),
                  subtitle: Text(
                    '${expense['category']} · '
                    '${_formatDate(expense['date'] as String)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMoney(expense['amount']),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'edit') {
                            _editExpense(expense);
                          } else {
                            _deleteExpense(expense);
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
