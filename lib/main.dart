import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

// TODO: Replace with your Supabase project URL and anon key before running.
// Project URL → Supabase dashboard → Project Settings → API → Project URL
// Anon key    → Supabase dashboard → Project Settings → API → anon public
const _supabaseUrl    = 'https://ojskjavkhsbqgxsaatdm.supabase.co';
const _supabaseAnonKey = 'sb_publishable_m7BYL1t5yesNHdy713RLVg_bKKtZYqe';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseAnonKey);
  runApp(const MenuApp());
}
