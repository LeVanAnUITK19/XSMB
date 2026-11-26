import 'package:flutter/material.dart';
import '../core/constants/regions.dart';

class WaitPage extends StatelessWidget {
  final RegionConfig region;

  const WaitPage({super.key, required this.region});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                region.assetImage,
                height: size.height * 0.3,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              Text(
                region.displayName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
