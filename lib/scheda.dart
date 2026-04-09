import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'segnalazioni.dart';
import 'services/api_service.dart';

class FormScreen extends StatefulWidget {
  final Map<String, dynamic> reportType;

  const FormScreen({super.key, required this.reportType});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _detailsController = TextEditingController();
  final _addressController = TextEditingController();
  final _picker = ImagePicker();

  List<XFile> _images = [];
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _detailsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ── GPS ────────────────────────────────────────────────────────

  Future<void> _getLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _error = 'Permesso posizione negato.';
          _locating = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locating = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossibile ottenere la posizione.';
        _locating = false;
      });
    }
  }

  // ── Galleria ───────────────────────────────────────────────────

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() => _images = [..._images, ...picked]);
      }
    } catch (_) {
      // pickMultiImage non disponibile, fallback a singola immagine
      try {
        final single =
            await _picker.pickImage(source: ImageSource.gallery);
        if (single != null) {
          setState(() => _images = [..._images, single]);
        }
      } catch (e) {
        setState(() => _error = 'Impossibile accedere alla galleria.');
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  // ── Submit ─────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_detailsController.text.trim().isEmpty) {
      setState(() => _error = 'Inserisci una descrizione.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ApiService.createReport(
      typeId: widget.reportType['id'].toString(),
      details: _detailsController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      latitude: _latitude?.toString(),
      longitude: _longitude?.toString(),
      imagePaths: _images.map((x) => x.path).toList(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SegnalazioniScreen()),
      );
    } else {
      setState(() =>
          _error = result['message'] as String? ?? 'Errore durante l\'invio.');
    }
  }

  // ── UI ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final typeName = widget.reportType['name'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF111111), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nuova Segnalazione',
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge tipo
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.label_outline,
                            color: Color(0xFF7BA566), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          typeName,
                          style: const TextStyle(
                            color: Color(0xFF7BA566),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Descrizione ──────────────────────────────
                  _sectionLabel('DESCRIZIONE DETTAGLIATA'),
                  const SizedBox(height: 8),
                  _fieldBox(
                    child: TextField(
                      controller: _detailsController,
                      maxLines: 5,
                      style: _inputStyle,
                      decoration: const InputDecoration(
                        hintText: 'Descrivi il problema nel dettaglio…',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Indirizzo ────────────────────────────────
                  _sectionLabel('INDIRIZZO (opzionale)'),
                  const SizedBox(height: 8),
                  _fieldBox(
                    child: TextField(
                      controller: _addressController,
                      style: _inputStyle,
                      decoration: const InputDecoration(
                        hintText: 'Es. Via Roma 12, Castellazzo…',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                        prefixIcon: Icon(Icons.location_on_outlined,
                            color: Color(0xFF9CA3AF), size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── GPS ──────────────────────────────────────
                  _sectionLabel('POSIZIONE GPS (opzionale)'),
                  const SizedBox(height: 8),
                  if (_latitude != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF16A34A), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_latitude!.toStringAsFixed(6)}, '
                              '${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(
                                () => _latitude = _longitude = null),
                            child: const Icon(Icons.close,
                                color: Color(0xFF16A34A), size: 16),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _locating ? null : _getLocation,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7BA566),
                          side: const BorderSide(color: Color(0xFF7BA566)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _locating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF7BA566)),
                              )
                            : const Icon(Icons.my_location, size: 16),
                        label: Text(
                          _locating
                              ? 'Acquisizione…'
                              : 'Usa posizione attuale',
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 13),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ── Foto ─────────────────────────────────────
                  _sectionLabel('FOTO (opzionale)'),
                  const SizedBox(height: 8),
                  if (_images.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_images.length, (i) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_images[i].path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removeImage(i),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7BA566),
                        side: const BorderSide(color: Color(0xFF7BA566)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add_photo_alternate_outlined,
                          size: 16),
                      label: Text(
                        _images.isEmpty
                            ? 'Aggiungi foto dalla galleria'
                            : 'Aggiungi altre foto',
                        style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 13),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Bottone INVIA fisso ───────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7BA566),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF7BA566).withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'INVIA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF444444),
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  static Widget _fieldBox({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: child,
      );

  static const TextStyle _inputStyle = TextStyle(
    color: Color(0xFF111111),
    fontSize: 14,
    fontFamily: 'Inter',
  );
}
