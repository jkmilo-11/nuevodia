import 'package:material_ui/material_ui.dart';

import '../services/savings_goal_service.dart';
import '../widgets/currency_input_formatter.dart';

class SavingsScreen extends StatefulWidget {
  final int userId;

  const SavingsScreen({super.key, required this.userId});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final SavingsGoalService _service = SavingsGoalService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));

  List<Map<String, dynamic>> _goals = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await _service.getGoals(widget.userId);

      if (!mounted) return;

      setState(() {
        _goals = goals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('No se pudieron cargar las metas: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatMoney(double amount) {
    return '\$${amount.toStringAsFixed(0)}';
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Selecciona la fecha límite',
    );

    if (selectedDate != null) {
      setState(() => _targetDate = selectedDate);
    }
  }

  Future<void> _createGoal() async {
    final title = _titleController.text.trim();
    final amount = parseCurrencyText(_amountController.text);

    if (title.isEmpty || amount == null || amount <= 0) {
      _showMessage('Escribe un nombre y un monto válido.');
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.createGoal(
        userId: widget.userId,
        title: title,
        targetAmount: amount,
        targetDate: _targetDate,
      );

      _titleController.clear();
      _amountController.clear();

      setState(() {
        _targetDate = DateTime.now().add(const Duration(days: 30));
      });

      await _loadGoals();

      if (!mounted) return;
      _showMessage('¡Meta creada correctamente!');
    } catch (e) {
      _showMessage('No se pudo crear la meta: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _editGoal(Map<String, dynamic> goal) async {
    final titleController = TextEditingController(
      text: goal['title'] as String,
    );
    final amountController = TextEditingController(
      text: formatCurrencyText('${goal['target_amount']}'),
    );
    var targetDate = DateTime.parse(goal['target_date'] as String);

    final values = await showDialog<Map<String, Object>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar meta de ahorro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la meta',
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
                  labelText: 'Cantidad objetivo',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: dialogContext,
                    initialDate: targetDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    helpText: 'Selecciona la fecha límite',
                  );
                  if (selectedDate != null) {
                    setDialogState(() => targetDate = selectedDate);
                  }
                },
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  'Fecha límite: '
                  '${targetDate.day.toString().padLeft(2, '0')}/'
                  '${targetDate.month.toString().padLeft(2, '0')}/'
                  '${targetDate.year}',
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
              onPressed: () => Navigator.pop(dialogContext, {
                'title': titleController.text,
                'amount': amountController.text,
                'targetDate': targetDate,
              }),
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    amountController.dispose();

    if (values == null) return;
    final amount = parseCurrencyText(values['amount'] as String);
    if (amount == null || amount <= 0) {
      _showMessage('Ingresa un monto válido para la meta.');
      return;
    }

    final savedAmount = (goal['saved_amount'] as num).toDouble();
    final previouslyCompleted =
        savedAmount >= (goal['target_amount'] as num).toDouble();
    final completedByEdit = !previouslyCompleted && amount <= savedAmount;

    try {
      await _service.updateGoal(
        userId: widget.userId,
        goalId: goal['id'] as int,
        title: values['title'] as String,
        targetAmount: amount,
        targetDate: values['targetDate'] as DateTime,
      );
      await _loadGoals();
      if (!mounted) return;
      _showMessage(
        completedByEdit
            ? '¡Felicitaciones! Logro completado'
            : 'Meta actualizada correctamente.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Invalid argument(s): ', ''));
    }
  }

  Future<void> _deleteGoal(Map<String, dynamic> goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text('¿Quieres eliminar la meta "${goal['title']}"?'),
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
      await _service.deleteGoal(
        userId: widget.userId,
        goalId: goal['id'] as int,
      );
      await _loadGoals();
      if (!mounted) return;
      _showMessage('Meta eliminada correctamente.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo eliminar la meta: $e');
    }
  }

  Future<void> _addSavings(Map<String, dynamic> goal) async {
    final controller = TextEditingController();

    final enteredAmount = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Aportar a ${goal['title']}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [CurrencyInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Cantidad que deseas ahorrar',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text);
              },
              child: const Text('Registrar aporte'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (enteredAmount == null) return;

    final amount = parseCurrencyText(enteredAmount);

    if (amount == null || amount <= 0) {
      _showMessage('Ingresa una cantidad válida.');
      return;
    }

    final savedAmount = (goal['saved_amount'] as num).toDouble();
    final targetAmount = (goal['target_amount'] as num).toDouble();
    final completedByContribution = savedAmount + amount >= targetAmount;

    try {
      await _service.addSavings(
        userId: widget.userId,
        goalId: goal['id'] as int,
        amount: amount,
      );

      await _loadGoals();

      if (!mounted) return;
      _showMessage(
        completedByContribution
            ? '¡Felicitaciones! Logro completado'
            : '¡Aporte registrado correctamente!',
      );
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final target = (goal['target_amount'] as num).toDouble();
    final saved = (goal['saved_amount'] as num).toDouble();

    final progress = (saved / target).clamp(0.0, 1.0);
    final completed = saved >= target;
    final targetDate = DateTime.parse(goal['target_date'] as String);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.savings_outlined,
                  color: Color(0xFF168B70),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goal['title'] as String,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') {
                      _editGoal(goal);
                    } else {
                      _deleteGoal(goal);
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
                if (completed)
                  const Chip(
                    label: Text('Completada'),
                    avatar: Icon(Icons.check_circle, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_formatMoney(saved)} de ${_formatMoney(target)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF168B70),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 8),
            Text('${(progress * 100).toStringAsFixed(1)}% completado'),
            if (completed) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F2ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.celebration, color: Color(0xFF168B70)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Felicitaciones! Logro completado',
                        style: TextStyle(
                          color: Color(0xFF168B70),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Fecha límite: ${targetDate.day.toString().padLeft(2, '0')}/'
              '${targetDate.month.toString().padLeft(2, '0')}/'
              '${targetDate.year}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (!completed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addSavings(goal),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar ahorro'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metas de ahorro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crear una nueva meta',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la meta',
                        hintText: 'Ej. Comprar un computador',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: const [CurrencyInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Cantidad que deseas ahorrar',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        'Fecha límite: '
                        '${_targetDate.day.toString().padLeft(2, '0')}/'
                        '${_targetDate.month.toString().padLeft(2, '0')}/'
                        '${_targetDate.year}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _createGoal,
                        icon: const Icon(Icons.add),
                        label: Text(_saving ? 'Guardando...' : 'Crear meta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mis objetivos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_goals.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Todavía no tienes metas de ahorro. '
                    '¡Crea tu primera meta!',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ..._goals.map(_buildGoalCard),
          ],
        ),
      ),
    );
  }
}
