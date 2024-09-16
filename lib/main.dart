import 'package:flutter/material.dart';
import 'screens_employer/login_FuelTransaction.dart';
import 'screens_employer/sales_FuelTransaction.dart';
import 'screens_admin/login_admin.dart';
import 'screens_admin/Home_admin.dart';
import 'screens_admin/search_page.dart';
import 'screens_admin/notifications_page.dart';
import 'screens_admin/annual_dividendsPage.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Login(),
        '/sales': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final staffId = args?['staff_id'] ?? ''; // รับค่า staffId จาก arguments
          return FuelTransactionScreen(staff_id: staffId);
        },
        '/login_FuelTransaction': (context) => const Login(),
        '/login_admin': (context) => const Login_admin(),
        '/Home_admin': (context) => const HomePage(),
        '/search_page': (context) => const SearchAndManagePage(),
        '/notifications': (context) => const NotificationsPage(),
        '/dividends': (context) => const AnnualDividendsPage(),
      },
    );
  }
}
