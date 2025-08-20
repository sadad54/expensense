import 'package:flutter/material.dart';

class TappableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? margin;

  const TappableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.elevation,
    this.shape,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final ShapeBorder effectiveShape =
        shape ??
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    BorderRadius? radius;
    if (effectiveShape is RoundedRectangleBorder) {
      radius = effectiveShape.borderRadius as BorderRadius?;
    }
    return Card(
      color: color,
      elevation: elevation ?? 4,
      shape: effectiveShape,
      margin: margin,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: child,
      ),
    );
  }
}
