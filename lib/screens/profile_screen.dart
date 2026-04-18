import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/theme.dart';
import 'splash_login_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DriverProfile? _profile;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/driver/profile');
      setState(() { _profile = DriverProfile.fromJson(res['data']); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _logout() async {
    await ApiClient.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: Column(children: [
      Container(color: kGreen, child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(children: [
          const Align(alignment: Alignment.centerRight,
            child: Icon(Icons.more_vert_rounded, color: Colors.white, size: 22)),
          Container(width: 74, height: 74,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(37),
              border: Border.all(color: Colors.white38, width: 2)),
            child: Center(child: Text(
              _profile?.initials ?? 'DV',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)))),
          const SizedBox(height: 10),
          Text(_profile?.name ?? '—',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Zone: ${_profile?.zone ?? '—'}',
              style: const TextStyle(fontSize: 11, color: Color(0xFFA5D6A7))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 16), SizedBox(width: 4),
              Text('4.9 Rating · Active Driver',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ]),
      ))),
      if (_loading)
        const Expanded(child: Center(child: CircularProgressIndicator(color: kGreen)))
      else
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          _section('Account Details', [
            _tile(Icons.person_rounded, kPrimary, 'Full Name', _profile?.name ?? '—'),
            _tile(Icons.email_rounded, kGreen, 'Email', _profile?.email ?? '—'),
            _tile(Icons.phone_rounded, kOrange, 'Phone', _profile?.phone ?? '—'),
            _tile(Icons.map_rounded, kPrimary, 'Delivery Zone', _profile?.zone ?? '—'),
          ]),
          const SizedBox(height: 14),
          _section('Vehicle Info', [
            _tile(Icons.two_wheeler_rounded, kGreen, 'Vehicle', 'Honda Activa'),
            _tile(Icons.confirmation_number_rounded, kPrimary, 'Reg. Number', 'TN58 AX 1234'),
            _tile(Icons.local_gas_station_rounded, kOrange, 'Fuel Allowance', '₹600 / month'),
          ]),
          const SizedBox(height: 14),
          _section('Today\'s Stats', [
            _tile(Icons.check_circle_rounded, kGreen, 'Delivered Today', '—'),
            _tile(Icons.add_circle_rounded, kOrange, 'Extra Fees Raised', '—'),
            _tile(Icons.schedule_rounded, kPrimary, 'Shift Time', '5:00 AM – 9:00 AM'),
          ]),
          const SizedBox(height: 14),
          _section('Support', [
            _tile(Icons.headset_mic_rounded, kPrimary, 'Contact Admin', '+91 98765 43210'),
            _tile(Icons.help_outline_rounded, kTextMid, 'Help Center', 'FAQs & guides'),
          ]),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: kRedLt, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF09595))),
              child: const Center(child: Text('Sign Out',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kRed))),
            ),
          ),
          const SizedBox(height: 8),
        ])),
    ]),
  );

  Widget _section(String title, List<Widget> tiles) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextDark, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      Container(decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Column(children: tiles)),
    ],
  );

  Widget _tile(IconData icon, Color color, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
    child: Row(children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 16)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: kTextMid, fontWeight: FontWeight.w500))),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextDark)),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right_rounded, color: kTextLight, size: 18),
    ]),
  );
}
