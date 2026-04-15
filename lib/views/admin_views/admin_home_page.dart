import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:delivery_app/firestore/user_db.dart';
import 'package:delivery_app/reusable_widgets/rw_appbar.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/admin_views/dashboard_admin_page.dart';
import 'package:delivery_app/reusable_widgets/rw_sidebar_item.dart';
import 'package:delivery_app/views/admin_views/users_view_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final UserDB _userRepo = UserDB();

  List<UserModel>? _cachedUsers;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isReloading = true);

    try {
      final users = await _userRepo.getAllUsers();
      setState(() {
        _cachedUsers = users;
        _isReloading = false;
      });
    } catch (e) {
      setState(() => _isReloading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de chargement: $e")));
      }
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_logged_in', false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/loginAdmin');
    }
  }

  // ⭐ SIDEBAR ITEMS (NEW ARCHITECTURE)
  List<RwSideBarItem> _buildItems() {
    return [
      RwSideBarItem(
        title: "Dashboard",
        icon: Icons.dashboard,
        page: const DashboardAdminPage(),
      ),

      RwSideBarItem(
        title: "Users",
        icon: Icons.people,
        page: UsersViewPage(
          users: _cachedUsers,
          onManualRefresh: _fetchUsers,
          isRefreshing: _isReloading,
        ),
      ),

      RwSideBarItem(
        title: "Paramètres",
        icon: Icons.settings,
        page: const Center(child: Text("Paramètres")),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 900;

    final items = _buildItems();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: DefaultColors.background,
      drawer: isWeb ? null : _buildSidebar(items),

      body: Row(
        children: [
          if (isWeb && _isSidebarOpen) _buildSidebar(items),

          Expanded(
            child: Column(
              children: [
                RwAppbar(
                  username: "Admin",
                  primaryColor: DefaultColors.primary,
                  onMenuPressed: () {
                    if (isWeb) {
                      setState(() => _isSidebarOpen = !_isSidebarOpen);
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                  },
                ),

                Expanded(
                  child: _cachedUsers == null && _selectedIndex == 1
                      ? const Center(child: CircularProgressIndicator())
                      : items[_selectedIndex].page,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(List<RwSideBarItem> items) {
    return RwSideBar(
      portalTitle: "ADMIN PORTAL",
      selectedIndex: _selectedIndex,
      items: items,
      primaryColor: Colors.white,
      backgroundColor: DefaultColors.primary,
      unselectedColor: Colors.white70,
      onItemSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      onLogout: _handleLogout,
    );
  }
}
