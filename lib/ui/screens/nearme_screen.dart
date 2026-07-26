
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class NearMeScreen extends StatefulWidget {
  const NearMeScreen({super.key});

  @override
  State<NearMeScreen> createState() => _NearMeScreenState();
}

class _NearMeScreenState extends State<NearMeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center                                         ,
          children: [
            Lottie.asset('assets/lottie/Coming Soon Dark Background.json'),
          ],
        ),
      ),
    );
  }
}
