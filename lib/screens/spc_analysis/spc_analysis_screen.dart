import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';

class SpcAnalysisScreen extends StatelessWidget {
  const SpcAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'SPC Analizi',
            subtitle: 'I-MR, X-bar/R ve Nelson 8 Kural kontrolleri',
          ),
          SizedBox(height: 24),
          Center(child: Text('SPC Analizi — Aşama 3\'te grafik eklenecek')),
        ],
      ),
    );
  }
}
