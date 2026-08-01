import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

const _supabaseUrl     = 'https://ojskjavkhsbqgxsaatdm.supabase.co';
const _supabaseAnonKey = 'sb_publishable_m7BYL1t5yesNHdy713RLVg_bKKtZYqe';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseAnonKey);

  // Supabase's background token refresh can throw AuthRetryableFetchException
  // (e.g. no network) into an uncaught zone, crashing the app. We swallow it
  // here — AuthCubit.onAuthStateChange handles the signed-out transition.
  runZonedGuarded(
    () => runApp(const MenuApp()),
    (error, stack) {
      if (error is AuthRetryableFetchException) return;
      // Re-throw anything else so real bugs still surface.
      Error.throwWithStackTrace(error, stack);
    },
  );
}
