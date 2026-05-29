import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('About MedGraph',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About MedGraph',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 32),
              _BodyText(
                'MedGraph is India\'s first verified medical networking platform — '
                'built by a doctor, for doctors and medical students.',
              ),
              const SizedBox(height: 20),
              _BodyText(
                'We\'re on a mission to connect India\'s 2.3 million medical students '
                'with verified peers — not just in textbooks.',
              ),
              const SizedBox(height: 20),
              _BodyText(
                'Through live roulette study sessions, scheduled peer learning, '
                'and a creator economy for educators, MedGraph is redefining how '
                'medical professionals in India learn, connect, and grow.',
              ),
              const SizedBox(height: 48),
              const Center(
                child: Text(
                  'Built in India 🇮🇳',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00C7BE),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withValues(alpha: 0.7),
        height: 1.7,
      ),
    );
  }
}
