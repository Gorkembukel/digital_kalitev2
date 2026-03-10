import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';

class DataHealthScreen extends StatelessWidget {
  const DataHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Veri Sağlık Analizi',
            subtitle: 'Veri kalite skoru ve bütünlük kontrolü',
          ),
          // TODO: Aşama 4'te implemente edilecek
          SizedBox(height: 24),
          Center(child: Text('Veri Sağlık Analizi — Geliştirme aşamasında')),
        ],
      ),
    );
  }
}
