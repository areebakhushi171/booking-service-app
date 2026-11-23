import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/utils/validators.dart';
import 'package:bookease/core/widgets/app_text_field.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/provider/data/service_image_presets.dart';
import 'package:bookease/features/provider/providers/provider_services_provider.dart';

/// Create or edit a service. Pops with `true` when saved.
class ServiceFormScreen extends StatefulWidget {
  final ServiceModel? existing;

  const ServiceFormScreen({super.key, this.existing});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  static const List<int> _durations = [15, 30, 45, 60, 90, 120, 180, 240];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _description;
  late final TextEditingController _features;
  late final TextEditingController _imageUrl;

  late String _category;
  late int _duration;
  late bool _isActive;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    final businessCategory = context.read<AuthProvider>().user.businessCategory;
    final knownIds = AppCategories.all.map((c) => c['id'] as String).toList();

    _name = TextEditingController(text: s?.name ?? '');
    _price = TextEditingController(
        text: s == null ? '' : s.price.toStringAsFixed(0));
    _city = TextEditingController(text: s?.city ?? 'Karachi');
    _country = TextEditingController(text: s?.country ?? 'Pakistan');
    _description = TextEditingController(text: s?.description ?? '');
    _features = TextEditingController(text: s?.features.join('\n') ?? '');
    final presetUrl =
        s == null ? '' : ServiceImagePresets.forCategory(s.category);
    _imageUrl = TextEditingController(
        text: (s == null || s.imageUrl == presetUrl) ? '' : s.imageUrl);

    _category = s?.category ??
        (knownIds.contains(businessCategory)
            ? businessCategory!
            : knownIds.first);
    _duration = s?.durationMinutes ?? 60;
    _isActive = s?.isActive ?? true;
    _imageUrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _city.dispose();
    _country.dispose();
    _description.dispose();
    _features.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  String get _previewUrl {
    final custom = _imageUrl.text.trim();
    return custom.isEmpty ? ServiceImagePresets.forCategory(_category) : custom;
  }

  String? _validateImage(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return 'Enter a valid http(s) image link or leave empty';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();
    final provider = context.read<ProviderServicesProvider>();
    final user = auth.user;

    final features = _features.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final existing = widget.existing;
    final service = existing == null
        ? ServiceModel(
            id: '',
            name: _name.text.trim(),
            category: _category,
            description: _description.text.trim(),
            price: double.parse(_price.text.trim()),
            durationMinutes: _duration,
            city: _city.text.trim().isNotEmpty ? _city.text.trim() : 'Karachi',
            country: _country.text.trim().isNotEmpty ? _country.text.trim() : 'Pakistan',
            imageUrl: _previewUrl,
            galleryImages: [_previewUrl],
            features: features,
            providerId: user.id,
            providerName: user.businessName ?? user.name,
            isActive: _isActive,
          )
        : existing.copyWith(
            name: _name.text.trim(),
            category: _category,
            description: _description.text.trim(),
            price: double.parse(_price.text.trim()),
            durationMinutes: _duration,
            city: _city.text.trim().isNotEmpty ? _city.text.trim() : 'Karachi',
            country: _country.text.trim().isNotEmpty ? _country.text.trim() : 'Pakistan',
            imageUrl: _previewUrl,
            features: features,
            isActive: _isActive,
          );

    try {
      await provider.save(service);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the service. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withAlpha(150);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit service' : 'Add new service'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: AppSizes.maxFormWidth + 80),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: AppSizes.screenPadding,
                children: [
                  // Cover preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _previewUrl.isEmpty
                          ? Container(
                              color: theme.colorScheme.onSurface.withAlpha(15),
                              child: Icon(Icons.broken_image_outlined,
                                  color: muted, size: 36.sp),
                            )
                          : CachedNetworkImage(
                              imageUrl: _previewUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                  color: theme.colorScheme.onSurface.withAlpha(15)),
                              errorWidget: (_, __, ___) => Container(
                                color: theme.colorScheme.onSurface.withAlpha(15),
                                child: Icon(Icons.broken_image_outlined,
                                    color: muted, size: 36.sp),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: AppSizes.s20),

                  AppTextField(
                    label: 'Service name',
                    hint: 'e.g. Bridal Makeup & Styling',
                    icon: Icons.title_rounded,
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        Validators.validateRequired(v, field: 'Service name'),
                  ),
                  SizedBox(height: AppSizes.s16),

                  Text('Category',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  SizedBox(height: AppSizes.s8),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: AppCategories.all.map((c) {
                      final id = c['id'] as String;
                      return ChoiceChip(
                        avatar: Icon(c['icon'] as IconData, size: 16.sp),
                        label: Text(c['name'] as String),
                        selected: _category == id,
                        onSelected: (_) => setState(() => _category = id),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: AppSizes.s16),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'City',
                          hint: 'e.g. Karachi',
                          icon: Icons.location_city_rounded,
                          controller: _city,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: AppTextField(
                          label: 'Country',
                          hint: 'e.g. Pakistan',
                          icon: Icons.public_rounded,
                          controller: _country,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.s16),

                  AppTextField(
                    label: 'Price (Rs)',
                    hint: 'e.g. 2500',
                    icon: Icons.payments_rounded,
                    controller: _price,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'Enter a price above 0';
                      return null;
                    },
                  ),
                  SizedBox(height: AppSizes.s16),

                  Text('Duration',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  SizedBox(height: AppSizes.s8),
                  DropdownButtonFormField<int>(
                    value: _durations.contains(_duration) ? _duration : 60,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.timer_outlined)),
                    items: _durations
                        .map((d) => DropdownMenuItem(
                            value: d, child: Text('$d minutes')))
                        .toList(),
                    onChanged: (v) => setState(() => _duration = v ?? 60),
                  ),
                  SizedBox(height: AppSizes.s16),

                  AppTextField(
                    label: 'Description',
                    hint: 'What is included, who it is for, what to expect',
                    controller: _description,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    validator: (v) {
                      if ((v ?? '').trim().length < 20) {
                        return 'Please write at least 20 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSizes.s16),

                  AppTextField(
                    label: 'What is included (one per line, optional)',
                    hint: 'Free consultation\nAll products included',
                    controller: _features,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                  ),
                  SizedBox(height: AppSizes.s16),

                  AppTextField(
                    label: 'Photo link (optional)',
                    hint: 'https://... leave empty to use a category photo',
                    icon: Icons.image_outlined,
                    controller: _imageUrl,
                    keyboardType: TextInputType.url,
                    validator: _validateImage,
                  ),
                  SizedBox(height: AppSizes.s8),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Visible to customers'),
                    subtitle:
                        const Text('Turn off to hide it without deleting'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  SizedBox(height: AppSizes.s20),

                  CustomButton(
                    label: _isEdit ? 'Save changes' : 'Publish service',
                    icon: Icons.check_rounded,
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
