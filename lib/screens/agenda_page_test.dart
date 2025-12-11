import 'package:flutter/material.dart';

class TestAgendaPage extends StatelessWidget {
  const TestAgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Agenda'),
      ),
      body: const Center(
        child: Text('Agenda de prueba'),
      ),
    );
  }
}
