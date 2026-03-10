import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';

class PatternAnalysisScreen extends StatelessWidget {
  const PatternAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Pattern Analizi',
            subtitle: 'Vardiya karşılaştırması',
          ),
          SizedBox(height: 24),
          Center(child: Text('Pattern Analizi — Geliştirme aşamasında')),
        ],
      ),
    );
  }
}
