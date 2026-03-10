import 'package:flutter/material.dart';
import '../../core/spc/imr_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'imr_chart.dart';

/// Virtual-windowed I-MR grafiği.
///
/// Aynı anda [windowSize] nokta gösterir. Kullanıcı ← → ok tuşları veya
/// kaydırma çubuğuyla geçmişe gidebilir; CANLI butonu en son veriye döner.
/// RAM'de en fazla [windowSize × bufferFactor] satır tutulur; geri kalanı
/// sunucudan [fetcher] callback'i ile HTTP üzerinden sayfalı çekilir.
class WindowedImrChart extends StatefulWidget {
  const WindowedImrChart({
    super.key,
    required this.fetcher,
    required this.totalCount,
    this.windowSize = 300,
    this.bufferFactor = 3,
    this.title = 'I-MR Kontrol Diyagramı',
    this.yAxisLabel = '',
    this.height = 440,
  });

  /// (offset, limit) → o aralıktaki ölçüm değerleri listesi.
  final Future<List<double>> Function(int offset, int limit) fetcher;

  /// Dosyadaki toplam kayıt sayısı.
  final int totalCount;

  /// Grafik'te bir anda görünen nokta sayısı.
  final int windowSize;

  /// RAM tamponu = windowSize × bufferFactor.
  final int bufferFactor;

  final String title;
  final String yAxisLabel;
  final double height;

  @override
  State<WindowedImrChart> createState() => _WindowedImrChartState();
}

class _WindowedImrChartState extends State<WindowedImrChart> {
  List<double> _buffer = [];
  int _bufferOffset = 0; // buffer'ın dosya indeksi başlangıcı
  int _viewOffset = 0;   // görünen pencerenin dosya indeksi başlangıcı
  bool _loading = false;
  bool _isLive = true;

  int get _bufferSize => widget.windowSize * widget.bufferFactor;
  int get _maxView => (widget.totalCount - widget.windowSize).clamp(0, widget.totalCount);

  @override
  void initState() {
    super.initState();
    _jumpToLive(force: true);
  }

  @override
  void didUpdateWidget(covariant WindowedImrChart old) {
    super.didUpdateWidget(old);
    // Canlı moddayken yeni veri gelirse güncelle
    if (_isLive && old.totalCount != widget.totalCount) {
      _jumpToLive();
    }
  }

  Future<void> _jumpToLive({bool force = false}) async {
    if (widget.totalCount == 0) return;
    await _loadBuffer(_maxView, force: force);
  }

  Future<void> _loadBuffer(int newViewOffset, {bool force = false}) async {
    if (_loading && !force) return;
    final clampedView = newViewOffset.clamp(0, _maxView);

    // Yeni buffer penceresi: viewOffset'ten bir windowSize önce başla
    final newBufStart = (clampedView - widget.windowSize).clamp(0, widget.totalCount);
    final newBufEnd = (newBufStart + _bufferSize).clamp(0, widget.totalCount);
    final actualBufSize = newBufEnd - newBufStart;

    // Mevcut buffer kapsıyorsa sadece view'u güncelle (HTTP isteği yok)
    if (!force &&
        _buffer.isNotEmpty &&
        newBufStart >= _bufferOffset &&
        newBufEnd <= _bufferOffset + _buffer.length) {
      setState(() {
        _viewOffset = clampedView;
        _isLive = clampedView >= _maxView;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await widget.fetcher(newBufStart, actualBufSize);
      if (!mounted) return;
      setState(() {
        _buffer = data;
        _bufferOffset = newBufStart;
        _viewOffset = clampedView;
        _isLive = clampedView >= _maxView;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<double> _getWindow() {
    if (_buffer.isEmpty) return [];
    final localStart = (_viewOffset - _bufferOffset).clamp(0, _buffer.length);
    final localEnd = (localStart + widget.windowSize).clamp(0, _buffer.length);
    return _buffer.sublist(localStart, localEnd);
  }

  @override
  Widget build(BuildContext context) {
    final values = _getWindow();
    final hasData = values.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NavBar(
          viewOffset: _viewOffset,
          windowSize: widget.windowSize,
          totalCount: widget.totalCount,
          isLive: _isLive,
          loading: _loading,
          canBack: _viewOffset > 0,
          canForward: !_isLive,
          onBack: () => _loadBuffer(_viewOffset - widget.windowSize),
          onForward: () => _loadBuffer(_viewOffset + widget.windowSize),
          onLive: _jumpToLive,
          onSliderChanged: (ratio) => _loadBuffer((ratio * _maxView).round()),
        ),
        const SizedBox(height: 8),

        if (_loading && !hasData)
          SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (!hasData)
          SizedBox(
            height: widget.height,
            child: Center(
              child: Text('Yeterli veri yok.', style: AppTextStyles.bodyMuted),
            ),
          )
        else
          Stack(
            children: [
              ImrChart(
                result: ImrCalculator.calculate(values),
                title: widget.title,
                yAxisLabel: widget.yAxisLabel,
                maxPoints: values.length,
                height: widget.height,
              ),
              if (_loading)
                Positioned.fill(
                  child: Container(
                    color: AppColors.cardBg.withValues(alpha: 0.65),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ─── Navigation Bar ──────────────────────────────────────────────────────────

class _NavBar extends StatefulWidget {
  const _NavBar({
    required this.viewOffset,
    required this.windowSize,
    required this.totalCount,
    required this.isLive,
    required this.loading,
    required this.canBack,
    required this.canForward,
    required this.onBack,
    required this.onForward,
    required this.onLive,
    required this.onSliderChanged,
  });

  final int viewOffset;
  final int windowSize;
  final int totalCount;
  final bool isLive;
  final bool loading;
  final bool canBack;
  final bool canForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final Future<void> Function() onLive;
  final ValueChanged<double> onSliderChanged;

  @override
  State<_NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<_NavBar> {
  double? _dragRatio; // slider sürüklenirken geçici değer

  @override
  Widget build(BuildContext context) {
    final maxView = (widget.totalCount - widget.windowSize).clamp(0, widget.totalCount);
    final committedRatio =
        maxView > 0 ? (widget.viewOffset / maxView).clamp(0.0, 1.0) : 1.0;
    final displayRatio = _dragRatio ?? committedRatio;
    final displayOffset = (displayRatio * maxView).round().clamp(0, maxView);
    final viewEnd = (displayOffset + widget.windowSize).clamp(0, widget.totalCount);
    final canSlide = widget.totalCount > widget.windowSize && !widget.loading;

    return Row(
      children: [
        // ← Önceki sayfa
        IconButton(
          onPressed: widget.canBack && !widget.loading ? widget.onBack : null,
          icon: const Icon(Icons.chevron_left_rounded),
          iconSize: 22,
          color: AppColors.primary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Önceki sayfa',
        ),

        // Zaman kaydırma çubuğu
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: AppColors.primary,
                  disabledThumbColor: AppColors.border,
                  disabledActiveTrackColor: AppColors.border,
                ),
                child: Slider(
                  value: displayRatio,
                  onChanged: canSlide
                      ? (v) => setState(() => _dragRatio = v)
                      : null,
                  onChangeEnd: canSlide
                      ? (v) {
                          setState(() => _dragRatio = null);
                          widget.onSliderChanged(v);
                        }
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  '$displayOffset – $viewEnd  /  ${widget.totalCount} kayıt',
                  style: AppTextStyles.chartAxis
                      .copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),

        // → Sonraki sayfa
        IconButton(
          onPressed: widget.canForward && !widget.loading ? widget.onForward : null,
          icon: const Icon(Icons.chevron_right_rounded),
          iconSize: 22,
          color: AppColors.primary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Sonraki sayfa',
        ),

        const SizedBox(width: 6),

        // CANLI butonu
        GestureDetector(
          onTap: !widget.isLive && !widget.loading ? widget.onLive : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isLive
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.isLive ? AppColors.success : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.isLive ? AppColors.success : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'CANLI',
                  style: AppTextStyles.chartAxis.copyWith(
                    color: widget.isLive ? AppColors.success : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
