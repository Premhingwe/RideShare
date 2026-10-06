import 'package:flutter/material.dart';

class VehicleDocumentsScreen extends StatefulWidget {
  const VehicleDocumentsScreen({super.key});

  @override
  State<VehicleDocumentsScreen> createState() =>
      _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState
    extends State<VehicleDocumentsScreen> {
  final TextEditingController rcNumberController =
      TextEditingController();

  final TextEditingController insuranceNumberController =
      TextEditingController();

  final TextEditingController pucNumberController =
      TextEditingController();

  bool rcUploaded = false;
  bool insuranceUploaded = false;
  bool pucUploaded = false;

  @override
  void dispose() {
    rcNumberController.dispose();
    insuranceNumberController.dispose();
    pucNumberController.dispose();
    super.dispose();
  }

  void uploadDocument(String documentName) {
    setState(() {
      if (documentName == 'RC') {
        rcUploaded = true;
      } else if (documentName == 'Insurance') {
        insuranceUploaded = true;
      } else if (documentName == 'PUC') {
        pucUploaded = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$documentName document selected. Actual upload will be added later.',
        ),
      ),
    );
  }

  void saveDocuments() {
    final String rcNumber =
        rcNumberController.text.trim();

    final String insuranceNumber =
        insuranceNumberController.text.trim();

    final String pucNumber =
        pucNumberController.text.trim();

    if (rcNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your RC number'),
        ),
      );
      return;
    }

    if (insuranceNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your insurance number'),
        ),
      );
      return;
    }

    if (pucNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your PUC number'),
        ),
      );
      return;
    }

    if (!rcUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your RC document'),
        ),
      );
      return;
    }

    if (!insuranceUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your insurance document'),
        ),
      );
      return;
    }

    if (!pucUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your PUC document'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vehicle documents saved successfully.',
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
        title: const Text('Vehicle Documents'),
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
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 55,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Vehicle Documents',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Add the required documents for your bike. These documents will be used for rider verification.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Registration Certificate (RC)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: rcNumberController,
                textCapitalization:
                    TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'RC Number',
                  hintText: 'Example: MH12AB1234',
                  prefixIcon: Icon(
                    Icons.confirmation_number_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              _buildUploadCard(
                title: 'RC Document',
                icon: Icons.upload_file_outlined,
                uploaded: rcUploaded,
                onTap: () => uploadDocument('RC'),
              ),

              const SizedBox(height: 25),

              const Text(
                'Vehicle Insurance',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: insuranceNumberController,
                textCapitalization:
                    TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Insurance Policy Number',
                  hintText:
                      'Enter insurance policy number',
                  prefixIcon: Icon(
                    Icons.shield_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              _buildUploadCard(
                title: 'Insurance Document',
                icon: Icons.upload_file_outlined,
                uploaded: insuranceUploaded,
                onTap: () =>
                    uploadDocument('Insurance'),
              ),

              const SizedBox(height: 25),

              const Text(
                'Pollution Under Control (PUC)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: pucNumberController,
                textCapitalization:
                    TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'PUC Certificate Number',
                  hintText:
                      'Enter PUC certificate number',
                  prefixIcon: Icon(
                    Icons.eco_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              _buildUploadCard(
                title: 'PUC Document',
                icon: Icons.upload_file_outlined,
                uploaded: pucUploaded,
                onTap: () => uploadDocument('PUC'),
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
                      Icons.lock_outline,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your vehicle documents are private and will only be used for verification and safety purposes.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey.shade700,
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
                  onPressed: saveDocuments,
                  child: const Text(
                    'Save & Continue',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  'Document verification will be connected later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required IconData icon,
    required bool uploaded,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Icon(icon),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      uploaded
                          ? 'Document added'
                          : 'Tap to add document',
                      style: TextStyle(
                        fontSize: 13,
                        color: uploaded
                            ? Colors.green
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                uploaded
                    ? Icons.check_circle
                    : Icons.arrow_forward_ios,
                size: uploaded ? 24 : 17,
                color:
                    uploaded ? Colors.green : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}