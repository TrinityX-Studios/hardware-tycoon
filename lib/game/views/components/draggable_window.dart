import 'package:flutter/material.dart';
import '../../core/theme.dart';

class DraggableWindow extends StatefulWidget {
  final String title;
  final Widget child;
  final IconData icon;
  final Offset initialPosition;
  final Size initialSize;
  final VoidCallback onClose;
  final VoidCallback onFocus;
  final bool isFocused;

  const DraggableWindow({
    super.key,
    required this.title,
    required this.child,
    required this.icon,
    required this.initialPosition,
    required this.initialSize,
    required this.onClose,
    required this.onFocus,
    required this.isFocused,
  });

  @override
  State<DraggableWindow> createState() => _DraggableWindowState();
}

class _DraggableWindowState extends State<DraggableWindow> {
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      width: widget.initialSize.width,
      height: widget.initialSize.height,
      child: GestureDetector(
        onTapDown: (_) => widget.onFocus(),
        child: Container(
          decoration: BoxDecoration(
            color: HTColors.background,
            border: Border.all(
              color: widget.isFocused ? HTColors.primary : HTColors.border,
              width: widget.isFocused ? 2.0 : 1.0,
            ),
            boxShadow: widget.isFocused
                ? [BoxShadow(color: HTColors.primary.withValues(alpha: 0.2), blurRadius: 10.0, spreadRadius: 2.0)]
                : [const BoxShadow(color: Colors.black54, blurRadius: 15.0, offset: Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Bar
              GestureDetector(
                onPanUpdate: (details) {
                  widget.onFocus();
                  setState(() {
                    _position += details.delta;
                  });
                },
                child: Container(
                  height: 32.0,
                  color: widget.isFocused ? HTColors.primary.withValues(alpha: 0.15) : HTColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(widget.icon, size: 14.0, color: widget.isFocused ? HTColors.primary : HTColors.textSecondary),
                      const SizedBox(width: 8.0),
                      Text(
                        widget.title,
                        style: HTTypography.panelHeader.copyWith(
                          color: widget.isFocused ? HTColors.primary : HTColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      // Drag indicator lines
                      for (int i = 0; i < 5; i++) ...[
                        Container(
                          width: 2.0,
                          height: 12.0,
                          color: HTColors.border,
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        ),
                      ],
                      const SizedBox(width: 16.0),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            width: 20.0,
                            height: 20.0,
                            decoration: BoxDecoration(
                              color: HTColors.error.withValues(alpha: 0.1),
                              border: Border.all(color: HTColors.error),
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                            child: const Icon(Icons.close, size: 14.0, color: HTColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Body
              Expanded(
                child: ClipRect(child: widget.child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
