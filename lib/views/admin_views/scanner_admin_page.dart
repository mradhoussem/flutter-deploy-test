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
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  PackageModel? _scannedPackage;
  EPackageStatus? _nextStatus;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double scannerSize = size.width < 600 ? size.width * 0.7 : 400;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Logistique"),
        backgroundColor: DefaultColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Section Scanner
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && !_isProcessing) {
                      final String? code = barcodes.first.rawValue;
                      if (code != null) _handleScan(code);
                    }
                  },
                ),
                // Overlay Viseur
                Container(
                  width: scannerSize,
                  height: scannerSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),

          // Section Détails en bas
          _buildBottomDetailPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomDetailPanel() {
    if (_scannedPackage == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Text("En attente de scan...",
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_scannedPackage!.firstName} ${_scannedPackage!.lastName}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() => _scannedPackage = null);
                  _controller.start();
                },
              )
            ],
          ),
          Text("📍 ${_scannedPackage!.governorate.name}"),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),

          // Affichage du changement de statut
          Row(
            children: [
              _statusChip(_scannedPackage!.status, Colors.grey),
              const Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
              _statusChip(_nextStatus!, Colors.blue),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isProcessing ? null : _confirmUpdate,
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("CONFIRMER LE CHANGEMENT",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(EPackageStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(status.name.toUpperCase(),
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _handleScan(String packageId) async {
    _controller.stop();

    try {
      final package = await _db.getPackageById(packageId);
      if (package == null) {
        _showSnackBar("Colis introuvable", isError: true);
        _controller.start();
        return;
      }

      // Logique de flux demandée
      EPackageStatus? next;
      if (package.status == EPackageStatus.waiting) {
        next = EPackageStatus.deposit; // enattente -> Audepot
      } else if (package.status == EPackageStatus.deposit) {
        next = EPackageStatus.progressing; // Audepot -> en cours
      } else if (package.status == EPackageStatus.progressing) {
        next = EPackageStatus.returnFromDeposit; // en cours -> retourDepot
      } else if (package.status == EPackageStatus.returnFromDeposit) {
        next = EPackageStatus.progressing; // retourDepot -> EnCours
      }

      if (next != null) {
        setState(() {
          _scannedPackage = package;
          _nextStatus = next;
        });
      } else {
        _showSnackBar("Statut actuel (${package.status.name}) non géré", isError: true);
        _controller.start();
      }
    } catch (e) {
      _showSnackBar("Erreur technique", isError: true);
      _controller.start();
    }
  }

  Future<void> _confirmUpdate() async {
    setState(() => _isProcessing = true);
    try {
      await _db.updateStatus(_scannedPackage!.id, _nextStatus!);
      _showSnackBar("Statut mis à jour : ${_nextStatus!.name}");
      setState(() {
        _scannedPackage = null;
        _isProcessing = false;
      });
      _controller.start();
    } catch (e) {
      _showSnackBar("Erreur lors de la mise à jour", isError: true);
      setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }
}