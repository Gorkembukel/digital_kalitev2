import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';

class CapabilityScreen extends StatelessWidget {
  const CapabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Kapasite Analizi',
            subtitle: 'Cp, Cpk, Pp, Ppk ve histogram',
          ),
          SizedBox(height: 24),
          Center(child: Text('Kapasite Analizi — Geliştirme aşamasında')),
        ],
      ),
    );
  }
}
