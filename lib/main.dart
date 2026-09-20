import 'package:flutter/material.dart';

void main() => runApp(const TheSystemApp());

class TheSystemApp extends StatelessWidget {
  const TheSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050A18),
        primaryColor: const Color(0xFF3FA9FF),
        fontFamily: 'monospace',
      ),
      home: const StatusScreen(),
    );
  }
}

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF3FA9FF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3FA9FF).withOpacity(0.4),
                  blurRadius: 16,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Center(
                  child: Text(
                    'S T A T U S',
                    style: TextStyle(
                      color: Color(0xFF3FA9FF),
                      fontSize: 22,
                      letterSpacing: 6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text('الاسم: لاعب جديد',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(height: 8),
                Text('Rank: E        Level: 1',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 16),
                Text('XP 0 / 100',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                SizedBox(height: 24),
                Text('The System is online.',
                    style: TextStyle(color: Color(0xFF3FA9FF), fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
