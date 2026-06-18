import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';
import '../providers/tournament_list_provider.dart';
import '../services/poster_scan_service.dart';

class AddTournamentScreen extends ConsumerStatefulWidget {
  const AddTournamentScreen({super.key, this.posterScanService});

  final PosterScanService? posterScanService;

  @override
  ConsumerState<AddTournamentScreen> createState() => _AddTournamentScreenState();
}

class _AddTournamentScreenState extends ConsumerState<AddTournamentScreen> {
  final _nameController = TextEditingController();
  final _buyInController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isScanning = false;

  late final PosterScanService _posterScanService =
      widget.posterScanService ?? PosterScanService();

  static const int _maxPosterImageBytes = 4 * 1024 * 1024;

  @override
  void dispose() {
    _nameController.dispose();
    _buyInController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  /// 카메라/갤러리 선택 바텀시트를 띄우고, 선택된 소스로 포스터 스캔을 진행한다
  Future<void> _showPosterScanSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.neonGreen),
              title: const Text('카메라로 촬영', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.neonGreen),
              title: const Text('갤러리에서 선택', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickAndScanPoster(source);
    }
  }

  /// XFile이 보고하는 mimeType이 비어있는 플랫폼(특히 데스크톱)을 대비해
  /// 확장자 기반으로도 추정하는 보조 로직 - 서버가 허용하는 3종 형식만 통과시킨다
  String? _resolveMimeType(XFile file) {
    final reported = file.mimeType;
    if (reported == 'image/jpeg' || reported == 'image/png' || reported == 'image/webp') {
      return reported;
    }
    final path = file.path.toLowerCase();
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    return null;
  }

  /// 이미지 선택 -> 크기/형식 검증 -> Base64 인코딩 -> scanPoster 호출 -> 폼 필드 자동 채움
  /// (CLAUDE.md: 외부 호출 try-catch 필수. AI 결과는 사용자가 검토/수정 가능하도록 폼에만 채워두고 자동 저장하지 않음)
  Future<void> _pickAndScanPoster(ImageSource source) async {
    if (_isScanning) return;

    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.length > _maxPosterImageBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미지 용량이 너무 큽니다. 더 작은 이미지로 다시 시도해 주세요.'),
              backgroundColor: AppColors.negative,
            ),
          );
        }
        return;
      }

      final mimeType = _resolveMimeType(picked);
      if (mimeType == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('지원하지 않는 이미지 형식입니다.'),
              backgroundColor: AppColors.negative,
            ),
          );
        }
        return;
      }

      setState(() => _isScanning = true);

      final result = await _posterScanService.scanPoster(
        imageBase64: base64Encode(bytes),
        mimeType: mimeType,
      );

      if (!mounted) return;

      setState(() {
        final name = result.name;
        if (name != null && name.isNotEmpty) {
          _nameController.text = name;
        }
        final buyIn = result.buyIn;
        if (buyIn != null) {
          _buyInController.text =
              buyIn == buyIn.roundToDouble() ? buyIn.toInt().toString() : buyIn.toString();
        }
        final date = result.date;
        if (date != null) {
          final parsedDate = DateTime.tryParse(date);
          if (parsedDate != null) _selectedDate = parsedDate;
        }
      });

      final warning = result.warning;
      if (warning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(warning), backgroundColor: AppColors.surfaceVariant),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('포스터 분석 실패: $e'), backgroundColor: AppColors.negative),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final buyIn = double.tryParse(_buyInController.text.trim()) ?? 0.0;
      await ref.read(tournamentListProvider.notifier).addTournament(
            name,
            _selectedDate,
            buyIn,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty && !_isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('토너먼트 기록'),
        actions: [
          IconButton(
            onPressed: _isScanning ? null : _showPosterScanSheet,
            tooltip: '포스터로 채우기',
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.neonGreen,
                    ),
                  )
                : const Icon(Icons.document_scanner_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          const Text(
            '이름 / 장소',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: '예: WSOP Main Event, 강남 OO포커클럽',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neonGreen),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '날짜',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '바이인',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _buyInController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.]'))],
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              suffixText: '\$',
              suffixStyle: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neonGreen),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton(
          onPressed: canSave ? _save : null,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : const Text('저장'),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }
}
