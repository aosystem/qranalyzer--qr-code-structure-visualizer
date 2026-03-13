import 'package:flutter/material.dart';

import 'package:qranalyzer/l10n/app_localizations.dart';

class InstructionPanel extends StatelessWidget {

  const InstructionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(children:[
      _buildCard("Version:\n${l.infoVersion}"),
      _buildCard("Error Correction Level:\n${l.infoECL}"),
      _buildCard("Finder Pattern:\n${l.infoFinderPattern}"),
      _buildCard("Alignment Pattern:\n${l.infoAlignmentPattern}"),
      _buildCard("Timing Pattern:\n${l.infoTimingPattern}"),
      _buildCard("Format Info:\n${l.infoFormatInfo}"),
      _buildCard("Version Info:\n${l.infoVersionInfo}"),
      _buildCard("Data:\n${l.infoData}"),
      _buildCard("ECC: Error Correction Code\n${l.infoECC}"),
      _buildCard("Unused:\n${l.infoUnused}"),
      _buildCard("Dark Module:\n${l.infoDarkModule}"),
      const SizedBox(height: 100),
    ]);
  }

  Widget _buildCard(String text) {
    return Card(
      margin: const EdgeInsets.only(left: 12, right: 12, top: 12),
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
          ],
        )
      )
    );
  }
}
