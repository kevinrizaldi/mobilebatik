import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable Notification Button used across all screens in the app header / AppBar.
class NotificationButton extends StatelessWidget {
  final EdgeInsetsGeometry? padding;

  const NotificationButton({
    super.key,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Belum ada notifikasi baru untuk Anda.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
            },
            borderRadius: BorderRadius.circular(10),
            child: Tooltip(
              message: 'Notifikasi',
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF401100),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (padding != null) {
      return Padding(
        padding: padding!,
        child: button,
      );
    }

    return button;
  }
}
