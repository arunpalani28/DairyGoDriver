import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/theme.dart';
import 'delivery_screen.dart';
import 'earnings_screen.dart';
import 'profile_screen.dart';

// ── SPLASH ────────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashState();
}
class _SplashState extends State<SplashScreen> {
  @override void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 900));
    final token = await ApiClient.loadToken();
    if (!mounted) return;
    if (token != null) {
      final ud = await ApiClient.loadUserData();
      final kycStatus = ud?['kycStatus'] ?? 'PENDING';
      if (kycStatus == 'VERIFIED') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverShell()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const KycPendingScreen()));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: kGreen,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      
Image.asset(
  'assets/app_logo.png',
  errorBuilder: (context, error, stackTrace) {
    print("Asset Error: $error"); // Look at your terminal/debug console
    return Text("Could not find image: $error");
  },
),
      const SizedBox(height: 48),
      const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    ])),
  );
}

// ── LOGIN (OTP-based) ─────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginState();
}
class _LoginState extends State<LoginScreen> {
  final _mobileCtrl = TextEditingController();
  final _otpCtrl    = TextEditingController();
  bool _loading = false, _otpSent = false;
  String? _error;
  int _resendSecs = 0;
  Timer? _timer;
  String? _otpNumber; 

  @override void dispose() { _mobileCtrl.dispose(); _otpCtrl.dispose(); _timer?.cancel(); super.dispose(); }

  Future<void> _sendOtp() async {
    final m = _mobileCtrl.text.trim();
    if (m.length < 10) { setState(() => _error = 'Enter a valid 10-digit mobile number'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final res= await ApiClient.post('/auth/send-otp', {'mobile': m});
      setState(() { _otpNumber= res["data"];_otpSent = true; _loading = false; _resendSecs = 30; });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_resendSecs <= 0) { _timer?.cancel(); setState(() {}); return; }
        setState(() => _resendSecs--);
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.length != 6) { setState(() => _error = 'Enter 6-digit OTP'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.post('/auth/verify-otp', {'mobile': _mobileCtrl.text.trim(), 'otp': _otpCtrl.text.trim()});
      final data = res['data'] as Map<String, dynamic>;
      if (data['role'] != 'DRIVER') { setState(() { _error = 'This app is for drivers only.'; _loading = false; }); return; }
      await ApiClient.saveToken(data['token']);
      await ApiClient.saveUserData(data);
      if (!mounted) return;
      final kycStatus = data['kycStatus'] ?? 'PENDING';
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>
          kycStatus == 'VERIFIED' ? const DriverShell() : const KycPendingScreen()));
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: kGreen,
    body: SafeArea(child: Column(children: [
      const Expanded(flex: 2, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset(
             'assets/app_logo.png',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
        // Text('🚚', style: TextStyle(fontSize: 60)),
        // SizedBox(height: 12),
        // Text('Aavinam Driver', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        Text('Driver Management', style: TextStyle(fontSize: 13, color: Color(0xFFA5D6A7))),
      ]))),
      Expanded(flex: 3, child: Container(
        decoration: const BoxDecoration(color: kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_otpSent ? 'Enter OTP' : 'Driver Sign In',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextDark)),
          const SizedBox(height: 4),
          Text(_otpSent ? 'OTP is ${_otpNumber}' : 'Enter your registered mobile number',
              style: const TextStyle(fontSize: 13, color: kTextMid)),
          const SizedBox(height: 24),
          if (!_otpSent)
            _field('Mobile Number', _mobileCtrl, keyboardType: TextInputType.phone)
          else ...[
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kGreenLt, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: kGreen, size: 16), const SizedBox(width: 8),
                Text('OTP is ${_otpNumber}', style: const TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w600)),
              ])),
            const SizedBox(height: 14),
            _field('6-digit OTP', _otpCtrl, keyboardType: TextInputType.number, maxLength: 6),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerRight, child: GestureDetector(
              onTap: _resendSecs > 0 ? null : _sendOtp,
              child: Text(_resendSecs > 0 ? 'Resend in ${_resendSecs}s' : 'Resend OTP',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _resendSecs > 0 ? kTextLight : kGreen)),
            )),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kRedLt, borderRadius: BorderRadius.circular(10)),
              child: Text(_error!, style: const TextStyle(color: kRed, fontSize: 12))),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
            style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_otpSent ? 'Verify OTP' : 'Send OTP', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          )),
          if (_otpSent) ...[
            const SizedBox(height: 12),
            Center(child: GestureDetector(
              onTap: () => setState(() { _otpSent = false; _otpCtrl.clear(); _error = null; }),
              child: const Text('Change number', style: TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w600)),
            )),
          ],
          const SizedBox(height: 16),
          Center(child: Text('Demo: use 9000000001 (Driver)', style: TextStyle(fontSize: 11, color: kTextLight))),
        ])),
      )),
    ])),
  );

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboardType, int? maxLength}) => TextField(
    controller: ctrl, keyboardType: keyboardType, maxLength: maxLength,
    style: const TextStyle(fontSize: 13, color: kTextDark, fontFamily: 'Poppins'),
    decoration: InputDecoration(
      labelText: label, labelStyle: const TextStyle(fontSize: 12, color: kTextMid, fontFamily: 'Poppins'),
      filled: true, fillColor: kCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), counterText: ''),
  );
}

// ── KYC PENDING for Drivers ────────────────────────────────────────────────────
class KycPendingScreen extends StatelessWidget {
  const KycPendingScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 88, height: 88, decoration: BoxDecoration(color: kGreenLt, borderRadius: BorderRadius.circular(44)),
        child: const Center(child: Text('🚚', style: TextStyle(fontSize: 44)))),
      const SizedBox(height: 24),
      const Text('Account Under Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kTextDark)),
      const SizedBox(height: 10),
      const Text('Your driver account is being verified by our admin team. You will be notified once approved.',
          style: TextStyle(fontSize: 13, color: kTextMid, height: 1.6), textAlign: TextAlign.center),
      const SizedBox(height: 28),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: kGreenLt, borderRadius: BorderRadius.circular(12)), child: Row(children: const [
        Icon(Icons.info_rounded, color: kGreen, size: 18), SizedBox(width: 8),
        Expanded(child: Text('Our team will call you within 24 hours to complete onboarding.', style: TextStyle(fontSize: 12, color: kGreen, height: 1.5))),
      ])),
      const SizedBox(height: 24),
      TextButton(onPressed: () async { await ApiClient.clearToken(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); },
        child: const Text('Sign Out', style: TextStyle(color: kTextLight, fontSize: 12))),
    ]))),
  );
}

// ── SHELL ─────────────────────────────────────────────────────────────────────
class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _ShellState();
}

class _ShellState extends State<DriverShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,

      // ✅ FIXED: Rebuild screen on tab change → API reload works
      body: [
        const DeliveryScreen(),
        const EarningsScreen(),
        const ProfileScreen(),
      ][_tab],

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kCard,
          boxShadow: [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                _ni(0, Icons.local_shipping_rounded, 'Deliveries'),
                _ni(1, Icons.account_balance_wallet_rounded, 'Earnings'),
                _ni(2, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ni(int idx, IconData icon, String label) {
    final on = _tab == idx;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _tab = idx); // ✅ triggers rebuild → API reload
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: on ? kGreen : kTextLight,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: on ? kGreen : kTextLight,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: on ? 6 : 0,
              height: on ? 6 : 0,
              decoration: const BoxDecoration(
                color: kGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


