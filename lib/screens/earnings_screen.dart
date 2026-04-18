import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/theme.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  EarningsData? _data;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/driver/earnings');
      setState(() { _data = EarningsData.fromJson(res['data']); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: Column(children: [
      _buildHeader(),
      if (_loading)
        const Expanded(child: Center(child: CircularProgressIndicator(color: kGreen)))
      else
        Expanded(child: RefreshIndicator(onRefresh: _load, color: kGreen,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            // 3 stat boxes
            Row(children: [
              Expanded(child: _statBox('Today', '${_data?.deliveredToday ?? 0}', Icons.local_shipping_rounded, kPrimaryLt, kPrimary)),
              const SizedBox(width: 10),
              Expanded(child: _statBox('Extra Fees', '${_data?.extraToday ?? 0}×₹10', Icons.add_circle_rounded, kOrangeLt, kOrange)),
              const SizedBox(width: 10),
              Expanded(child: _statBox('Monthly', '₹${(_data?.monthlyTotal ?? 0).toStringAsFixed(0)}', Icons.trending_up_rounded, kGreenLt, kGreen)),
            ]),
            const SizedBox(height: 20),
            const DSectionTitle(title: 'Daily Breakdown'),
            const SizedBox(height: 10),
            if (_data?.recentEarnings.isEmpty ?? true)
              DCard(child: const Center(child: Text('No earnings recorded yet',
                  style: TextStyle(color: kTextLight, fontSize: 12))))
            else
              ...?_data?.recentEarnings.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6), child: _dayRow(e))),
            const SizedBox(height: 20),
            // Summary breakdown card
            const DSectionTitle(title: 'Monthly Summary'),
            const SizedBox(height: 10),
            DCard(child: Column(children: [
              _feeRow('Base delivery pay',
                  '₹${(_data?.recentEarnings.fold(0.0, (s, e) => s + e.baseAmount) ?? 0).toStringAsFixed(0)}', false),
              const SizedBox(height: 8),
              // Extra fee highlighted in orange
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: kOrangeLt, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFCC80))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: const [
                    Icon(Icons.warning_rounded, color: kOrange, size: 14), SizedBox(width: 6),
                    Text('Special delivery fees (₹10/trip)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kOrange)),
                  ]),
                  Text('₹${(_data?.recentEarnings.fold(0.0, (s, e) => s + e.extraAmount) ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kOrange)),
                ]),
              ),
              const SizedBox(height: 8),
              _feeRow('Performance bonus', '₹0', false),
              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: kBorder, height: 1)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Earned', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
                Text('₹${(_data?.monthlyTotal ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kGreen)),
              ]),
            ])),
            const SizedBox(height: 8),
          ]),
        )),
    ]),
  );

  Widget _buildHeader() => Container(
    color: kGreen,
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(children: [
        Row(children: [
          const DAvatar(initials: 'RV'),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('My Earnings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('This month', style: TextStyle(fontSize: 11, color: Color(0xFFA5D6A7))),
          ])),
        ]),
        const SizedBox(height: 16),
        Container(width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            const Text('TOTAL EARNED THIS MONTH',
                style: TextStyle(fontSize: 9, color: Color(0xFFA5D6A7), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text('₹${(_data?.monthlyTotal ?? 0).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text('${_data?.deliveredToday ?? 0} delivered today · ${_data?.extraToday ?? 0} extra fees',
                style: const TextStyle(fontSize: 10, color: Color(0xFFA5D6A7))),
          ]),
        ),
      ]),
    )),
  );

  Widget _statBox(String label, String value, IconData icon, Color bg, Color color) =>
      DCard(padding: const EdgeInsets.all(12), child: Column(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: kTextLight, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]));

  Widget _dayRow(DayEarning e) => DCard(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    child: Row(children: [
      SizedBox(width: 56, child: Text(e.shortDate,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextDark))),
      const SizedBox(width: 8),
      Expanded(child: Row(children: [
        const Icon(Icons.local_shipping_rounded, size: 13, color: kPrimary), const SizedBox(width: 3),
        Text('${e.deliveries} deliveries', style: const TextStyle(fontSize: 10, color: kTextMid)),
        if (e.extraFees > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: kOrangeLt, borderRadius: BorderRadius.circular(20)),
            child: Text('+${e.extraFees}×₹10',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: kOrange))),
        ],
      ])),
      Text('₹${e.totalAmount.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kGreen)),
    ]),
  );

  Row _feeRow(String label, String val, bool orange) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: kTextMid))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: orange ? kOrange : kTextDark)),
      ]);
}
