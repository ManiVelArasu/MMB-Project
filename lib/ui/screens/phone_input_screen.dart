import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../network/provider/auth_provider.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone Login"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Phone Number TextField
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              onChanged: (value) => authProvider.updateMobile(value),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Enter Phone Number",
                prefixText: "+91 ",
                errorText: authProvider.mobileError,
              ),
            ),

            const SizedBox(height: 20),

            /// Send OTP Button
            ElevatedButton(
              onPressed: authProvider.isLoading 
                  ? null 
                  : () async {
                      String phoneNumber = phoneController.text.trim();

                      if (phoneNumber.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Enter phone number")),
                        );
                        return;
                      }

                      await authProvider.sendOtp(
                        phoneNumber: phoneNumber,
                        onCodeSent: (verificationId) {
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtpVerificationScreen(
                                  verificationId: verificationId,
                                  phoneNumber: phoneNumber,
                                ),
                              ),
                            );
                          }
                        },
                        onError: (errorMessage) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMessage)),
                            );
                          }
                        },
                      );
                    },
              child: const Text("Send OTP"),
            ),

            const SizedBox(height: 20),

            if (authProvider.isLoading)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }
}