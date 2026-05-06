import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Analysis extends StatelessWidget {
  const Analysis({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
          },
          child: const Text("Logout"),
        ),
      ),
    );
  }
}
