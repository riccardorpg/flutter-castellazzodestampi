import 'package:flutter/material.dart';
import 'services/api_service.dart';

class SegnalazioniScreen extends StatefulWidget {
  const SegnalazioniScreen({super.key});

  @override
  State<SegnalazioniScreen> createState() => _SegnalazioniScreenState();
}

class _SegnalazioniScreenState extends State<SegnalazioniScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String _filter = 'all';

  // 4 card demo — mostrate quando l'API è vuota o non raggiungibile
  static const List<Map<String, dynamic>> _demo = [
    {
      'id': '1',
      'type': {'name': 'Illuminazione pubblica'},
      'details': 'Lampione spento in Via Roma 12, zona completamente al buio di notte.',
      'address': 'Via Roma 12, Castellazzo',
      'status': 'pending',
      'status_label': 'In attesa',
      'datetime': '2026-04-07 10:30:00',
    },
    {
      'id': '2',
      'type': {'name': 'Verde pubblico'},
      'details': 'Albero pericolante nel parco centrale, rami sporgenti sulla strada.',
      'address': 'Parco Centrale, Castellazzo',
      'status': 'resolved',
      'status_label': 'Risolta',
      'datetime': '2026-03-28 14:15:00',
    },
    {
      'id': '3',
      'type': {'name': 'Guasto tecnico'},
      'details': 'Perdita d\'acqua dal tombino all\'incrocio con Via Mazzini.',
      'address': 'Via Mazzini, Castellazzo',
      'status': 'rejected',
      'status_label': 'Rifiutata',
      'datetime': '2026-03-25 09:00:00',
    },
    {
      'id': '4',
      'type': {'name': 'Sicurezza stradale'},
      'details': 'Buca profonda nel marciapiede, rischio caduta per i pedoni.',
      'address': 'Via Garibaldi 45, Castellazzo',
      'status': 'pending',
      'status_label': 'In attesa',
      'datetime': '2026-04-01 16:45:00',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    final result = await ApiService.getMyReports();
    if (!mounted) return;
    final data = result['success'] == true
        ? List<Map<String, dynamic>>.from(result['data'] as List)
        : <Map<String, dynamic>>[];
    setState(() {
      _reports = data.isEmpty
          ? List<Map<String, dynamic>>.from(_demo)
          : data;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _reports;
    return _reports.where((r) => r['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset('android/app/src/main/res/drawable/logo.png'),
        ),
        title: const Text(
          'Le mie segnalazioni',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Filtri ────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tutte',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'In attesa',
                  selected: _filter == 'pending',
                  onTap: () => setState(() => _filter = 'pending'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Risolte',
                  selected: _filter == 'resolved',
                  onTap: () => setState(() => _filter = 'resolved'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Rifiutate',
                  selected: _filter == 'rejected',
                  onTap: () => setState(() => _filter = 'rejected'),
                ),
              ],
            ),
          ),
          // ── Lista ─────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF666666), size: 20),
              SizedBox(width: 8),
              Text(
                'Nuova',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7BA566)));
    }
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'Nessuna segnalazione in questa categoria.',
              style: TextStyle(color: Color(0xFF888888), fontFamily: 'Inter'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF7BA566),
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _ReportCard(report: list[i]),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportCard({required this.report});

  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);   // giallo
      case 'resolved':
        return const Color(0xFF7BA566);   // verde
      case 'rejected':
        return const Color(0xFFEF4444);   // rosso
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  static String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = report['type'] as Map<String, dynamic>?;
    final typeName = type?['name'] as String? ?? '—';
    final details = report['details'] as String? ?? '';
    final address = report['address'] as String? ?? '';
    final status = report['status'] as String? ?? '';
    final statusLabel = report['status_label'] as String? ?? status;
    final datetime = report['datetime'] as String? ?? '';
    final id = report['id']?.toString() ?? '';
    final color = statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    typeName,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Badge stato
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 13,
                    fontFamily: 'Inter'),
              ),
            ],
            if (address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(
                  _formatDate(datetime),
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontFamily: 'Inter'),
                ),
                const Spacer(),
                Text(
                  '#$id',
                  style: const TextStyle(
                    color: Color(0xFF7BA566),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip filtro ───────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF555555) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(color: const Color(0xFFCCCCCC)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF555555),
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
