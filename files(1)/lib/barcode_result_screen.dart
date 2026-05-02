// ============================================================
// barcode_result_screen.dart — product lookup + next steps
//
// Pulls product data from Open Food Facts (OFF) when possible and
// merges it into the in-flight [ScanRecord]. Users can still override
// missing fields via manual entry.
// ============================================================

import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'app_theme.dart';
import 'color_scan_screen.dart';
import 'gps_screen.dart';
import 'models/product_info.dart';
import 'models/scan_record.dart';

class BarcodeResultScreen extends StatefulWidget {
  final String barcode;
  final String formatLabel;
  final ScanRecord scanRecord;
  final List<CameraDescription> cameras;

  const BarcodeResultScreen({
    super.key,
    required this.barcode,
    required this.formatLabel,
    required this.scanRecord,
    required this.cameras,
  });

  @override
  State<BarcodeResultScreen> createState() => _BarcodeResultScreenState();
}

class _BarcodeResultScreenState extends State<BarcodeResultScreen> {
  late ScanRecord _record;
  ProductInfo? _product;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _record = widget.scanRecord.copyWith(barcode: widget.barcode);
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await fetchOpenFoodFacts(widget.barcode);
      if (!mounted) return;
      setState(() {
        _product = info;
        _loading = false;
        if (info != null) {
          _record = _record.mergeProduct(info);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  String _displayBarcode(String digits) {
    if (digits.length == 13) {
      return '${digits.substring(0, 1)} ${digits.substring(1, 7)} ${digits.substring(7)}';
    }
    if (digits.length == 8) {
      return '${digits.substring(0, 4)} ${digits.substring(4)}';
    }
    return digits;
  }

  bool _bestBeforeSoon() {
    final String? iso = _record.bestBeforeIso;
    if (iso == null) return false;
    final d = DateTime.tryParse(iso);
    if (d == null) return false;
    return !d.difference(DateTime.now()).isNegative &&
        d.difference(DateTime.now()).inDays <= 7;
  }

  Future<void> _openManualForm() async {
    final name = TextEditingController(text: _product?.productName ?? '');
    final brand = TextEditingController(text: _product?.brand ?? '');
    final weight = TextEditingController(text: _product?.weight ?? '');
    final batch = TextEditingController(text: _product?.batchNo ?? '');
    DateTime? bb = _product?.bestBefore;

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          backgroundColor: kDarkBlue,
          title: const Text('Manual product entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  controller: brand,
                  decoration: const InputDecoration(labelText: 'Brand'),
                ),
                TextField(
                  controller: weight,
                  decoration: const InputDecoration(labelText: 'Weight'),
                ),
                TextField(
                  controller: batch,
                  decoration: const InputDecoration(labelText: 'Batch Number'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(
                    bb == null ? 'Best before' : DateFormat.yMMMd().format(bb!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                      initialDate: bb ?? now,
                    );
                    if (picked != null) setModal(() => bb = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kOrange),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      final manual = ProductInfo(
        barcode: widget.barcode,
        formatLabel: widget.formatLabel,
        productName: name.text.trim().isEmpty ? 'Unknown product' : name.text.trim(),
        brand: brand.text.trim().isEmpty ? 'Unknown brand' : brand.text.trim(),
        weight: weight.text.trim().isEmpty ? null : weight.text.trim(),
        batchNo: batch.text.trim().isEmpty ? null : batch.text.trim(),
        bestBefore: bb,
        manufacturerName: brand.text.trim().isEmpty ? 'Unknown manufacturer' : brand.text.trim(),
        manufacturerEmail: ProductInfo.placeholderEmailForBrand(brand.text.trim().isEmpty ? 'brand' : brand.text),
        manufacturerCountry: '—',
        certificationNotes: '',
        fromOpenFoodFacts: false,
      );
      setState(() {
        _product = manual;
        _record = _record.mergeProduct(manual);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProductInfo? p = _product;
    final bool fromOff = p?.fromOpenFoodFacts ?? false;

    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Product Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kOrange),
                ),
                child: Text(
                  _loading ? '…' : 'NG',
                  style: const TextStyle(
                    color: kOrange,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                /// Barcode badge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kBlue.withAlpha(56),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBlue.withAlpha(120)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_rounded, color: kBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayBarcode(widget.barcode),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.formatLabel.replaceAll('_', '-').toUpperCase(),
                              style: TextStyle(color: Colors.white.withAlpha(180)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  p?.productName ?? 'Unknown product',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (p?.brand ?? 'Brand unknown').toUpperCase(),
                  style: const TextStyle(
                    color: kOrange,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                _infoGrid(p),

                const SizedBox(height: 18),

                _manufacturerCard(p),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: fromOff ? const Color(0xFF22C55E) : kModerate,
                      size: 10,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fromOff ? 'Data from Open Food Facts' : 'Product not in database',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    if (!fromOff && !_loading)
                      TextButton(
                        onPressed: _openManualForm,
                        child: const Text('Add manually'),
                      ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: const TextStyle(color: kUnsafe)),
                  ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final updated = await Navigator.of(context).push<ScanRecord>(
                            MaterialPageRoute(
                              builder: (_) => GpsScreen(record: _record),
                            ),
                          );
                          if (updated != null && mounted) {
                            setState(() => _record = updated);
                          }
                        },
                        child: const Text('View GPS Location'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: kOrange),
                        onPressed: () async {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => ColorScanScreen(
                                cameras: widget.cameras,
                                record: _record,
                              ),
                            ),
                          );
                        },
                        child: const Text('Scan SafeInk Ring'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _infoGrid(ProductInfo? p) {
    final String cat = p?.category ?? '—';
    final String w = p?.weight ?? '—';
    final String batch = p?.batchNo ?? '—';
    final String bb = p?.bestBefore == null
        ? '—'
        : DateFormat.yMMMd().format(p!.bestBefore!);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _miniCard('Category', cat),
        _miniCard('Weight', w),
        _miniCard('Batch No.', batch),
        _miniCard(
          'Best Before',
          bb,
          valueColor: _bestBeforeSoon() ? kOrange : Colors.white,
        ),
      ],
    );
  }

  Widget _miniCard(String title, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDarkBlue.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12)),
          const Spacer(),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _manufacturerCard(ProductInfo? p) {
    final name = p?.manufacturerName ?? 'Unknown manufacturer';
    final email = p?.manufacturerEmail ?? '—';
    final country = p?.manufacturerCountry ?? '—';
    final cert = p?.certificationNotes.isNotEmpty == true ? p!.certificationNotes : 'Community dataset';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBlue.withAlpha(40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBlue.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.factory_outlined, color: kBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kBlue.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Verified Manufacturer',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Email: $email', style: const TextStyle(color: Colors.white70)),
          Text('Country: $country', style: const TextStyle(color: Colors.white70)),
          Text('Certification: $cert', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

// ── Open Food Facts (no API key) ───────────────────────────

Future<ProductInfo?> fetchOpenFoodFacts(String barcode) async {
  final uri = Uri.parse(
    'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
  );
  final res = await http.get(uri).timeout(const Duration(seconds: 18));
  if (res.statusCode != 200) {
    return null;
  }
  final map = jsonDecode(res.body) as Map<String, dynamic>;
  final int status = (map['status'] as num?)?.toInt() ?? 0;
  if (status != 1) return null;

  final product = map['product'] as Map<String, dynamic>? ?? {};

  final String productName = (product['product_name'] as String?)?.trim().isNotEmpty == true
      ? product['product_name'] as String
      : 'Unknown product';

  final String brandsRaw = (product['brands'] as String?)?.trim() ?? '';
  final String brand =
      brandsRaw.isEmpty ? 'Unknown brand' : brandsRaw.split(',').first.trim();

  final String? quantity = (product['quantity'] as String?)?.trim();

  String? categories;
  final List<dynamic>? cats = product['categories_tags'] as List<dynamic>?;
  if (cats != null && cats.isNotEmpty) {
    categories = cats.first.toString().replaceAll('en:', '').replaceAll('-', ' ');
  } else {
    categories = (product['categories'] as String?)?.split(',').first.trim();
  }

  final String? batch = (product['lot_number'] as String?)?.trim();

  DateTime? bestBefore;
  final String? exp = (product['expiration_date'] as String?)?.trim();
  if (exp != null && exp.isNotEmpty) {
    bestBefore = DateTime.tryParse(exp) ?? _tryOffDate(exp);
  }

  String country = '—';
  final String? countries = (product['countries'] as String?)?.trim();
  if (countries != null && countries.isNotEmpty) {
    country = countries.split(',').first.trim();
  }

  final String places =
      (product['manufacturing_places'] as String?)?.trim() ?? '';
  final String cert = places.isNotEmpty
      ? 'Manufacturing: $places'
      : 'Open Food Facts community listing';

  final String mName = brand;

  return ProductInfo(
    barcode: barcode,
    formatLabel: 'Open Food Facts',
    productName: productName,
    brand: brand,
    category: categories,
    weight: quantity,
    batchNo: batch,
    bestBefore: bestBefore,
    manufacturerName: mName,
    manufacturerEmail: ProductInfo.placeholderEmailForBrand(brand),
    manufacturerCountry: country,
    certificationNotes: cert,
    fromOpenFoodFacts: true,
  );
}

DateTime? _tryOffDate(String raw) {
  // OFF sometimes uses dd/mm/yyyy
  final parts = raw.split(RegExp(r'[/.-]'));
  if (parts.length == 3) {
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);
    if (a != null && b != null && c != null) {
      if (c > 31) {
        return DateTime(c, a, b);
      }
    }
  }
  return null;
}
