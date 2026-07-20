import 'package:flutter/material.dart';

import '../widgets/logo_lockup.dart';
import 'ipr_screen.dart';

/// Describes one tool entry so new tools can be added by appending to [_tools].
class _Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder? builder;

  const _Tool({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.builder,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final List<_Tool> _tools = [
    _Tool(
      title: 'IPR Calculator',
      subtitle: 'IPR & AOF from a well test or PI — step by step',
      icon: Icons.show_chart,
      color: const Color(0xFF4FC3F7),
      builder: (_) => const IprScreen(),
    ),
    // Operating Point tool hidden for now. To restore it, re-add:
    // _Tool(
    //   title: 'Operating Point',
    //   subtitle: 'IPR × TPC intersection — nodal analysis',
    //   icon: Icons.mediation,
    //   color: const Color(0xFFFFB74D),
    //   builder: (_) => const OperatingPointScreen(),
    // ),
    // and the import of 'operating_point_screen.dart' above.
    const _Tool(
      title: 'More tools coming soon',
      subtitle: 'PVT correlations, decline curves, and more',
      icon: Icons.construction,
      color: Color(0xFF9E9E9E),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            const LogoLockup(height: 44),
            const SizedBox(height: 8),
            Text(
              'Engineering toolkit for petroleum students',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            for (final tool in _tools) ...[
              _ToolCard(tool: tool),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatefulWidget {
  final _Tool tool;

  const _ToolCard({required this.tool});

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    // Brief pause so the indicator is visible before the screen slides in.
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _opening = false);
    Navigator.of(context).push(MaterialPageRoute(builder: widget.tool.builder!));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tool = widget.tool;
    final enabled = tool.builder != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        enabled: enabled,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: tool.color.withValues(alpha: 0.15),
          child: Icon(tool.icon, color: tool.color),
        ),
        title: Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(tool.subtitle, style: theme.textTheme.bodySmall),
        trailing: !enabled
            ? null
            : _opening
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: tool.color),
                  )
                : const Icon(Icons.chevron_right),
        onTap: enabled ? _open : null,
      ),
    );
  }
}
