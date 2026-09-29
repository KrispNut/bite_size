import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AppConstants {
  static ThemeMode? currentTheme;
  static String deviceId = '';
  static String deviceToken = '';
  static GlobalKey bottomBarKey = GlobalKey();

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Who is an admin, and who receives pings, are both database questions and
  // neither is read from .env any more. Admin is `public.users.role`, enforced
  // by RLS and read through `IdentityService.instance.isAdmin`; there may be
  // any number of admins. The ping target is the one row flagged
  // `is_ping_target` (migration 009). Both change with an UPDATE in Supabase
  // and no rebuild — which is the whole point, since .env ships inside the APK.

  static Future<void> getDeviceInfo() async {
    var deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;

      AppConstants.deviceId = androidDeviceInfo.id;
    } else if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      AppConstants.deviceId = iosDeviceInfo.identifierForVendor ?? "";
    }
  }

  void openWhatsAppChat(String phoneNumber) async {
    final Uri whatsappUrl = Uri.parse("https://wa.me/$phoneNumber");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  static String formatToTwoDecimalPlaces(dynamic value) {
    if (value == null) return "0.00";

    try {
      double parsedValue = double.parse(value.toString());
      return parsedValue.toStringAsFixed(2);
    } catch (e) {
      return "0.00";
    }
  }

  static String uppercaseToLowercase(String value) {
    if (value.isEmpty) return "";
    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ""
              : "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}",
        )
        .join(' ');
  }

  static Future<T?> navigate<T>(
    BuildContext context,
    Widget page, {
    String type = 'rightToLeft',
    bool keep = false,
    bool replacement = false,
    RoutePredicate? removeUntil,
  }) {
    Offset startOffset;

    switch (type) {
      case 'leftToRight':
        startOffset = const Offset(-2.0, 0.0);
        break;
      case 'bottomToTop':
        startOffset = const Offset(0.0, 2.0);
        break;
      case 'topToBottom':
        startOffset = const Offset(0.0, -2.0);
        break;
      case 'rightToLeft':
      default:
        startOffset = const Offset(2.0, 0.0);
        break;
    }

    final route = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, anim, secondaryAnimation, child) {
        final tween = Tween(
          begin: startOffset,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));

        return SlideTransition(position: anim.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );

    if (replacement) {
      return Navigator.pushReplacement<T, T>(context, route);
    }
    if (keep) {
      return Navigator.push<T>(context, route);
    }
    return Navigator.pushAndRemoveUntil<T>(
      context,
      route,
      removeUntil ?? (_) => false,
    );
  }
}
