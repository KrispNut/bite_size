import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '/core/alerts/toast.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/custom_button.dart';
import '/core/widgets/custom_textfield.dart';
import '/core/widgets/sheet_handle.dart';
import '/core/widgets/user_avatar.dart';
import '/features/dashboard/dashboard_viewmodel.dart';

/// Your photo and display name, edited in one place.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

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
      builder: (_) => const EditProfileSheet(),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<DashboardViewModel>().currentUserName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// The photo saves straight away, so the sheet stays open showing it.
  Future<void> _changePhoto(ImageSource source) async {
    final viewModel = context.read<DashboardViewModel>();
    final photo = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (photo == null) return;

    await ShowToastDialog.whileLoading(
      'Uploading photo...',
      () => viewModel.setProfilePhoto(photo),
      success: 'Profile photo updated! 📸',
    );
  }

  Future<void> _saveName() async {
    if (!_formKey.currentState!.validate()) return;
    final viewModel = context.read<DashboardViewModel>();
    final name = _nameController.text.trim();
    final photoUrl = viewModel.currentUserPhotoUrl;

    Navigator.of(context).pop();
    await ShowToastDialog.whileLoading(
      'Saving name...',
      () => viewModel.updateProfile(
        name: name,
        photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
      ),
      success: 'Name updated! ✨',
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpace.lg,
        right: AppSpace.lg,
        top: AppSpace.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpace.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              Text('Your profile', style: AppText.h3),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  UserAvatar(
                    name: viewModel.currentUserName,
                    photoUrl: viewModel.currentUserPhotoUrl,
                    size: 72,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      children: [
                        _photoButton(
                          icon: Icons.camera_alt_rounded,
                          text: 'Take photo',
                          source: ImageSource.camera,
                        ),
                        const SizedBox(height: AppSpace.xs),
                        _photoButton(
                          icon: Icons.photo_library_rounded,
                          text: 'Choose photo',
                          source: ImageSource.gallery,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              CustomTextField(
                context: context,
                controller: _nameController,
                label: 'Display name',
                hintText: 'Your full name',
                helperText: "This is how you appear on today's roster.",
                type: TextInputType.name,
                textInputAction: TextInputAction.done,
                validatorFn: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter your name'
                    : null,
              ),
              const SizedBox(height: AppSpace.lg),
              CustomButton(
                onPress: _saveName,
                text: 'Save name',
                btnColor: AppColors.primary,
                textColor: AppColors.onPrimary,
                isIcon: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoButton({
    required IconData icon,
    required String text,
    required ImageSource source,
  }) {
    return CustomButton(
      onPress: () {
        _changePhoto(source);
      },
      text: text,
      btnColor: AppColors.transparent,
      textColor: AppColors.primary,
      isIcon: true,
      iconData: icon,
      elevated: false,
      height: 48,
    );
  }
}
