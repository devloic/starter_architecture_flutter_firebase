import 'dart:developer' show log;
import 'dart:math' show Random;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:starter_architecture_flutter_firebase/firebase_options.dart';
import 'package:starter_architecture_flutter_firebase/src/constants/app_sizes.dart';
import 'package:starter_architecture_flutter_firebase/src/features/onboarding/data/onboarding_repository.dart';

import 'app.dart';

part 'app_startup.g.dart';

@Riverpod(keepAlive: true)
Future<void> appStartup(AppStartupRef ref) async {
  ref.listen(onboardingRepositoryProvider, (previous, current) {
    if (current.hasError) {
      // keep track of error so the provider can be rebuilt on retry
    }
  });
  ref.onDispose(() {
    // ensure dependent providers are disposed as well
    ref.invalidate(onboardingRepositoryProvider);
  });
  // await for all initialization code to be complete before returning
  await Future.wait([
    // Firebase init
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    // list of providers to be warmed up
    ref.watch(onboardingRepositoryProvider.future)
  ]);
}


@riverpod
Future<bool> three(ThreeRef ref) async {
  await Future<void>.delayed(const Duration(seconds: 3));
  ref.onDispose(() => log('disposing three'));
  final shouldThrow = Random().nextBool();
  if (shouldThrow) throw Exception('three');
  return shouldThrow;
}





class AppStartupWidget extends ConsumerStatefulWidget {
  const AppStartupWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppStartupState();
}

class _AppStartupState extends ConsumerState<AppStartupWidget> {
  bool warmedUp = false;

  @override
  Widget build(BuildContext context) {
    log('WarmedUp : $warmedUp');
    if (warmedUp) {
      return const MyApp();
    }

    final providers = <ProviderListenable<AsyncValue<Object?>>>[
      appStartupProvider,
      //threeProvider
    ];

    var states = providers.map(ref.watch).toList();
    for (final state in states) {
      if (state is AsyncError) {
        log('warm up failed: $state');
        //Error.throwWithStackTrace(state.error, state.stackTrace);
        return AppStartupErrorWidget(
            message: state.error.toString(),
            onRetry: ()  {
              ref.invalidate(appStartupProvider);
              ref.invalidate(threeProvider);
            });
      }

    }

    if (states.every((state) => state is AsyncData)) {
      log('warmup is done');
      Future(() => setState(() => warmedUp = true));
    }

    return const AppStartupLoadingWidget();
  }
}

class AppStartupLoadingWidget extends StatelessWidget {
  const AppStartupLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return
        const Center(
          child: CircularProgressIndicator(),
        );
  }
}

class AppStartupErrorWidget extends StatelessWidget {
  const AppStartupErrorWidget(
      {super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(context).textTheme.headlineSmall),
              gapH16,
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
