import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminGuard extends StatefulWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> with WidgetsBindingObserver {
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final bool isLoggedIn = prefs.getBool('is_admin_logged_in') ?? false;

    if (!isLoggedIn && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/loginAdmin', (route) => false);
    } else if (mounted) {
      setState(() => _isAuthorized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isAuthorized ? widget.child : const Scaffold(body: SizedBox.shrink());
  }
}