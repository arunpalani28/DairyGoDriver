import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';
import '../widgets/theme.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});
  @override State<DeliveryScreen> createState() => _DeliveryState();
}

class _DeliveryState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  List<DeliveryTask> _tasks = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  late TabController _tabController;
  DriverProfile? _profile;

  @override 
  void initState() { 
    super.initState(); 
    // Initialize TabController immediately
    _tabController = TabController(length: 3, vsync: this);
    _load(); 
    _searchCtrl.addListener(() => setState(() {})); 
  }

  @override 
  void dispose() { 
    _searchCtrl.dispose(); 
    _tabController.dispose();
    super.dispose(); 
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/driver/deliveries');
      final list = (res['data'] as List).map((e) => DeliveryTask.fromJson(e)).toList();
      if (mounted) {
        setState(() { 
          _tasks = list; 
          _loading = false; 
        });
      }
      
      final res1 = await ApiClient.get('/driver/profile');
      setState(() { _profile = DriverProfile.fromJson(res1['data']); _loading = false; });

    } catch (_) { 
      if (mounted) setState(() => _loading = false); 
    }
  }

  List<DeliveryTask> _getFilteredList(String status) {
    final q = _searchCtrl.text.toLowerCase().trim();
    return _tasks.where((t) {
      final matchStatus = t.localStatus == status;
      final matchSearch = q.isEmpty || 
          t.customerName.toLowerCase().contains(q) || 
          t.customerAddress.toLowerCase().contains(q);
      return matchStatus && matchSearch;
    }).toList();
  }

  int _getCount(String status) => _tasks.where((t) => t.localStatus == status).length;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: Column(children: [
      _header(),
      _progressBar(),
      Expanded(
        child: _loading 
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList('PENDING'),
                _buildList('DELIVERED'),
                _buildList('CANCELLED'), 
              ],
            ),
      ),
    ]),
  );

  Widget _buildList(String status) {
    final list = _getFilteredList(status);
    if (list.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(status == 'DELIVERED' ? Icons.check_circle_outline : Icons.inventory_2_outlined, 
             size: 56, color: kTextLight),
        const SizedBox(height: 12),
        Text('No $status deliveries', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextMid)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load, 
      color: kGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(14), 
        itemCount: list.length,
        itemBuilder: (ctx, i) => _DeliveryCard(
          task: list[i],
          onDeliver: (actualMl, distKm, notes) async {
            try {
              await ApiClient.post('/driver/deliveries/${list[i].id}/deliver', {
                'actualQuantityMl': actualMl, 'distanceKm': distKm, 'driverNotes': notes
              });
              await _load(); // Auto-refresh after success
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
            }
          },
          onRaiseExtra: (customerId, itemDesc, qty, distKm) async {
            // ... (keep existing extra logic)
          },
        ),
      ),
    );
  }

  Widget _header() => Container(color: kGreen, child: SafeArea(bottom: false, child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Column(children: [
      Row(children: [
        DAvatar(initials: _profile?.initials ?? 'DV'), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Driver Delivery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(_todayLabel(), style: const TextStyle(fontSize: 11, color: Color(0xFFA5D6A7))),
        ])),
        // Added Refresh Icon, Removed Online Badge
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
        ),
      ]),
      const SizedBox(height: 12),
      TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        tabs: [
          Tab(text: 'PENDING (${_getCount('PENDING')})'),
          Tab(text: 'DONE (${_getCount('DELIVERED')})'),
          Tab(text: 'CANCELED (${_getCount('CANCELLED')})'),
        ],
      ),
      const SizedBox(height: 12),
      Container(decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 8)]),
        child: TextField(controller: _searchCtrl,
          style: const TextStyle(fontSize: 13, color: kTextDark),
          decoration: const InputDecoration(hintText: 'Search by area, name...',
            hintStyle: TextStyle(fontSize: 12, color: kTextLight),
            prefixIcon: Icon(Icons.search_rounded, color: kTextLight, size: 20),
            border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)))),
      const SizedBox(height: 12),
    ]),
  )));

  Widget _progressBar() => Container(color: kGreen, padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('${_getCount('DELIVERED')} of ${_tasks.length} delivered', style: const TextStyle(fontSize: 10, color: Color(0xFFA5D6A7), fontWeight: FontWeight.w600)),
      Text(_tasks.isEmpty ? '0%' : '${(_getCount('DELIVERED') / _tasks.length * 100).round()}%', style: const TextStyle(fontSize: 10, color: Color(0xFFA5D6A7), fontWeight: FontWeight.w700)),
    ]),
    const SizedBox(height: 5),
    ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _tasks.isEmpty ? 0 : _getCount('DELIVERED') / _tasks.length, backgroundColor: Colors.white24, color: const Color(0xFF66BB6A), minHeight: 6)),
  ]));

  String _todayLabel() { 
    final n = DateTime.now(); 
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; 
    return '${n.day} ${m[n.month-1]} ${n.year}'; 
  }
}

// ── Delivery Card (Logic for Canceled/Delivered states) ──────────────────────────
class _DeliveryCard extends StatefulWidget {
  final DeliveryTask task;
  final Future<void> Function(int ml, double km, String notes) onDeliver;
  final Future<void> Function(int customerId, String item, String qty, double km) onRaiseExtra;

  const _DeliveryCard({required this.task, required this.onDeliver, required this.onRaiseExtra});

  @override State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  bool _loadingAction = false;

void _showDeliverDialog() {
    final mlCtrl = TextEditingController(text: '${widget.task.quantityMl}');
    final kmCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, color: kGreen, size: 36),
                ),
                const SizedBox(height: 16),
                
                // Title & Subtitle
                const Text(
                  'Confirm Delivery',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verify the details before submitting',
                  style: TextStyle(fontSize: 12, color: kTextLight),
                ),
                const SizedBox(height: 24),

                // Quantity Input
                _buildProfessionalField(
                  controller: mlCtrl,
                  label: 'ACTUAL QUANTITY',
                  hint: 'Enter quantity',
                  suffix: 'ml',
                  icon: Icons.water_drop_rounded,
                ),
                const SizedBox(height: 16),

                // Distance Input
                _buildProfessionalField(
                  controller: kmCtrl,
                  label: 'TRAVEL DISTANCE',
                  hint: '0.0',
                  suffix: 'km',
                  icon: Icons.add_road_rounded,
                ),
                const SizedBox(height: 28),

                // Action Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          setState(() => _loadingAction = true);
                          
                          final ml = int.tryParse(mlCtrl.text) ?? widget.task.quantityMl;
                          final km = double.tryParse(kmCtrl.text) ?? 0.0;
                          
                          await widget.onDeliver(ml, km, '');
                          
                          if (mounted) setState(() => _loadingAction = false);
                        },
                        child: const Text(
                          'SUBMIT DELIVERY',
                          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Discard Changes',
                        style: TextStyle(color: kTextLight, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // A helper to keep the input fields looking sharp and consistent
  Widget _buildProfessionalField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTextMid, letterSpacing: 0.5),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: kGreen, size: 20),
            suffixText: suffix,
            suffixStyle: const TextStyle(fontWeight: FontWeight.w700, color: kTextLight),
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }


void _showCancelDialog() {
  //final reasonCtrl = TextEditingController();
final String taskId = widget.task.id.toString();
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cancel Delivery?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTextDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure want to cancel delivery?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kTextMid, height: 1.4),
            ),
            const SizedBox(height: 20),
            
            // Styled Reason Field
            // TextField(
            //   controller: reasonCtrl,
            //   maxLines: 2,
            //   style: const TextStyle(fontSize: 13),
            //   decoration: InputDecoration(
            //     hintText: 'Reason (e.g., Customer not available)',
            //     filled: true,
            //     fillColor: Colors.grey.withOpacity(0.05),
            //     contentPadding: const EdgeInsets.all(12),
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(12),
            //       borderSide: BorderSide.none,
            //     ),
            //   ),
            // ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back', style: TextStyle(color: kTextLight, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      
                   await ApiClient.post('/driver/deliveries/${taskId}/cancel', {});
                   
                    },
                    child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final bool isDelivered = t.localStatus == 'DELIVERED';
    final bool isCanceled = t.localStatus == 'CANCELLED';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 4, height: 60, decoration: BoxDecoration(color: isDelivered ? Colors.green : (isCanceled ? Colors.red : Colors.orange), borderRadius: BorderRadius.circular(10))),
                  const SizedBox(width: 10),
                  CircleAvatar(radius: 20, backgroundColor: isDelivered ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    child: Text(t.customerName.isNotEmpty ? t.customerName[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.bold, color: isDelivered ? Colors.green : Colors.blue))),
                ]),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(t.customerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                    _slotChip(t.deliverySlot ?? 'N/A'),
                  ]),
                  const SizedBox(height: 4),
                  Text(t.customerAddress, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Center(child: Column(children: [
                    const Icon(Icons.local_drink, size: 18, color: Colors.blueGrey),
                    Text("${t.actualQuantityMl == 0 ? t.quantityMl : t.actualQuantityMl} ml", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ])),
                ])),
                IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => launchUrl(Uri.parse("tel:${t.customerPhone}"))),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(children: [
              if (!isDelivered && !isCanceled) ...[
                _actionIcon(icon: Icons.check_circle, label: "Deliver", color: Colors.green, onTap: _loadingAction ? null : _showDeliverDialog),
                _actionIcon(icon: Icons.cancel, label: "Cancel", color: Colors.red, onTap: _showCancelDialog),
              ],
              if (isDelivered || isCanceled) _actionIcon(icon: Icons.edit, label: "Edit", color: Colors.blue, onTap: _showDeliverDialog),
              const Spacer(),
              _actionIcon(icon: Icons.add_shopping_cart, label: "Extra", color: Colors.orange, onTap: () {}),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _slotChip(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.blue)));

  Widget _actionIcon({required IconData icon, required String label, required Color color, VoidCallback? onTap}) => InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(children: [Icon(icon, color: color, size: 22), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 10, color: color))])));
}