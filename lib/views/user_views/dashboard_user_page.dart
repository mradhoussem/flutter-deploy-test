import 'package:flutter/material.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/views/user_views/add_package_page.dart';
import 'package:delivery_app/views/user_views/packages_stats_page.dart';

class DashboardUserPage extends StatelessWidget {
  final String userId;
  final String username;

  const DashboardUserPage({
    super.key,
    required this.userId,
    required this.username,
  });


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text("Bonjour, $username", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const Text("Que souhaitez-vous faire aujourd'hui ?", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          _buildActionCard(context),
          const SizedBox(height: 40),
          PackagesStatsPage(
            userId: userId,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_shipping, size: 40, color: DefaultColors.primary),
          const SizedBox(height: 15),
          const Text("Nouvelle Expédition", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPackagePage())),
            style: ElevatedButton.styleFrom(backgroundColor: DefaultColors.primary, foregroundColor: Colors.white),
            child: const Text("COMMENCER"),
          ),
        ],
      ),
    );
  }
}