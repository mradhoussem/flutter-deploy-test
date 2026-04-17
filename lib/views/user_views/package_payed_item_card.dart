import 'package:delivery_app/dialogs/rd_print_save_package.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:delivery_app/views/user_views/package_details_page.dart';
import 'package:delivery_app/views/user_views/update_package_page.dart';
import 'package:flutter/material.dart';

class PackagePayedItemCard extends StatelessWidget {
  final PackageModel package;
  final bool showSender;

  const PackagePayedItemCard({
    super.key,
    required this.package,
    this.showSender = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculation: Net Amount (HT) = Total Amount - Delivery Cost
    final double amountHT = package.amount - package.deliveryCost;

    return SelectionArea(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOP SECTION: Info & Status Badge ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildInfo()),
                  _buildStatusBadge(package.status),
                ],
              ),
      
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, thickness: 0.5),
              ),
      
              // --- ACCOUNTING SECTION (The "Little Table") ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildPriceRow("Montant Total", "${package.amount.toStringAsFixed(3)} TND", isBold: true),
                    const SizedBox(height: 6),
                    _buildPriceRow("Frais Livraison", "- ${package.deliveryCost.toStringAsFixed(3)} TND", color: Colors.red.shade700),
                    const Divider(height: 16),
                    _buildPriceRow(
                        "Montant Net (HT)",
                        "${amountHT.toStringAsFixed(3)} TND",
                        color: Colors.green.shade700,
                        isLarge: true
                    ),
                  ],
                ),
              ),
      
              const SizedBox(height: 12),
      
              // --- BOTTOM SECTION: Action Buttons ---
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 4,
                  children: [
                    // Only allow Edit/Delete if it's still in "waiting"
                    if (package.status == EPackageStatus.waiting) ...[
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        color: DefaultColors.error,
                        tooltip: "Supprimer",
                        onPressed: () => _confirmDelete(context),
                      ),
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        color: Colors.blue,
                        tooltip: "Editer",
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UpdatePackagePage(package: package),
                          ),
                        ),
                      ),
                    ],
                    _buildActionButton(
                      icon: Icons.print_outlined,
                      color: Colors.black87,
                      tooltip: "Imprimer",
                      onPressed: () => RdPrintSavePackage.show(context, package),
                    ),
                    _buildActionButton(
                      icon: Icons.visibility_outlined,
                      color: Colors.black87,
                      tooltip: "Détails",
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PackageDetailsPage(package: package),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for the Table Rows
  Widget _buildPriceRow(String label, String value, {Color? color, bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 14 : 13,
            fontWeight: isBold || isLarge ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: FontWeight.w900,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSender) ...[
          Row(
            children: [
              const Icon(Icons.storefront, size: 14, color: DefaultColors.primary),
              const SizedBox(width: 4),
              Text(
                "Expéditeur: ${package.creatorUsername}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DefaultColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Text(
          "${package.firstName} ${package.lastName}",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        _infoRow(Icons.location_on_outlined, package.governorate.name),
        const SizedBox(height: 4),
        _infoRow(
          Icons.phone_outlined,
          "${package.phone1}${package.phone2 != null ? ' / ${package.phone2}' : ''}",
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusBadge(EPackageStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // Changes color based on status for better visibility
        color: DefaultColors.success,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: DefaultColors.background,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer l'expédition"),
        content: const Text("Voulez-vous vraiment supprimer ce colis ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ANNULER")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("SUPPRIMER", style: TextStyle(color: DefaultColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PackageDB().deletePackage(package.id);
      RefreshNotifier().notifyRefresh();
    }
  }
}