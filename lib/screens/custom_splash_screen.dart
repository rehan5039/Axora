import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomSplashScreen extends StatelessWidget {
  final Widget child;
  
  const CustomSplashScreen({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFEF8EB),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Logo
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF8EB),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'app_icon.png',
                      width: 150,
                      height: 150,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Loading animation
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.amber,
                    size: 40,
                  ),
                ],
              ),
            ),
            
            // Main app (initially invisible)
            FutureBuilder(
              future: Future.delayed(const Duration(seconds: 3)), // 3 second delay
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return child;
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
} 