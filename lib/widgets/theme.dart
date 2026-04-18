import 'package:flutter/material.dart';

// ── Colors ───────────────────────────────────────────────────────────────────
const Color kPrimary   = Color(0xFF1565C0);
const Color kPrimaryLt = Color(0xFFE3F2FD);
const Color kGreen     = Color(0xFF2E7D32);
const Color kGreenLt   = Color(0xFFE8F5E9);
const Color kGreenDk   = Color(0xFF1B5E20);
const Color kOrange    = Color(0xFFE65100);
const Color kOrangeLt  = Color(0xFFFFF3E0);
const Color kOrangeDk  = Color(0xFFBF360C);
const Color kBg        = Color(0xFFEEF3FA);
const Color kCard      = Color(0xFFFFFFFF);
const Color kBorder    = Color(0xFFE3F2FD);
const Color kTextDark  = Color(0xFF1A237E);
const Color kTextMid   = Color(0xFF607D8B);
const Color kTextLight = Color(0xFF90A4AE);
const Color kRed       = Color(0xFFC62828);
const Color kRedLt     = Color(0xFFFCEBEB);

// ── Models ───────────────────────────────────────────────────────────────────
class DeliveryTask {
  final int id, customerId;
  final String customerName, customerAddress, customerPhone;
  final String? customerWhatsapp, deliverySlot;
  final double? customerLat, customerLon;
  final int quantityMl;
  int? actualQuantityMl;
  final double extraFee;
  final bool isExtra;
  String localStatus;
  final String? planName;

  DeliveryTask.fromJson(Map<String, dynamic> j)
      : id = j['id'] ?? 0,
        customerId = j['customerId'] ?? 0,
        customerName = j['customerName'] ?? '',
        customerAddress = j['customerAddress'] ?? '',
        customerPhone = j['customerPhone'] ?? '',
        customerWhatsapp = j['customerWhatsapp'],
        deliverySlot = j['deliverySlot'] ?? 'MORNING',
        customerLat = (j['customerLat'] as num?)?.toDouble(),
        customerLon = (j['customerLon'] as num?)?.toDouble(),
        quantityMl = j['quantityMl'] ?? 500,
        actualQuantityMl = (j['actualQuantityMl'] as num?)?.toInt(),
        extraFee = (j['extraFee'] as num?)?.toDouble() ?? 0.0,
        isExtra = j['isExtra'] ?? false,
        localStatus = j['status'] ?? 'PENDING',
        planName = j['planName'] ?? 'Regular Milk';
}

class EarningsData {
  final double monthlyTotal;
  final int deliveredToday, extraToday;
  final List<DayEarning> recentEarnings;

  EarningsData.fromJson(Map<String, dynamic> j)
      : monthlyTotal = (j['monthlyTotal'] as num?)?.toDouble() ?? 0.0,
        deliveredToday = (j['deliveredToday'] as num?)?.toInt() ?? 0,
        extraToday = (j['extraToday'] as num?)?.toInt() ?? 0,
        recentEarnings = ((j['recentEarnings'] as List?) ?? [])
            .map((e) => DayEarning.fromJson(e)).toList();
}

class DayEarning {
  final String earnDate;
  final int deliveries, extraFees;
  final double baseAmount, extraAmount, totalAmount;

  DayEarning.fromJson(Map<String, dynamic> j)
      : earnDate = j['earnDate'] ?? '',
        deliveries = (j['deliveries'] as num?)?.toInt() ?? 0,
        extraFees = (j['extraFees'] as num?)?.toInt() ?? 0,
        baseAmount = (j['baseAmount'] as num?)?.toDouble() ?? 0.0,
        extraAmount = (j['extraAmount'] as num?)?.toDouble() ?? 0.0,
        totalAmount = (j['totalAmount'] as num?)?.toDouble() ?? 0.0;

  String get shortDate => earnDate.length >= 10 ? earnDate.substring(5) : earnDate;
}

class DriverProfile {
  final int id;
  final String name, email, phone, zone, kycStatus;
  DriverProfile.fromJson(Map<String, dynamic> j)
      : id = j['id'] ?? 0,
        name = j['name'] ?? '',
        email = j['email'] ?? '',
        phone = j['phone'] ?? '',
        zone = j['zone'] ?? '',
        kycStatus = j['kycStatus'] ?? 'VERIFIED';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'DV';
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
class DAvatar extends StatelessWidget {
  final String initials;
  final double size;
  const DAvatar({super.key, required this.initials, this.size = 40});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(size / 2)),
    child: Center(child: Text(initials,
        style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w700, color: Colors.white))),
  );
}

class DCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final double borderWidth;
  const DCard({super.key, required this.child, this.padding, this.borderColor, this.borderWidth = 1});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? kBorder, width: borderWidth),
      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
    ),
    padding: padding ?? const EdgeInsets.all(14),
    child: child,
  );
}

class DActionButton extends StatefulWidget {
  final String label;
  final Color color, darkColor;
  final VoidCallback? onTap;
  final bool loading, compact;
  const DActionButton({super.key, required this.label, required this.color, required this.darkColor, this.onTap, this.loading = false, this.compact = false});
  @override State<DActionButton> createState() => _DActionButtonState();
}
class _DActionButtonState extends State<DActionButton> {
  bool _down = false;
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTapDown: (_) => setState(() => _down = true),
    onTapUp: (_) { setState(() => _down = false); widget.onTap?.call(); },
    onTapCancel: () => setState(() => _down = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.symmetric(vertical: 11, horizontal: widget.compact ? 14 : 0),
      decoration: BoxDecoration(color: _down ? widget.darkColor : widget.color, borderRadius: BorderRadius.circular(10)),
      child: widget.loading
          ? const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          : Center(child: Text(widget.label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
    ),
  );
}

class DSectionTitle extends StatelessWidget {
  final String title;
  const DSectionTitle({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextDark, letterSpacing: 0.3));
}
