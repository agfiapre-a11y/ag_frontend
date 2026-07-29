import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tenant_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _loading = false;
  bool _obscure = true;

  final _churchNameCtrl = TextEditingController();
  final _churchAddressCtrl = TextEditingController();
  final _churchPhoneCtrl = TextEditingController();
  final _churchEmailCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController();
  final _adminPhoneCtrl = TextEditingController();

  @override
  void dispose() {
    _churchNameCtrl.dispose();
    _churchAddressCtrl.dispose();
    _churchPhoneCtrl.dispose();
    _churchEmailCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPasswordCtrl.dispose();
    _adminPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(appStateProvider.notifier).setupChurch(
            churchName: _churchNameCtrl.text.trim(),
            churchAddress: _churchAddressCtrl.text.trim(),
            churchPhone: _churchPhoneCtrl.text.trim(),
            churchEmail: _churchEmailCtrl.text.trim(),
            adminName: _adminNameCtrl.text.trim(),
            adminEmail: _adminEmailCtrl.text.trim(),
            adminPassword: _adminPasswordCtrl.text,
            adminPhone: _adminPhoneCtrl.text.trim(),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantConfig = ref.watch(tenantConfigProvider);
    final appName = tenantConfig?.appName ?? tenantConfig?.name ?? 'Paradise AG';
    final setupMessage = tenantConfig?.name != null && tenantConfig!.name != appName
        ? "Let's set up ${tenantConfig.name}"
        : "Let's set up your church";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.church,
                          color: Colors.white, size: 42),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Welcome to $appName',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                    Text(
                      setupMessage,
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ]),
                ),
                const SizedBox(height: 28),

                // Step indicator
                Row(children: [
                  _StepBubble(number: 1, active: true, done: _step > 0),
                  Expanded(
                    child: Divider(
                        color:
                            _step >= 1 ? AppColors.primary : Colors.grey.shade300,
                        thickness: 2),
                  ),
                  _StepBubble(number: 2, active: _step >= 1, done: false),
                ]),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Church Info',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                    Text('Admin Account',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _step >= 1
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: _step >= 1
                                ? FontWeight.w500
                                : FontWeight.normal)),
                  ],
                ),
                const SizedBox(height: 20),

                if (_step == 0) ...[
                  Text('Church Information',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _field(_churchNameCtrl, 'Church Name', Icons.church,
                      required: true),
                  const SizedBox(height: 12),
                  _field(_churchEmailCtrl, 'Church Email', Icons.email,
                      type: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field(_churchPhoneCtrl, 'Phone Number', Icons.phone,
                      type: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(_churchAddressCtrl, 'Address', Icons.location_on,
                      lines: 2),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_churchNameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Church name is required')));
                        return;
                      }
                      setState(() => _step = 1);
                    },
                    child: const Text('Continue'),
                  ),
                ] else ...[
                  Text('Admin Account',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _field(_adminNameCtrl, 'Your Full Name', Icons.person,
                      required: true),
                  const SizedBox(height: 12),
                  _field(_adminEmailCtrl, 'Email Address', Icons.email,
                      required: true, type: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field(_adminPhoneCtrl, 'Phone Number', Icons.phone,
                      type: TextInputType.phone),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _adminPasswordCtrl,
                    obscureText: _obscure,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _step = 0),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _finish,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Set Up Church'),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? type,
    int lines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: lines,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _StepBubble extends StatelessWidget {
  final int number;
  final bool active;
  final bool done;

  const _StepBubble(
      {required this.number, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          active ? AppColors.primary : Colors.grey.shade300,
      child: done
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text('$number',
              style: TextStyle(
                  color: active ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
    );
  }
}
