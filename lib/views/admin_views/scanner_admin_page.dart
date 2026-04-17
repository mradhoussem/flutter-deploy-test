import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AdminScannerPage extends StatefulWidget {
  const AdminScannerPage({super.key});

  @override
  State<AdminScannerPage> createState() => _AdminScannerPageState();
}

class _AdminScannerPageState extends State<AdminScannerPage> {
  final PackageDB _db = PackageDB();
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back, // Caméra arrière par défaut sur mobile
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calcul de la taille du viseur selon l'écran (Responsive)
    final size = MediaQuery.of(context).size;
    final double scannerSize = size.width < 600 ? size.width * 0.8 : 500;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Colis"),
        backgroundColor: DefaultColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Bouton pour changer de caméra ou allumer le flash (utile sur mobile)
          /*IconButton(
            icon: ValueListenableBuilder<TorchState>( // ✅ Spécifie le type
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.white);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),*/
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: scannerSize,
                  height: scannerSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: DefaultColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty && !_isProcessing) {
                          final String? code = barcodes.first.rawValue;
                          if (code != null) _handleScan(code);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Placez le QR Code dans le cadre",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleScan(String packageId) async {
    setState(() => _isProcessing = true);
    _controller.stop(); // Stop pour éviter les scans en boucle

    try {
      final package = await _db.getPackageById(packageId);

      if (package == null) {
        _showSnackBar("Erreur: Colis introuvable ($packageId)", isError: true);
        _resume();
        return;
      }

      _processLogic(package);
    } catch (e) {
      _showSnackBar("Erreur de connexion", isError: true);
      _resume();
    }
  }

  void _processLogic(PackageModel package) {
    EPackageStatus? nextStatus;
    String title = "";

    // Application stricte de votre flux
    if (package.status == EPackageStatus.deposit) {
      nextStatus = EPackageStatus.progressing;
      title = "SORTIE DÉPÔT";
    } else if (package.status == EPackageStatus.progressing) {
      nextStatus = EPackageStatus.returnFromDeposit;
      title = "RETOUR DÉPÔT";
    } else if (package.status == EPackageStatus.returnFromDeposit) {
      nextStatus = EPackageStatus.progressing;
      title = "RÉEXPÉDITION";
    }

    if (nextStatus != null) {
      _confirmDialog(package, nextStatus, title);
    } else {
      _showSnackBar(
        "Aucune action pour ce statut (${package.status.name})",
        isError: true,
      );
      _resume();
    }
  }

  void _confirmDialog(PackageModel package, EPackageStatus next, String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Client: ${package.firstName} ${package.lastName}"),
            Text("Destination: ${package.governorate.name}"),
            const Divider(height: 20),
            Text(
              "Changer le statut vers : ${next.name.toUpperCase()} ?",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resume();
            },
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await _db.updateStatus(package.id, next);
              if(context.mounted) {
                Navigator.pop(context);
              }
              _showSnackBar("Statut mis à jour !");
              _resume();
            },
            child: const Text(
              "CONFIRMER",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _resume() {
    _controller.start();
    if (mounted) setState(() => _isProcessing = false);
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
