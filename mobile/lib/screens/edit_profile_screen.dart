import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  final Map<String, dynamic> profile;

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController streetController;
  late final TextEditingController cityController;
  late final TextEditingController postalCodeController;

  String? selectedState;

  int? selectedMonth;
  int? selectedDay;
  int? selectedYear;

  bool isLoading = false;
  String? errorMessage;

  final Map<String, String> states = {
    'Alabama': 'AL',
    'Alaska': 'AK',
    'Arizona': 'AZ',
    'Arkansas': 'AR',
    'California': 'CA',
    'Colorado': 'CO',
    'Connecticut': 'CT',
    'Delaware': 'DE',
    'Florida': 'FL',
    'Georgia': 'GA',
    'Hawaii': 'HI',
    'Idaho': 'ID',
    'Illinois': 'IL',
    'Indiana': 'IN',
    'Iowa': 'IA',
    'Kansas': 'KS',
    'Kentucky': 'KY',
    'Louisiana': 'LA',
    'Maine': 'ME',
    'Maryland': 'MD',
    'Massachusetts': 'MA',
    'Michigan': 'MI',
    'Minnesota': 'MN',
    'Mississippi': 'MS',
    'Missouri': 'MO',
    'Montana': 'MT',
    'Nebraska': 'NE',
    'Nevada': 'NV',
    'New Hampshire': 'NH',
    'New Jersey': 'NJ',
    'New Mexico': 'NM',
    'New York': 'NY',
    'North Carolina': 'NC',
    'North Dakota': 'ND',
    'Ohio': 'OH',
    'Oklahoma': 'OK',
    'Oregon': 'OR',
    'Pennsylvania': 'PA',
    'Rhode Island': 'RI',
    'South Carolina': 'SC',
    'South Dakota': 'SD',
    'Tennessee': 'TN',
    'Texas': 'TX',
    'Utah': 'UT',
    'Vermont': 'VT',
    'Virginia': 'VA',
    'Washington': 'WA',
    'West Virginia': 'WV',
    'Wisconsin': 'WI',
    'Wyoming': 'WY',
  };

  final Map<int, String> months = const {
    1: 'January',
    2: 'February',
    3: 'March',
    4: 'April',
    5: 'May',
    6: 'June',
    7: 'July',
    8: 'August',
    9: 'September',
    10: 'October',
    11: 'November',
    12: 'December',
  };

  @override
  void initState() {
    super.initState();

    final emails =
        widget.profile['email_addresses'] as List<dynamic>? ?? [];

    final phones =
        widget.profile['phone_numbers'] as List<dynamic>? ?? [];

    final address =
        widget.profile['current_address'] as Map<String, dynamic>? ?? {};

    firstNameController = TextEditingController(
      text: widget.profile['first_name']?.toString() ?? '',
    );

    lastNameController = TextEditingController(
      text: widget.profile['last_name']?.toString() ?? '',
    );

    emailController = TextEditingController(
      text: emails.isNotEmpty ? emails.first.toString() : '',
    );

    phoneController = TextEditingController(
      text: phones.isNotEmpty ? phones.first.toString() : '',
    );

    streetController = TextEditingController(
      text: address['street']?.toString() ?? '',
    );

    cityController = TextEditingController(
      text: address['city']?.toString() ?? '',
    );

    postalCodeController = TextEditingController(
      text: address['postal_code']?.toString() ?? '',
    );

    selectedState = address['state']?.toString();

    final dateString =
        widget.profile['date_of_birth']?.toString();

    if (dateString != null && dateString.isNotEmpty) {
      final parsed = DateTime.tryParse(dateString);

      if (parsed != null) {
        selectedYear = parsed.year;
        selectedMonth = parsed.month;
        selectedDay = parsed.day;
      }
    }
  }

  bool isLeapYear(int year) {
    if (year % 400 == 0) {
      return true;
    }

    if (year % 100 == 0) {
      return false;
    }

    return year % 4 == 0;
  }

  int daysInMonth(int month, int year) {
    if (month == 2) {
      return isLeapYear(year) ? 29 : 28;
    }

    if ({
      4,
      6,
      9,
      11,
    }.contains(month)) {
      return 30;
    }

    return 31;
  }

  List<int> get availableDays {
    if (selectedMonth == null || selectedYear == null) {
      return List.generate(
        31,
        (index) => index + 1,
      );
    }

    final count = daysInMonth(
      selectedMonth!,
      selectedYear!,
    );

    return List.generate(
      count,
      (index) => index + 1,
    );
  }

  List<int> get availableYears {
    final currentYear = DateTime.now().year;

    return List.generate(
      currentYear - 1899,
      (index) => currentYear - index,
    );
  }

  void validateSelectedDay() {
    if (selectedDay == null ||
        selectedMonth == null ||
        selectedYear == null) {
      return;
    }

    final maxDay = daysInMonth(
      selectedMonth!,
      selectedYear!,
    );

    if (selectedDay! > maxDay) {
      selectedDay = null;
    }
  }

  String formatApiDate() {
    final year = selectedYear.toString();
    final month =
        selectedMonth.toString().padLeft(2, '0');
    final day =
        selectedDay.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }

    final emailPattern = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedState == null) {
      setState(() {
        errorMessage = 'Please select a state.';
      });
      return;
    }

    if (selectedMonth == null ||
        selectedDay == null ||
        selectedYear == null) {
      setState(() {
        errorMessage =
            'Please select your complete date of birth.';
      });
      return;
    }

    final profileId =
        widget.profile['profile_id']?.toString();

    if (profileId == null || profileId.isEmpty) {
      setState(() {
        errorMessage = 'Profile ID is missing.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ApiService.updateProfile(
        profileId: profileId,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        street: streetController.text.trim(),
        city: cityController.text.trim(),
        state: selectedState!,
        postalCode: postalCodeController.text.trim(),
        dateOfBirth: formatApiDate(),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    streetController.dispose();
    cityController.dispose();
    postalCodeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Privacy Profile'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: firstNameController,
              textCapitalization:
                  TextCapitalization.words,
              validator: requiredValidator,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: lastNameController,
              textCapitalization:
                  TextCapitalization.words,
              validator: requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: emailController,
              keyboardType:
                  TextInputType.emailAddress,
              validator: emailValidator,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              validator: requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: streetController,
              textCapitalization:
                  TextCapitalization.words,
              validator: requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: cityController,
              textCapitalization:
                  TextCapitalization.words,
              validator: requiredValidator,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: selectedState,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
              items: states.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(
                    '${entry.key} (${entry.value})',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedState = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: postalCodeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              validator: requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Postal Code',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Date of Birth',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              initialValue: selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Month',
                border: OutlineInputBorder(),
              ),
              items: months.entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value;
                  validateSelectedDay();
                });
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              initialValue: selectedDay,
              decoration: const InputDecoration(
                labelText: 'Day',
                border: OutlineInputBorder(),
              ),
              items: availableDays.map((day) {
                return DropdownMenuItem<int>(
                  value: day,
                  child: Text(day.toString()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDay = value;
                });
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              initialValue: selectedYear,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              items: availableYears.map((year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedYear = value;
                  validateSelectedDay();
                });
              },
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed:
                  isLoading ? null : saveProfile,
              icon: const Icon(Icons.save_outlined),
              label: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}