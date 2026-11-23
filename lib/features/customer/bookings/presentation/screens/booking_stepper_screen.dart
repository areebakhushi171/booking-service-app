import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_confirmation_screen.dart';

class BookingStepperScreen extends StatefulWidget {
  final ServiceModel service;

  const BookingStepperScreen({super.key, required this.service});

  @override
  State<BookingStepperScreen> createState() => _BookingStepperScreenState();
}

class _BookingStepperScreenState extends State<BookingStepperScreen> {
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
    // Generate next 30 days
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
            backgroundColor: Colors.red.shade700,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        elevation: 0,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        elevation: 0,
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        onStepTapped: (step) {
          if (step < _currentStep) {
            setState(() => _currentStep = step);
          }
        },
        steps: [
          // Step 1: Choose Date
          Step(
            title: const Text('Date'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a Date (Next 30 Days)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  height: 90.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableDates.length,
                    itemBuilder: (context, idx) {
                      final date = _availableDates[idx];
                      final isSelected = date.year == _selectedDate.year &&
                          date.month == _selectedDate.month &&
                          date.day == _selectedDate.day;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                            _selectedSlot = null; // reset slot selection
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 68.w,
                          margin: EdgeInsets.only(right: 10.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor.withAlpha(40),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withAlpha(80),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
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
                                      ? Colors.white70
                                      : Colors.grey,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                DateFormat('dd').format(date),
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                DateFormat('MMM').format(date),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Selected Date: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 24.h),
                CustomButton(
                  label: 'Proceed to Time Slot',
                  onPressed: () => setState(() => _currentStep = 1),
                ),
              ],
            ),
          ),

          // Step 2: Choose Time Slot
          Step(
            title: const Text('Time'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Available Slot',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Duration: ${widget.service.formattedDuration}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
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
                  children: slotStatuses.map((status) {
                    final isSelected = _selectedSlot == status.time;
                    final isAvailable = status.isAvailable;

                    return Tooltip(
                      message: status.reason ?? 'Available for booking',
                      child: InkWell(
                        onTap: isAvailable
                            ? () => setState(() => _selectedSlot = status.time)
                            : null,
                        borderRadius: BorderRadius.circular(12.r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isAvailable
                                    ? theme.cardColor
                                    : (theme.brightness == Brightness.dark
                                        ? Colors.white10
                                        : Colors.grey.shade200)),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (isAvailable
                                      ? theme.dividerColor.withAlpha(40)
                                      : Colors.transparent),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAvailable
                                    ? Icons.schedule_rounded
                                    : Icons.block_rounded,
                                size: 14.sp,
                                color: isSelected
                                    ? Colors.white
                                    : (isAvailable
                                        ? theme.colorScheme.primary
                                        : Colors.grey),
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
                                      ? Colors.white
                                      : (isAvailable
                                          ? theme.colorScheme.onSurface
                                          : Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 28.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Back',
                        isOutlined: true,
                        onPressed: () => setState(() => _currentStep = 0),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: CustomButton(
                        label: 'Next',
                        onPressed: _selectedSlot != null
                            ? () => setState(() => _currentStep = 2)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Step 3: Instructions & Notes
          Step(
            title: const Text('Details'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Address & Specific Instructions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 14.h),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Service Delivery Address',
                    hintText: 'e.g. House #14, Sector Y, DHA Phase 5, Lahore',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Special Notes / Preferences (Optional)',
                    hintText:
                        'e.g. Please ring doorbell twice, specific model is 1.5 ton Inverter AC, etc.',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                SizedBox(height: 28.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Back',
                        isOutlined: true,
                        onPressed: () => setState(() => _currentStep = 1),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: CustomButton(
                        label: 'Review Booking',
                        onPressed: () => setState(() => _currentStep = 3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Step 4: Review & Confirm
          Step(
            title: const Text('Confirm'),
            isActive: _currentStep >= 3,
            state: StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: theme.dividerColor.withAlpha(30)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Service:'),
                          Expanded(
                            child: Text(
                              widget.service.name,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 20.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Date:'),
                          Text(
                            DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Time Window:'),
                          Text(
                            '$_selectedSlot - ${BookingProvider.calculateEndTime(_selectedSlot ?? '09:00', widget.service.durationMinutes)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Duration:'),
                          Text(widget.service.formattedDuration),
                        ],
                      ),
                      Divider(height: 20.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Due (Pay at service):',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.service.formattedPrice,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Back',
                        isOutlined: true,
                        onPressed: () => setState(() => _currentStep = 2),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: CustomButton(
                        label: 'Confirm Booking',
                        isLoading: _isSubmitting,
                        onPressed: _submitBooking,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
