import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final postalCodeController = TextEditingController();

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

  Future<void> createProfile() async {
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

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ApiService.createProfile(
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

      Navigator.pop(context);
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
        title: const Text('Create Privacy Profile'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: firstNameController,
              autofillHints: const [],
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
              autofillHints: const [],
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
              autofillHints: const [],
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
              autofillHints: const [],
              enableSuggestions: false,
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
              autofillHints: const [],
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
              autofillHints: const [],
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
              validator: (value) {
                if (value == null) {
                  return 'Please select a state.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: postalCodeController,
              autofillHints: const [],
              enableSuggestions: false,
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

            const SizedBox(height: 8),

            const Text(
              'Choose month, day, and year.',
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

            const SizedBox(height: 24),

            if (selectedMonth != null &&
                selectedDay != null &&
                selectedYear != null)
              Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.cake_outlined),
                  title:
                      const Text('Date of Birth'),
                  subtitle: Text(
                    '${months[selectedMonth]} '
                    '$selectedDay, '
                    '$selectedYear',
                  ),
                ),
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

            FilledButton(
              onPressed:
                  isLoading ? null : createProfile,
              child: Padding(
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
                        'Create Profile',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}