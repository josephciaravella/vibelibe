import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(
              'v${snapshot.data!.version}',
              style: Theme.of(context).textTheme.labelSmall,
            );
          } else {
            // Returns an empty space while loading to avoid UI flicker
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
