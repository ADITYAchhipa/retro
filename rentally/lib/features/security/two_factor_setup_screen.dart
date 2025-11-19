import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/security/two_factor_service.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  bool _enabled = false;
  final _codeCtrl = TextEditingController();
  String? _secret;
  String? _otpauth;
  bool _loading = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final enabled = await TwoFactorService.instance.isEnabled();
    final secret = await TwoFactorService.instance.getOrCreateSecret();
    final uri = TwoFactorService.instance.buildOtpAuthUri(
      issuer: 'Rentally',
      accountName: 'user@rentally',
      secretBase32: secret,
    );
    if (!context.mounted) return;
    setState(() {
      _enabled = enabled;
      _secret = secret;
      _otpauth = uri;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  SwitchListTile(
                    title: const Text('Enable 2FA (TOTP)'),
                    subtitle: const Text('Use Authenticator apps like Google Authenticator, Authy, 1Password'),
                    value: _enabled,
                    onChanged: (v) async {
                      if (v) {
                        // Require verification to enable
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a code from your authenticator and tap Verify & Enable')));
                      } else {
                        await TwoFactorService.instance.setEnabled(false);
                        if (!context.mounted) return;
                        setState(() => _enabled = false);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Two-factor authentication disabled')));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Step 1: Scan QR Code', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (_otpauth != null)
                            Center(
                              child: QrImageView(
                                data: _otpauth!,
                                version: QrVersions.auto,
                                size: 180,
                                gapless: true,
                              ),
                            ),
                          const SizedBox(height: 8),
                          const Text('If you cannot scan, enter this secret manually in your app:'),
                          const SizedBox(height: 6),
                          SelectableText(_secret ?? '-', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Step 2: Verify Code', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _codeCtrl,
                            decoration: const InputDecoration(labelText: '6-digit code'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final code = _codeCtrl.text.trim();
                                if (code.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 6-digit code')));
                                  return;
                                }
                                final ok = await TwoFactorService.instance.verifyCode(code);
                                if (!context.mounted) return;
                                if (ok) {
                                  await TwoFactorService.instance.setEnabled(true);
                                  if (!context.mounted) return;
                                  setState(() => _enabled = true);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Two-factor authentication enabled')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code. Please try again')));
                                }
                              },
                              icon: const Icon(Icons.verified_outlined),
                              label: const Text('Verify & Enable'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_enabled)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await TwoFactorService.instance.regenerateSecret();
                        await _load();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Secret regenerated. Scan the new QR')));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate Secret'),
                    ),
                ],
              ),
            ),
    );
  }
}
