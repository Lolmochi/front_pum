import 'package:flutter/material.dart';
import 'screens_employer/login_FuelTransaction.dart';
import 'screens_employer/sales_FuelTransaction.dart';

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
      },
    );
  }
}
