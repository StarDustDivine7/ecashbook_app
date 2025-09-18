import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPasscodeScreen extends ConsumerStatefulWidget {
  const AppPasscodeScreen({super.key});
  @override
  ConsumerState createState() => _AppPasscodeScreenState();
}

class _AppPasscodeScreenState extends ConsumerState<AppPasscodeScreen> {
  final TextEditingController _pin = TextEditingController();
  bool _hasPin = false;
  bool _isSetting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasPin = (prefs.getString('app_passcode_hash') ?? '').isNotEmpty;
      _isSetting = !_hasPin;
    });
  }

  String _hash(String input) => sha256.convert(utf8.encode(input)).toString();

  Future<void> _submit() async {
    final code = _pin.text.trim();
    if (code.length != 4) {
      setState(() => _error = 'Enter 4 digits');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (_isSetting) {
      await prefs.setString('app_passcode_hash', _hash(code));
      setState(() => _hasPin = true);
      _next();
    } else {
      final saved = prefs.getString('app_passcode_hash') ?? '';
      if (saved == _hash(code)) {
        _next();
      } else {
        setState(() => _error = 'Incorrect PIN');
      }
    }
  }

  void _next() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('user_logged_in') ?? false;
    Navigator.of(context).pushNamedAndRemoveUntil(isLoggedIn ? '/dashboard' : '/login', (r) => false);
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF422F90),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_isSetting ? 'Set App PIN' : 'Enter App PIN', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(counterText: '', errorText: _error, hintText: '••••'),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isSetting ? 'Save PIN' : 'Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
