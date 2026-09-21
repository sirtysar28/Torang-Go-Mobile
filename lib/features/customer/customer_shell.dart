import 'package:flutter/material.dart';

import '../../shared/widgets.dart';
import '../notifications/notifications_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  final pages = const [
    HomeScreen(),
    OrdersScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      // SafeArea bottom: memastikan nav bar floating TIDAK tertutup
      // tombol back/gesture bar Android (edge-to-edge).
      bottomNavigationBar: SafeArea(
        top: false,
        child: TGNavBar(
          index: _index,
          items: const [
            TGNavBarItem(Icons.home_rounded, 'Beranda'),
            TGNavBarItem(Icons.receipt_long_rounded, 'Pesanan'),
            TGNavBarItem(Icons.notifications_rounded, 'Notifikasi'),
            TGNavBarItem(Icons.person_rounded, 'Akun'),
          ],
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
