import 'package:flutter/material.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState
    extends State<VehicleDetailsScreen> {
  final TextEditingController bikeNameController =
      TextEditingController();

  final TextEditingController registrationController =
      TextEditingController();

  final TextEditingController modelController =
      TextEditingController();

  String? selectedColour;
  String? selectedYear;

  final List<String> colours = [
    'Black',
    'White',
    'Red',
    'Blue',
    'Grey',
    'Silver',
    'Other',
  ];

  final List<String> years = [
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018',
    '2017',
    '2016',
    '2015',
  ];

  @override
  void dispose() {
    bikeNameController.dispose();
    registrationController.dispose();
    modelController.dispose();
    super.dispose();
  }

  void saveVehicleDetails() {
    final bikeName = bikeNameController.text.trim();
    final registrationNumber =
        registrationController.text.trim();
    final model = modelController.text.trim();

    if (bikeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your bike name'),
        ),
      );
      return;
    }

    if (registrationNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your registration number'),
        ),
      );
      return;
    }

    if (model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your bike model'),
        ),
      );
      return;
    }

    if (selectedColour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your bike colour'),
        ),
      );
      return;
    }

    if (selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your bike year'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vehicle details saved successfully.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
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
                    Icons.two_wheeler_outlined,
                    size: 55,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Your Vehicle',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Add the basic details of the bike you will use for sharing rides.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: bikeNameController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Bike Name',
                  hintText:
                      'Example: Honda, TVS, Bajaj',
                  prefixIcon: Icon(
                    Icons.two_wheeler_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: modelController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Bike Model',
                  hintText:
                      'Example: Activa 6G, Apache RTR 160',
                  prefixIcon: Icon(
                    Icons.motorcycle_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller:
                    registrationController,
                textCapitalization:
                    TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  hintText: 'Example: MH12AB1234',
                  prefixIcon: Icon(
                    Icons.confirmation_number_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedColour,
                decoration: const InputDecoration(
                  labelText: 'Bike Colour',
                  prefixIcon: Icon(
                    Icons.color_lens_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: colours.map((colour) {
                  return DropdownMenuItem<String>(
                    value: colour,
                    child: Text(colour),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedColour = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Manufacturing Year',
                  prefixIcon: Icon(
                    Icons.calendar_today_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: years.map((year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedYear = value;
                  });
                },
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(16),
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
                      Icons.info_outline,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure the vehicle details match your official vehicle documents.',
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
                      saveVehicleDetails,
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
                  'You can update these details later from your profile.',
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