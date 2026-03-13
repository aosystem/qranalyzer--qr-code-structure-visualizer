import 'package:flutter/material.dart';

import 'package:qranalyzer/legend_item.dart';

class LegendPanel extends StatelessWidget {
  const LegendPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(left: 12, right: 12, top: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 4),
        child: GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 1,
          crossAxisSpacing: 0,
          childAspectRatio: 6,
          children: const [
            LegendItem(color: Colors.green, label: "Finder Pattern"),
            LegendItem(color: Colors.cyan, label: "Alignment Pattern"),
            LegendItem(color: Colors.yellow, label: "Timing Pattern"),
            LegendItem(color: Colors.purple, label: "Format Info"),
            LegendItem(color: Colors.orange, label: "Version Info"),
            LegendItem(color: Colors.blue, label: "Data"),
            LegendItem(color: Colors.red, label: "ECC"),
            LegendItem(color: Colors.white, label: "Unused"),
            LegendItem(color: Colors.black, label: "Dark Module"),
          ],
        ),
      ),
    );
  }
}
