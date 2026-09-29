import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/font_weights.dart';
import '/core/theme/text_styles.dart';

/// A person's photo, or their initial when there isn't one.
///
/// The roster, the ledger, the share picker and the drawer all needed this and
/// all had their own copy at a slightly different size. One widget, one [size].
///
/// This is the only place the app renders a raster image, and it goes through
/// [OctoImage]: the monogram is drawn while the photo loads and again if the
/// load fails, so a dead Google photo URL degrades to the initial instead of a
/// broken-image glyph, and the photo fades in over the monogram rather than
/// popping.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;

  /// Greys the tint for someone who isn't participating today.
  final bool dimmed;

  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 42,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final photo = photoUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final tint = dimmed ? AppColors.textTertiary : AppColors.primary;

    final monogram = _Monogram(name: name, tint: tint, size: size);

    return Container(
      width: size,
      height: size,
      // A rounded square, not a circle. Faces in this app sit in the same
      // little bento boxes everything else does.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: AppRadius.rXs,
        color: AppColors.tint(tint, 0.2),
      ),
      // The stroke sits in the foreground so the photo can't paint over it.
      foregroundDecoration: BoxDecoration(
        borderRadius: AppRadius.rXs,
        border: Border.all(color: AppColors.ink, width: AppDecor.strokeWidth),
      ),
      child: hasPhoto
          ? OctoImage(
              image: NetworkImage(photo),
              width: size,
              height: size,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 220),
              fadeOutDuration: const Duration(milliseconds: 120),
              gaplessPlayback: true,
              placeholderBuilder: (_) => monogram,
              errorBuilder: (_, _, _) => monogram,
            )
          : monogram,
    );
  }
}

/// The initial in a tinted box. Stands in before, instead of, and behind a
/// photo, so it has to be a whole avatar on its own.
class _Monogram extends StatelessWidget {
  final String name;
  final Color tint;
  final double size;

  const _Monogram({required this.name, required this.tint, required this.size});

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: getMonoStyle(
          color: tint,
          fontSize: size * 0.38,
          weight: FontWeightManager.extraBold,
        ),
      ),
    );
  }
}
