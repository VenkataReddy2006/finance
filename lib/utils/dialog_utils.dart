import 'package:flutter/material.dart';
import 'responsive.dart';

class DialogUtils {
  static void showConstrainedDialog({
    required BuildContext context,
    required Widget child,
    double maxWidth = 500,
    bool barrierDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        if (Responsive.isMobile(context)) return child;
        
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
