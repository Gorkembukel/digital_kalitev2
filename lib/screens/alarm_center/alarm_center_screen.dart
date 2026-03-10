import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';

class AlarmCenterScreen extends StatelessWidget {
  const AlarmCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Alarm Merkezi',
            subtitle: 'Tolerans dışı ve Nelson kural ihlalleri',
          ),
          SizedBox(height: 24),
          Center(child: Text('Alarm Merkezi — Geliştirme aşamasında')),
        ],
      ),
    );
  }
}
