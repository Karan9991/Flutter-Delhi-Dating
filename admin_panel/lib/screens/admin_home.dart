import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'dashboard_screen.dart';
import 'features_screen.dart';
import 'matches_screen.dart';
import 'reports_screen.dart';
import 'users_screen.dart';

class AdminHome extends ConsumerStatefulWidget {
  const AdminHome({super.key});

  @override
  ConsumerState<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends ConsumerState<AdminHome> {
  int _index = 0;

  final List<_AdminDestination> _destinations = const [
    _AdminDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      widget: DashboardScreen(),
    ),
    _AdminDestination(
      label: 'Users',
      icon: Icons.people_outline,
      widget: UsersScreen(),
    ),
    _AdminDestination(
      label: 'Reports',
      icon: Icons.report_gmailerrorred_outlined,
      widget: ReportsScreen(),
    ),
    _AdminDestination(
      label: 'Matches',
      icon: Icons.favorite_border,
      widget: MatchesScreen(),
    ),
    _AdminDestination(
      label: 'Features',
      icon: Icons.tune,
      widget: FeaturesScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wideLayout = MediaQuery.of(context).size.width >= 980;

    final content = IndexedStack(
      index: _index,
      children: _destinations.map((dest) => dest.widget).toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_index].label),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(firebaseAuthProvider).signOut(),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: wideLayout ? null : Drawer(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Delhi Dating Admin',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in _destinations.asMap().entries)
              ListTile(
                leading: Icon(entry.value.icon),
                title: Text(entry.value.label),
                selected: entry.key == _index,
                onTap: () {
                  setState(() => _index = entry.key);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
      body: Row(
        children: [
          if (wideLayout)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final dest in _destinations)
                  NavigationRailDestination(
                    icon: Icon(dest.icon),
                    label: Text(dest.label),
                  ),
              ],
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              color: theme.scaffoldBackgroundColor,
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDestination {
  const _AdminDestination({
    required this.label,
    required this.icon,
    required this.widget,
  });

  final String label;
  final IconData icon;
  final Widget widget;
}
