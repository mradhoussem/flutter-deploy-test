import 'package:delivery_app/dialogs/rd_print_save_package.dart';
import 'package:delivery_app/firestore/enums/e_governorate.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_package.dart';
import 'package:delivery_app/firestore/package_db.dart';
import 'package:delivery_app/reusable_widgets/rw_dropdown.dart';
import 'package:delivery_app/reusable_widgets/rw_textview.dart';
import 'package:delivery_app/tools/default_colors.dart';
import 'package:delivery_app/tools/refresh_notifier.dart';
import 'package:flutter/material.dart';

class UpdatePackagePage extends StatefulWidget {
  final PackageModel package;
  const UpdatePackagePage({super.key, required this.package});

  @override
  State<UpdatePackagePage> createState() => _UpdatePackagePageState();
}

class _UpdatePackagePageState extends State<UpdatePackagePage> {
  final _formKey = GlobalKey<FormState>();
  final PackageDB _db = PackageDB();

  late TextEditingController _fNameController;
  late TextEditingController _lNameController;
  late TextEditingController _phone1Controller;
  late TextEditingController _phone2Controller;
  late TextEditingController _addressController;
  late TextEditingController _amountController;
  late TextEditingController _designationController;
  late TextEditingController _commentController;

  String? _selectedGov;
  bool _isExchange = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _fNameController = TextEditingController(text: widget.package.firstName);
    _lNameController = TextEditingController(text: widget.package.lastName);
    _phone1Controller = TextEditingController(text: widget.package.phone1);
    _phone2Controller = TextEditingController(text: widget.package.phone2 ?? '');
    _addressController = TextEditingController(text: widget.package.address);
    _amountController = TextEditingController(text: widget.package.amount.toString());
    _designationController = TextEditingController(text: widget.package.packageDesignation ?? '');
    _commentController = TextEditingController(text: widget.package.comment ?? '');

    _selectedGov = widget.package.governorate.name;
    _isExchange = widget.package.isExchange;
  }

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _designationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _updateForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Prepare the data
      final updatedData = {
        'firstName': _fNameController.text.trim(),
        'lastName': _lNameController.text.trim(),
        'phone1': _phone1Controller.text.trim(),
        'phone2': _phone2Controller.text.trim().isEmpty ? null : _phone2Controller.text.trim(),
        'governorate': _selectedGov,
        'address': _addressController.text.trim(),
        'amount': double.parse(_amountController.text.trim().replaceAll(',', '.')),
        'isExchange': _isExchange,
        'packageDesignation': _isExchange ? _designationController.text.trim() : null,
        'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      };

      // 2. Perform the update in Firestore
      await _db.updatePackageFields(widget.package.id, updatedData);

      if (mounted) {
        // 3. Notify the list to refresh
        RefreshNotifier().notifyRefresh();

        // 4. Create a local instance of the updated package to pass to the printer
        // We use widget.package.copyWith if you have that method,
        // otherwise, manually create the model from the updated data.
        final updatedPackage = widget.package.copyWith(
          firstName: updatedData['firstName'] as String,
          lastName: updatedData['lastName'] as String,
          phone1: updatedData['phone1'] as String,
          phone2: updatedData['phone2'] as String?,
          governorate: EGovernorateExtension.fromName(updatedData['governorate'] as String),
          address: updatedData['address'] as String,
          amount: updatedData['amount'] as double,
          isExchange: updatedData['isExchange'] as bool,
          packageDesignation: updatedData['packageDesignation'] as String?,
          comment: updatedData['comment'] as String?,
        );

        // 5. Close the Update page first to avoid context issues
        Navigator.pop(context);

        // 6. Show the Print Dialog on the previous screen (Home/List)
        // We use the root Navigator's context or a small delay to ensure the UI is ready
        RdPrintSavePackage.show(context, updatedPackage);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Colis mis à jour et prêt pour impression')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: DefaultColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.pagesBackground,
      appBar: AppBar(
        title: const Text('Modifier le Colis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('DESTINATAIRE'),
              Row(
                children: [
                  Expanded(
                    child: RwTextview(
                      controller: _fNameController,
                      hint: 'Prénom',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RwTextview(
                      controller: _lNameController,
                      hint: 'Nom',
                      prefixIcon: Icons.person,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _phone1Controller,
                hint: 'Téléphone 1',
                textNumeric: true,
                prefixIcon: Icons.phone_iphone,
                maxLength: 8,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('LIVRAISON'),
              RwDropdown(
                value: _selectedGov,
                items: EGovernorate.values.map((e) => e.name).toList(),
                itemLabelBuilder: (name) => EGovernorateExtension.fromName(name).label,
                onChanged: (val) => setState(() => _selectedGov = val),
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _addressController,
                hint: 'Adresse exacte',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 15),
              RwTextview(
                controller: _amountController,
                hint: 'Montant (TND)',
                textDouble: true,
                prefixIcon: Icons.payments_outlined,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 25),
              _buildExchangeSection(),
              const SizedBox(height: 15),
              RwTextview(
                controller: _commentController,
                hint: 'Remarque',
                prefixIcon: Icons.textsms_outlined,
              ),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
  );

  Widget _buildExchangeSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Échange de colis', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            value: _isExchange,
            activeThumbColor: DefaultColors.primary,
            onChanged: (val) => setState(() {
              _isExchange = val;
              if (!val) _designationController.clear();
            }),
          ),
          if (_isExchange)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: RwTextview(
                controller: _designationController,
                hint: 'Que doit-on récupérer ?',
                prefixIcon: Icons.inventory_2_outlined,
                validator: (v) => (_isExchange && v!.isEmpty) ? 'Requis' : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateForm,
        style: ElevatedButton.styleFrom(backgroundColor: DefaultColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENREGISTRER LES MODIFICATIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}