import 'package:flutter/material.dart';

class DrivingLicenceScreen extends StatefulWidget {
  const DrivingLicenceScreen({super.key});

  @override
  State<DrivingLicenceScreen> createState() =>
      _DrivingLicenceScreenState();
}

class _DrivingLicenceScreenState
    extends State<DrivingLicenceScreen> {
  final TextEditingController licenceNumberController =
      TextEditingController();

  final TextEditingController nameController =
      TextEditingController();

  DateTime? selectedDate;

  @override
  void dispose() {
    licenceNumberController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void continueVerification() {
    final licenceNumber =
        licenceNumberController.text.trim();

    final name = nameController.text.trim();

    if (licenceNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your driving licence number',
          ),
        ),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the licence holder name',
          ),
        ),
      );
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select your date of birth',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Driving Licence details saved successfully.',
        ),
      ),
    );

    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) return;

        Navigator.pop(context, true);
      },
    );
  }

  String get formattedDate {
    if (selectedDate == null) {
      return 'Select your date of birth';
    }

    final day =
        selectedDate!.day.toString().padLeft(2, '0');

    final month =
        selectedDate!.month.toString().padLeft(2, '0');

    final year =
        selectedDate!.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driving Licence'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color:
                        Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    size: 55,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Driving Licence Verification',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Enter the details exactly as they appear on your driving licence.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller:
                    licenceNumberController,
                textCapitalization:
                    TextCapitalization.characters,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Driving Licence Number',
                  hintText:
                      'Example: MH12 20201234567',
                  prefixIcon: Icon(
                    Icons.credit_card_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: nameController,
                textCapitalization:
                    TextCapitalization.words,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Licence Holder Name',
                  hintText:
                      'Enter name as on licence',
                  prefixIcon: Icon(
                    Icons.person_outline,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              InkWell(
                onTap: selectDate,
                borderRadius:
                    BorderRadius.circular(4),
                child: InputDecorator(
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Date of Birth',
                    prefixIcon: Icon(
                      Icons.calendar_today_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          selectedDate == null
                              ? Colors.grey.shade600
                              : Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Container(
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your driving licence information will be stored securely in your rider profile and will only be used for verification.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      continueVerification,
                  child: const Text(
                    'Save & Continue',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  'Actual document verification will be connected later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}