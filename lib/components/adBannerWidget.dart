// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// class AdBannerWidget extends StatefulWidget {
//   final String adUnitId;
//   final double height;

//   const AdBannerWidget({
//     super.key,
//     required this.adUnitId,
//     this.height = 100,
//   });

//   @override
//   State<AdBannerWidget> createState() => _AdBannerWidgetState();
// }

// class _AdBannerWidgetState extends State<AdBannerWidget> {
//   BannerAd? _bannerAd;
//   bool _isLoaded = false;

//   @override
//   void initState() {
//     super.initState();
//     _bannerAd = BannerAd(
//       adUnitId: widget.adUnitId,
//       size: AdSize.banner,
//       request: const AdRequest(),
//       listener: BannerAdListener(
//         onAdLoaded: (_) => setState(() => _isLoaded = true),
//         onAdFailedToLoad: (ad, error) {
//           ad.dispose();
//           debugPrint("Erreur de chargement pub : $error");
//         },
//       ),
//     )..load();
//   }

//   @override
//   void dispose() {
//     _bannerAd?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
//       child: Container(
//         height: widget.height,
//         decoration: BoxDecoration(
//           color: Colors.blueGrey[100],
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.blueGrey, width: 1),
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 4,
//               offset: Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Center(
//           child: _isLoaded && _bannerAd != null
//               ? AdWidget(ad: _bannerAd!)
//               : Image.asset('assets/images/empty.png'), // placeholder
//         ),
//       ),
//     );
//   }
// }
