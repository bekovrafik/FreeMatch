import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/card_item.dart';
import '../services/admob_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NativeAdCard extends ConsumerStatefulWidget {
  final CardItem cardItem;

  const NativeAdCard({super.key, required this.cardItem});

  @override
  ConsumerState<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends ConsumerState<NativeAdCard> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd =
        ref
            .read(admobServiceProvider)
            .createNativeAd(
              onAdLoaded: (ad) {
                if (mounted) {
                  setState(() {
                    _nativeAd = ad as NativeAd;
                    _isAdLoaded = true;
                  });
                }
              },
              onAdFailedToLoad: (ad, error) {
                debugPrint('Native Ad failed to load: $error');
                ad.dispose();
              },
            )
          ..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ad isn't loaded yet, show a placeholder that looks like a loading card
    if (!_isAdLoaded || _nativeAd == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Slate-800
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ad Widget (Platform View)
          // Note: NativeAd is typically a platform view.
          // However, for complete custom styling in Flutter matching our card stack,
          // we often use defined templates or need the NativeAd widget to support our layout.
          // Since we want EXACT styling match, we'll wrap the AdWidget.
          // IMPORTANT: Google Mobile Ads Flutter plugin Native Ads are usually platform views (XML/XIB).
          // But to get it to look like OUR Flutter widgets exactly, we rely on the AdWidget to render the defined native template
          // OR we can try to render components if the factory supports it.
          // For this implementation, we assume the factory 'listTile' or similar is configured on native side OR
          // we use the default NativeAd widget behavior which renders the platform view initialized by the factoryID.
          AdWidget(ad: _nativeAd!),

          // Overlay Gradient (To ensure text readability if the native view doesn't have it)
          // Note: Since the NativeAd renders a PlatformView, Flutter widgets on top OF it might have transparency issues on some Android versions
          // but usually works. If the Native View (XML) already has styling, this might be redundant.
          // Assuming the Native Factory ('listTile') renders a basic layout.

          // "Sponsored" Badge (Top Right)
          Positioned(
            top: 30,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: Colors.black),
                  SizedBox(width: 4),
                  Text(
                    "SPONSORED",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
