import 'package:material_ui/material_ui.dart';
import 'package:nuevodia/widgets/financial_card.dart';

import 'income_screen.dart';
import 'expenses_screen.dart';
import 'savings_screen.dart';
import 'advisor_screen.dart';
import 'budget_screen.dart';

Future<void> _confirmSignOut(BuildContext context) async {
  final shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );

  if (shouldSignOut != true || !context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _SadSunGoodbyeDialog(),
  );

  if (!context.mounted) return;

  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}

class _SadSunGoodbyeDialog extends StatefulWidget {
  const _SadSunGoodbyeDialog();

  @override
  State<_SadSunGoodbyeDialog> createState() => _SadSunGoodbyeDialogState();
}

class _SadSunGoodbyeDialogState extends State<_SadSunGoodbyeDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.rotate(
                angle: -0.12 + (_controller.value * 0.24),
                child: ScaleTransition(scale: _scale, child: child),
              ),
              child: const Text('🌞', style: TextStyle(fontSize: 76)),
            ),
            const SizedBox(height: 12),
            const Text(
              'vuelva pronto',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user['name'] as String;
    final userId = user['id'] as int;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NuevoDia 🌞',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF168B70),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BIENVENIDA
            Text(
              '¡Hola, $name!',
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Bienvenido a tu espacio financiero.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // BANNER PRINCIPAL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF168B70),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu futuro comienza hoy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Organiza tus ingresos, controla tus gastos '
                    'y alcanza tus metas de ahorro.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // GRÁFICOS FINANCIEROS
            FinancialCharts(userId: userId),

            const SizedBox(height: 30),

            // HERRAMIENTAS
            const Text(
              'Mis herramientas',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            // INGRESOS
            _MenuCard(
              icon: Icons.account_balance_wallet,
              title: 'Mis ingresos',
              description: 'Registra y administra tus ingresos.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IncomeScreen(userId: userId),
                  ),
                );
              },
            ),

            // GASTOS
            _MenuCard(
              icon: Icons.receipt_long,
              title: 'Mis gastos',
              description: 'Controla tus gastos mensuales.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpenseScreen(userId: userId),
                  ),
                );
              },
            ),

            // METAS DE AHORRO
            _MenuCard(
              icon: Icons.savings,
              title: 'Metas de ahorro',
              description: 'Define objetivos y fechas.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavingsScreen(userId: userId),
                  ),
                );
              },
            ),

            // ASESOR FINANCIERO
            _MenuCard(
              icon: Icons.lightbulb_outline,
              title: 'Asesor financiero',
              description: 'Recibe recomendaciones económicas.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdvisorScreen(userId: userId),
                  ),
                );
              },
            ),

            // PRESUPUESTO INTELIGENTE
            _MenuCard(
              icon: Icons.pie_chart_outline,
              title: 'Presupuesto inteligente',
              description: 'Organiza y distribuye tus ingresos.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BudgetScreen(userId: userId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE2F2ED),
          child: Icon(icon, color: const Color(0xFF168B70)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
