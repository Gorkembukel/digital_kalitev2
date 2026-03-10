import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';

class StratificationScreen extends StatelessWidget {
  const StratificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Tabakalama Analizi',
            subtitle: 'Stratification — Gruplara göre karşılaştırma',
          ),
          SizedBox(height: 24),
          Center(child: Text('Tabakalama — Geliştirme aşamasında')),
        ],
      ),
    );
  }
}
