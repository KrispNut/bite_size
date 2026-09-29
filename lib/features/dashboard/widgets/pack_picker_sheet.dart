import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/custom_button.dart';
import '/core/widgets/sheet_handle.dart';
import '/core/widgets/sheet_header_card.dart';
import '/core/widgets/tactile_container.dart';
import '/generated/assets.dart';

/// Picks what this install *is*.
///
/// Not a colour picker, though it looks like one: choosing a pack swaps the
/// palette, the geometry, every noun on screen, the marks, the currency and
/// which halves of the app exist at all.
///
/// Choosing one restarts the app in place — see `_BiteSizeAppState`. That
/// tears down this sheet along with everything else, which is why there is no
/// "apply" step and no confirmation: you tap a row and the app comes back
/// wearing it. Each row is drawn in its own pack's colours and geometry, so
/// the preview happens before the tap rather than after.
class PackPickerSheet extends StatefulWidget {
  const PackPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sheet,
        side: BorderSide(color: AppColors.ink, width: AppDecor.strokeWidth),
      ),
      builder: (ctx) => const PackPickerSheet(),
    );
  }

  @override
  State<PackPickerSheet> createState() => _PackPickerSheetState();
}

class _PackPickerSheetState extends State<PackPickerSheet> {
  @override
  Widget build(BuildContext context) {
    // Listens directly rather than relying on the rebuild in main.dart, so the
    // tapped row marks itself selected on the frame before the restart tears
    // the sheet down.
    return ListenableBuilder(
      listenable: PackService.instance,
      builder: (context, _) {
        final service = PackService.instance;
        final current = service.pack;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.sheet,
          ),
          padding: EdgeInsets.only(
            left: AppSpace.lg,
            right: AppSpace.lg,
            top: AppSpace.md,
            bottom: MediaQuery.of(context).padding.bottom + AppSpace.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                const SheetHeaderCard(
                  title: 'Theme',
                  subtitle:
                      'Changes the colours, the shapes, what everything is '
                      'called and which parts of the app you get. Picking one '
                      'reloads the app.',
                ),
                const SizedBox(height: AppSpace.sm),

                for (final pack in service.selectable) ...[
                  _PackOption(
                    pack: pack,
                    selected: pack.id == current.id,
                    onTap: () => service.select(pack),
                  ),
                  const SizedBox(height: AppSpace.xs),
                ],

                const SizedBox(height: AppSpace.sm),
                CustomButton(
                  onPress: () => Navigator.of(context).pop(),
                  text: 'Done',
                  btnColor: AppColors.primaryDeep,
                  textColor: AppColors.textOnBrand,
                  isIcon: true,
                  iconData: Icons.check_rounded,
                  iconColor: AppColors.textOnBrand,
                  height: 56,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PackOption extends StatelessWidget {
  final ActivityPack pack;
  final bool selected;
  final VoidCallback onTap;

  const _PackOption({
    required this.pack,
    required this.selected,
    required this.onTap,
  });

  /// What this pack actually gives you, in its own words.
  ///
  /// Generated from the module switches rather than written out per pack, so a
  /// new pack describes itself correctly the moment it exists.
  String get _summary {
    final labels = pack.labels;
    final modules = pack.modules;
    final parts = <String>[
      if (modules.roster) labels.contribution,
      if (modules.units) labels.unitPlural,
      if (modules.errand) labels.errand,
      if (modules.advisor) labels.advisorName,
    ];
    if (parts.isEmpty) {
      return 'Costs, invitations and the ledger. Nothing else.';
    }
    return '${parts.join(' · ')} · ${labels.expensePlural}';
  }

  @override
  Widget build(BuildContext context) {
    // Drawn in the pack's OWN colours and its OWN geometry, not the running
    // theme's. The row is the preview: a boxy pack gets a boxy row with a
    // heavy stroke and a hard shadow, so you can see what you'd be getting
    // before you commit to it.
    final palette = pack.palette;
    final shape = pack.shape;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? palette.primaryDark : palette.primary;

    return TactileContainer(
      onTap: onTap,
      builder: (context, pressed) => Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.tint(accent, 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(shape.scale(12)),
          border: Border.all(
            color: selected ? accent : AppColors.border,
            width: shape.strokeWidth,
          ),
          boxShadow: pressed
              ? null
              : switch (shape.depth) {
                  ShapeDepth.flat => null,
                  ShapeDepth.hard => [
                    BoxShadow(color: AppColors.ink, offset: const Offset(2, 4)),
                  ],
                  ShapeDepth.soft => AppShadow.card,
                },
        ),
        padding: const EdgeInsets.all(AppSpace.sm),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.tint(accent, 0.20),
                borderRadius: BorderRadius.circular(shape.scale(4)),
                border: Border.all(
                  color: AppColors.ink,
                  width: shape.strokeWidth,
                ),
              ),
              child: AppIcon(Assets.svg.roti.path, size: 26),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pack.labels.activityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getExtraBoldStyle(
                      fontSize: 16,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: getMediumStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _Swatch(colors: palette.swatch, shape: shape),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            _SelectionMark(selected: selected, accent: accent, shape: shape),
          ],
        ),
      ),
    );
  }
}

/// The four-band strip that tells two packs apart at a glance.
class _Swatch extends StatelessWidget {
  final List<Color> colors;
  final PackShape shape;

  const _Swatch({required this.colors, required this.shape});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(shape.scale(4)),
        border: Border.all(color: AppColors.ink, width: 1),
      ),
      child: Row(
        children: [
          for (final c in colors) Expanded(child: ColoredBox(color: c)),
        ],
      ),
    );
  }
}

/// Square, not a radio button — circles read as a different design language.
class _SelectionMark extends StatelessWidget {
  final bool selected;
  final Color accent;
  final PackShape shape;

  const _SelectionMark({
    required this.selected,
    required this.accent,
    required this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? accent : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(shape.scale(4)),
        border: Border.all(color: AppColors.ink, width: shape.strokeWidth),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 17, color: AppColors.white)
          : null,
    );
  }
}
