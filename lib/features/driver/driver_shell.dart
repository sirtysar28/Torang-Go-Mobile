import 'package:flutter/material.dart';

import '../../shared/widgets.dart';
import 'driver_home_screen.dart';
import 'driver_orders_screen.dart';
import 'driver_wallet_screen.dart';
import 'driver_profile_screen.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;

  final pages = const [
    DriverHomeScreen(),
    DriverOrdersScreen(),
    DriverWalletScreen(),
    DriverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      // SafeArea bottom: nav bar tidak tertutup tombol back/gesture Android.
      bottomNavigationBar: SafeArea(
        top: false,
        child: TGNavBar(
          index: _index,
          items: const [
            TGNavBarItem(Icons.speed_rounded, 'Beranda'),
            TGNavBarItem(Icons.receipt_long_rounded, 'Order'),
            TGNavBarItem(Icons.account_balance_wallet_rounded, 'Dompet'),
            TGNavBarItem(Icons.person_rounded, 'Akun'),
          ],
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
