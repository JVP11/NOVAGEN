// ============================================================
// history_screen.dart — persisted scan timeline
//
// Reads JSON snapshots from [ScanHistory] and surfaces quick
// stats, search, and a detailed bottom sheet per entry.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_theme.dart';
import 'models/scan_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _search = TextEditingController();
  List<ScanRecord> _all = <ScanRecord>[];
  List<ScanRecord> _filtered = <ScanRecord>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pull();
    _search.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pull() async {
    setState(() => _loading = true);
    final rows = await ScanHistory.loadAll();
    if (!mounted) return;
    setState(() {
      _all = rows;
      _filtered = rows;
      _loading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = List<ScanRecord>.from(_all));
      return;
    }
    setState(() {
      _filtered = _all.where((e) {
        return e.productName.toLowerCase().contains(q) ||
            e.barcode.toLowerCase().contains(q);
      }).toList();
    });
  }

  (int, int, int) _stats() {
    int s = 0, m = 0, u = 0;
    for (final e in _all) {
      switch (e.safetyStatus) {
        case 'safe':
          s++;
          break;
        case 'moderate':
          m++;
          break;
        case 'unsafe':
          u++;
          break;
        default:
          break;
      }
    }
    return (s, m, u);
  }

  Color _dot(String status) {
    switch (status) {
      case 'safe':
        return kSafe;
      case 'moderate':
        return kModerate;
      default:
        return kUnsafe;
    }
  }

  void _openDetail(ScanRecord r) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kDarkBlue,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.95,
        minChildSize: 0.45,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              r.productName.isEmpty ? 'Unknown product' : r.productName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Barcode: ${r.barcode}', style: const TextStyle(color: kOrange)),
            const SizedBox(height: 16),
            _detailRow('Manufacturer', r.manufacturerName),
            _detailRow('Email', r.manufacturerEmail),
            _detailRow('Batch', r.batchNo),
            _detailRow('Safety', '${r.safetyStatus.toUpperCase()} • ${r.safetyPercent}%'),
            _detailRow('Colour', r.detectedColorHex),
            _detailRow('HSV', '${r.hue.toStringAsFixed(1)}° / ${(r.saturation * 100).toStringAsFixed(0)}% / ${(r.value * 100).toStringAsFixed(0)}%'),
            _detailRow('GPS', r.latitude == null ? '—' : '${r.latitude}, ${r.longitude}'),
            _detailRow('Address', r.address.isEmpty ? '—' : r.address),
            _detailRow('When', DateFormat.yMMMd().add_jm().format(DateTime.tryParse(r.scanDateTimeIso) ?? DateTime.now())),
            _detailRow('Alert sent', r.alertSent ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: TextStyle(color: Colors.white.withAlpha(160))),
          Text(v),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (safeC, modC, badC) = _stats();

    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: const Text('Scan history'),
        actions: [
          IconButton(onPressed: _pull, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      _statChip('Safe', safeC, kSafe),
                      const SizedBox(width: 10),
                      _statChip('Warn', modC, kModerate),
                      const SizedBox(width: 10),
                      _statChip('Risk', badC, kUnsafe),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: kBlue),
                      hintText: 'Search product or barcode…',
                      fillColor: kDarkBlue.withAlpha(200),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final r = _filtered[i];

                      return ListTile(
                        onTap: () => _openDetail(r),
                        leading: CircleAvatar(
                          backgroundColor: _dot(r.safetyStatus),
                          radius: 8,
                        ),
                        title: Text(
                          r.productName.isEmpty ? 'Scan ${r.barcode}' : r.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${r.barcode.isEmpty ? 'No barcode' : r.barcode} • ${r.address.isEmpty ? 'No address' : r.address}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${r.safetyPercent}%',
                              style: TextStyle(color: _dot(r.safetyStatus), fontWeight: FontWeight.bold),
                            ),
                            if (r.alertSent)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kOrange.withAlpha(55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Alerted MFR',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: kDarkBlue.withAlpha(200),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(120)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
