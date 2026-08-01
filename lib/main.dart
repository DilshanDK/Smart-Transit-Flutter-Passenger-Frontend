import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/ui/auth_wrapper.dart';
import 'features/wallet/data/repositories/wallet_repository.dart';
import 'features/wallet/bloc/wallet_bloc.dart';
import 'features/wallet/bloc/wallet_event.dart';
import 'features/payment/data/repositories/payment_repository.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> _initAppServices() async {
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('🚀 dotenv loaded successfully');
  } catch (e) {
    debugPrint('⚠️ Failed to load .env: $e');
  }

  try {
    final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? 'pk_test_51TZ6vJ8PKebNGkX2IP8gkHL0vkzjo3yvf0MEUHPMmx1yOWGzdOdRnIrezjKUGCz6aWqpzDwiNCSrhfH3gC3H6a1p00VhqzR3oK';
    debugPrint('🔑 Stripe Key Loaded (length: ${key.length}): ${key.length > 15 ? key.substring(0, 15) : key}...');
    Stripe.publishableKey = key;
    await Stripe.instance.applySettings();
    debugPrint('✅ Stripe initialized successfully');
  } catch (e) {
    debugPrint('❌ Stripe initialization failed: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initAppServices();

  // Load saved theme before showing the app
  final themeCubit = ThemeCubit();
  await themeCubit.load();

  runApp(MyApp(themeCubit: themeCubit));
}

class MyApp extends StatelessWidget {
  final ThemeCubit themeCubit;
  const MyApp({super.key, required this.themeCubit});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<WalletRepository>(
          create: (context) => WalletRepository(),
        ),
        RepositoryProvider<PaymentRepository>(
          create: (context) => PaymentRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            )..add(const AppStarted()),
          ),
          BlocProvider<WalletBloc>(
            create: (context) => WalletBloc(
              walletRepository: RepositoryProvider.of<WalletRepository>(context),
            )..add(const LoadWalletRequested()),
          ),
        ],
        child: BlocBuilder<ThemeCubit, bool>(
          builder: (context, isDark) {
            return MaterialApp(
              title: 'Smart Transit Passenger',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}
