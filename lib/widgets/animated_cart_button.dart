import 'package:flutter/material.dart';

class AnimatedCartButton extends StatefulWidget {
  const AnimatedCartButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<AnimatedCartButton> createState() => _AnimatedCartButtonState();
}

class _AnimatedCartButtonState extends State<AnimatedCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Ajouter au panier'),
          onPressed: () async {
            await _ctrl.forward();
            await _ctrl.reverse();
            widget.onPressed();
          },
        ),
      ),
    );
  }
}
