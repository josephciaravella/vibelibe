import 'package:flutter/material.dart';
import 'package:vibelibe/widgets/footer.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        spacing: 32,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              "vibelibe",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(fontSize: 32),
            ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
            //  padding: EdgeInsetsGeometry.only(left: 20.0, right: 20.0, bottom: 20.0),
            child: ElevatedButton(
              onPressed: () {
                print('Spotify Login Tapped');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                spacing: 32,
                children: [
                  Image.asset(
                    'lib/assets/spotify_black.png',
                    width: 24,
                    height: 24,
                  ),
                  Text(
                    "Log into your Spotify Account",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const Footer(),
    );
  }
}
