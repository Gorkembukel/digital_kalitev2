import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';

class HumiditySpcScreen extends StatelessWidget {
  const HumiditySpcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Nem SPC (Kapsamlı)',
            subtitle: 'Genişletilmiş nem analizi',
          ),
          SizedBox(height: 24),
          Center(child: Text('Nem SPC — Geliştirme aşamasında')),
        ],
      ),
    );
  }
}
