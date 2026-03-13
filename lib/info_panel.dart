import 'package:flutter/material.dart';

import 'package:qranalyzer/qr_info.dart';
import 'package:qranalyzer/l10n/app_localizations.dart';

class InfoPanel extends StatelessWidget {
  final QrInfo? info;

  const InfoPanel({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    if (info == null) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    return Column(children:[
      Card(
        elevation: 0,
        margin: const EdgeInsets.only(left: 12, right: 12, top: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Decoded Result: ${info!.decodedText ?? ''}"),
              Text("Version: ${info!.version}"),
              Text("Error Correction Level: ${info!.ecLevel}"),
              Text("Mask Pattern: ${info!.maskPattern}"),
              Text("Size: ${info!.size} × ${info!.size}"),
              Text("Data Codewords: ${info!.dataCodewords}"),
              Text("ECC Codewords: ${info!.eccCodewords}"),
            ],
          )
        )
      ),
      Card(
        margin: const EdgeInsets.only(left: 12, right: 12, top: 12),
        elevation: 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.infoImageFirst),
              const SizedBox(height: 12),
              Text(l.infoImageSecond),
              const SizedBox(height: 12),
              Text(l.infoImageThird),
              const SizedBox(height: 12),
              Text(l.infoImageFourth),
            ],
          )
        )
      ),
    ]);
  }

}
