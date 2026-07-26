import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../network/provider/auth_provider.dart';
import 'home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    Key? key,
    required this.verificationId,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Column(
              children: [
                const SizedBox(height: 50),
                Text(
                  "Enter the OTP sent to ${widget.phoneNumber}",
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                    (index) => SizedBox(
                      width: 60,
                      child: TextField(
                        controller: authProvider.controllers[index],
                        focusNode: authProvider.focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        decoration: const InputDecoration(
                          counterText: "",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.length == 1 && index < 3) {
                            authProvider.focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            authProvider.focusNodes[index - 1].requestFocus();
                          }
                          
                          if (authProvider.isOtpComplete()) {
                            _verifyOtp(context, authProvider);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                authProvider.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () => _verifyOtp(context, authProvider),
                        child: const Text("Verify OTP"),
                      ),
                
                const SizedBox(height: 10),
                
                TextButton(
                  onPressed: () => _resendOtp(context, authProvider),
                  child: const Text("Resend OTP"),
                ),
                
                const SizedBox(height: 10),
                
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Edit Phone Number"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _verifyOtp(BuildContext context, AuthProvider authProvider) async {
    if (!authProvider.isOtpComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter complete OTP")),
      );
      return;
    }

    String otp = authProvider.getOtp();

    await authProvider.verifyOtp(
      verificationId: widget.verificationId,
      smsCode: otp,
      onSuccess: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      },
      onError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      },
    );
  }

  void _resendOtp(BuildContext context, AuthProvider authProvider) async {
    await authProvider.resendOtp(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (verificationId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP resent successfully")),
        );
      },
      onError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      },
    );
  }
}