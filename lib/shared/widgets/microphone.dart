import 'package:flutter/material.dart';

/// A simple widget that displays a microphone icon
/// and a circle that changes size based on the sound level.
class MicrophoneWidget extends StatelessWidget {
  const MicrophoneWidget({
    super.key,
    required this.level,
    required this.onPressed,
  });

  final double level;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              blurRadius: .26,
              spreadRadius: level * 1.5,
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(.05))
        ],
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(50)),
      ),
      child: IconButton(
        icon: const Icon(Icons.mic),
        onPressed: onPressed,
      ),
    );
  }
}