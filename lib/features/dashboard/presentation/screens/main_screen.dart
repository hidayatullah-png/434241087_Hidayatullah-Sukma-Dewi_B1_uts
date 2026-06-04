import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'dashboard_screen.dart';
import '../../../tickets/presentation/screens/ticket_list_screen.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navIndexProvider);

    // List halaman yang akan ditampilkan
    final List<Widget> screens = [
      const DashboardScreen(),
      const TicketListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.wrnShapePurple.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          // PERUBAHAN HANYA DI BARIS INI:
          onTap: (index) => ref.read(navIndexProvider.notifier).setIndex(index),
          backgroundColor: AppColors.wrnDarkBg,
          selectedItemColor: AppColors.wrnBtsPurple,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_rounded),
              label: 'Tiket',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
