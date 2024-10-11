import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String officerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely access the arguments in didChangeDependencies
    final args = ModalRoute.of(context)!.settings.arguments as String?;
    if (args != null) {
      setState(() {
        officerId = args;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Text('Officer Profile: $officerId'),
      ),
    );
  }
}
