import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_confirmation_screen.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';

class BookingStepperScreen extends StatefulWidget {
  final ServiceModel service;

  const BookingStepperScreen({super.key, required this.service});

  @override
  State<BookingStepperScreen> createState() => _BookingStepperScreenState();
}

class _BookingStepperScreenState extends State<BookingStepperScreen> {
  static const _stepTitles = ['Date', 'Time', 'Details', 'Confirm'];

  int _currentStep = 0;
  late DateTime _selectedDate;
  String? _selectedSlot;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isSubmitting = false;

  late final List<DateTime> _availableDates;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _availableDates = List.generate(
      30,
          (i) => DateTime(now.year, now.month, now.day + i),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String get _formattedDateString => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _submitBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    final bookingProvider = context.read<BookingProvider>();

    setState(() => _isSubmitting = true);

    try {
      final combinedNotes = [
        if (_addressController.text.trim().isNotEmpty)
          'Address: ${_addressController.text.trim()}',
        if (_notesController.text.trim().isNotEmpty)
          'Notes: ${_notesController.text.trim()}',
      ].join('\n');

      final newBooking = await bookingProvider.createBooking(
        service: widget.service,
        dateStr: _formattedDateString,
        startTime: _selectedSlot!,
        customerNotes: combinedNotes.isNotEmpty ? combinedNotes : null,
        customerName: user.name,
        customerEmail: user.email,
        customerPhone: user.phone,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(booking: newBooking),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingProvider = context.watch<BookingProvider>();
    final slotStatuses = bookingProvider.getSlotStatuses(
      dateStr: _formattedDateString,
      service: widget.service,
    );

    final stepContent = switch (_currentStep) {
      0 => _dateStep(theme),
      1 => _timeStep(theme, slotStatuses),
      2 => _detailsStep(theme),
      _ => _reviewStep(theme),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment'), elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              _StepHeader(
                titles: _stepTitles,
                current: _currentStep,
                onTapStep: (s) {
                  if (s < _currentStep) setState(() => _currentStep = s);
                },
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey(_currentStep),
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                    child: stepContent,
                  ),
                ),
              ),
              _bottomBar(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(ThemeData theme) {
    final labels = [
      'Proceed to Time Slot',
      'Next',
      'Review Booking',
      'Confirm Booking',
    ];
    final VoidCallback? onNext = switch (_currentStep) {
      0 => () => setState(() => _currentStep = 1),
      1 => _selectedSlot != null ? () => setState(() => _currentStep = 2) : null,
      2 => () => setState(() => _currentStep = 3),
      _ => _submitBooking,
    };

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.onSurface.withAlpha(20)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: CustomButton(
                  label: 'Back',
                  isOutlined: true,
                  onPressed: () => setState(() => _currentStep -= 1),
                ),
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              flex: _currentStep > 0 ? 1 : 2,
              child: CustomButton(
                label: labels[_currentStep],
                isLoading: _currentStep == 3 && _isSubmitting,
                onPressed: onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(ThemeData theme, String title, {String? trailing}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h, top: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (trailing != null)
            StatusPill(
              label: trailing,
              color: theme.colorScheme.secondary,
              showDot: false,
            ),
        ],
      ),
    );
  }

  // ---------- Step 1 ----------
  Widget _dateStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(theme, 'Select a Date (Next 30 Days)'),
        SizedBox(
          height: 96.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableDates.length,
            itemBuilder: (context, idx) {
              final date = _availableDates[idx];
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final onSel = theme.colorScheme.onPrimary;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = date;
                  _selectedSlot = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 68.w,
                  margin: EdgeInsets.only(right: 10.w),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    )
                        : null,
                    color: isSelected ? null : theme.cardColor,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : theme.colorScheme.onSurface.withAlpha(30),
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? onSel.withAlpha(210)
                              : theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        DateFormat('dd').format(date),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? onSel : theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        DateFormat('MMM').format(date),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isSelected
                              ? onSel.withAlpha(210)
                              : theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 22.h),
        SectionCard(
          title: 'Selected Date',
          icon: Icons.event_rounded,
          child: Text(
            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Step 2 ----------
  Widget _timeStep(ThemeData theme, List slotStatuses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(theme, 'Choose Available Slot',
            trailing: widget.service.formattedDuration),
        Wrap(
          spacing: 14.w,
          runSpacing: 6.h,
          children: [
            _legend(theme, 'Available', theme.colorScheme.primary, outlined: true),
            _legend(theme, 'Selected', theme.colorScheme.primary),
            _legend(theme, 'Booked', theme.colorScheme.onSurface.withAlpha(60)),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          'Greyed-out slots are already booked, past current time, or conflict with duration overlap.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(140),
          ),
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: slotStatuses.map<Widget>((status) {
            final isSelected = _selectedSlot == status.time;
            final isAvailable = status.isAvailable as bool;

            return Tooltip(
              message: status.reason ?? 'Available for booking',
              child: InkWell(
                onTap: isAvailable
                    ? () => setState(() => _selectedSlot = status.time)
                    : null,
                borderRadius: BorderRadius.circular(14.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isAvailable
                        ? theme.cardColor
                        : theme.colorScheme.onSurface.withAlpha(14)),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isAvailable
                          ? theme.colorScheme.primary.withAlpha(90)
                          : Colors.transparent),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAvailable ? Icons.schedule_rounded : Icons.block_rounded,
                        size: 14.sp,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : (isAvailable
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withAlpha(90)),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        status.time,
                        style: TextStyle(
                          fontWeight: isSelected || isAvailable
                              ? FontWeight.w600
                              : FontWeight.normal,
                          decoration: isAvailable
                              ? TextDecoration.none
                              : TextDecoration.lineThrough,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : (isAvailable
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withAlpha(90)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _legend(ThemeData theme, String label, Color color,
      {bool outlined = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(4.r),
            border: outlined ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        SizedBox(width: 6.w),
        Text(label, style: TextStyle(fontSize: 11.sp)),
      ],
    );
  }

  // ---------- Step 3 ----------
  Widget _detailsStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(theme, 'Address & Specific Instructions'),
        SectionCard(
          title: 'Where should we come?',
          icon: Icons.location_on_rounded,
          child: TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Service Delivery Address',
              hintText: 'e.g. House #14, Sector Y, DHA Phase 5, Lahore',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SectionCard(
          title: 'Anything we should know?',
          icon: Icons.note_alt_rounded,
          tint: theme.colorScheme.secondary,
          child: TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Special Notes / Preferences (Optional)',
              hintText:
              'e.g. Please ring doorbell twice, specific model is 1.5 ton Inverter AC, etc.',
              prefixIcon: Icon(Icons.note_alt_outlined),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Step 4 ----------
  Widget _reviewStep(ThemeData theme) {
    final muted = theme.colorScheme.onSurface.withAlpha(150);

    Widget row(String l, String v, {bool bold = false, Color? color}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: TextStyle(color: muted)),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(theme, 'Appointment Summary'),
        Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: theme.colorScheme.onSurface.withAlpha(25)),
          ),
          child: Column(
            children: [
              row('Service', widget.service.name, bold: true),
              SizedBox(height: 12.h),
              row('Date', DateFormat('EEE, MMM d, yyyy').format(_selectedDate)),
              SizedBox(height: 12.h),
              row(
                'Time Window',
                '$_selectedSlot - ${BookingProvider.calculateEndTime(_selectedSlot ?? '09:00', widget.service.durationMinutes)}',
                bold: true,
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: 12.h),
              row('Duration', widget.service.formattedDuration),
              SizedBox(height: 14.h),
              LayoutBuilder(builder: (_, c) {
                final n = (c.maxWidth / 9).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    n,
                        (_) => Container(
                      width: 5,
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withAlpha(50),
                    ),
                  ),
                );
              }),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total Due (Pay at service)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                  ),
                  Text(
                    widget.service.formattedPrice,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  final List<String> titles;
  final int current;
  final ValueChanged<int> onTapStep;

  const _StepHeader({
    required this.titles,
    required this.current,
    required this.onTapStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final off = theme.colorScheme.onSurface.withAlpha(30);
    final dim = 32.r;

    final children = <Widget>[];
    for (var i = 0; i < titles.length; i++) {
      final done = i < current;
      final active = i == current;
      children.add(
        GestureDetector(
          onTap: () => onTapStep(i),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 62.w,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: dim,
                  height: dim,
                  decoration: BoxDecoration(
                    color: (done || active) ? primary : off,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [
                      BoxShadow(
                        color: primary.withAlpha(90),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ]
                        : null,
                  ),
                  child: Center(
                    child: done
                        ? Icon(Icons.check_rounded,
                        size: 18.sp, color: theme.colorScheme.onPrimary)
                        : Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: active
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  titles[i],
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: (done || active)
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withAlpha(130),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (i < titles.length - 1) {
        children.add(
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(top: dim / 2 - 1.5),
              height: 3,
              decoration: BoxDecoration(
                color: i < current ? primary : off,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}