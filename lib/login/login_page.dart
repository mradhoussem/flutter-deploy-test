
import 'package:delivery_app/tools/images_files.dart';
import 'package:flutter/material.dart';
import '../reusable_widgets/rw_textview.dart';
import '../tools/default_colors.dart';

// Import your AdminHomePage here
// import 'admin_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultColors.background,
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    // Image Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        ImagesFiles.backgroundCar,
                        width: isMobile ? 300 : 600,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Login Card Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        color: DefaultColors.background,
                        elevation: 5,
                        shadowColor: DefaultColors.primary.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          width: isMobile ? double.infinity : 450,
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Votre colis, notre mission',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                    color: DefaultColors.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 30),

                                // Email Field
                                RwTextview(
                                  controller: _emailController,
                                  hint: 'Email',
                                  isEmail: true,
                                  prefixIcon: Icons.email_rounded,
                                ),
                                const SizedBox(height: 15),

                                // Password Field
                                RwTextview(
                                  controller: _passwordController,
                                  hint: "Mot de passe",
                                  isPassword: true,
                                ),
                                const SizedBox(height: 30),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DefaultColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 15),
                                // Space between button and link

                                // --- NEW CLICKABLE TEXT ---
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Accès réservé ? "),
                                    TextButton(
                                      onPressed: () {
                                        // Use pushNamed since you defined the route in main.dart
                                        Navigator.pushNamed(
                                          context,
                                          '/loginAdmin',
                                        );
                                      },
                                      child: const Text(
                                        "Ouvrir une session administrateur",
                                        style: TextStyle(
                                          color: DefaultColors.primary,
                                          // Requested red color
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
