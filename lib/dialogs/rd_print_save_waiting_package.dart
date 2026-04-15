import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/pdf_waiting_packages.dart';
import 'package:flutter/material.dart';

class RdPrintSaveWaitingPackages {
  static Future<void> show(
      BuildContext context,
      List<PackageModel> packages, {
        bool isDismissible = true,
      }) {
    return showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Column(
          children: const [
            Icon(
              Icons.pending_actions,
              color: DefaultColors.primary,
              size: 70,
            ),
            SizedBox(height: 15),
            Text(
              "Colis en attente",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: DefaultColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          "Vous avez ${packages.length} colis en attente.\nSouhaitez-vous imprimer ou sauvegarder la liste ?",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: DefaultColors.textPrimary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            children: [
              // PRINT BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await PdfWaitingPackages.printList(packages);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text(
                    "IMPRIMER",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DefaultColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await PdfWaitingPackages.saveList(packages);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.save_alt, color: Colors.white),
                  label: const Text(
                    "ENREGISTRER PDF",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // CANCEL
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "ANNULER",
                  style: TextStyle(
                    color: DefaultColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
