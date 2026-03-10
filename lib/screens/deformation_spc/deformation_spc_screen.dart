import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';

class DeformationSpcScreen extends StatelessWidget {
  const DeformationSpcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Deformasyon SPC',
            subtitle: '4 ölçüm noktası detaylı analizi',
          ),
          SizedBox(height: 24),
          Center(child: Text('Deformasyon SPC — Geliştirme aşamasında')),
        ],
      ),
    );
  }
}
