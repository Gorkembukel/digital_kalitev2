import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';

class EarlyWarningScreen extends StatelessWidget {
  const EarlyWarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Erken Uyarı',
            subtitle: 'Trend bazlı uyarı sistemi',
          ),
          SizedBox(height: 24),
          Center(child: Text('Erken Uyarı — Geliştirme aşamasında')),
        ],
      ),
    );
  }
}
