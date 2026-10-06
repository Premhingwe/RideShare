import 'package:flutter/material.dart';
import 'driving_licence_screen.dart';
import 'vehicle_details_screen.dart';
import 'vehicle_documents_screen.dart';
import 'create_ride_screen.dart';

class RiderVerificationScreen extends StatefulWidget {
  const RiderVerificationScreen({super.key});

  @override
  State<RiderVerificationScreen> createState() =>
      _RiderVerificationScreenState();
}

class _RiderVerificationScreenState
    extends State<RiderVerificationScreen> {
  bool drivingLicenceCompleted = false;
  bool vehicleDetailsCompleted = false;
  bool vehicleDocumentsCompleted = false;

  Future<void> openDrivingLicence() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DrivingLicenceScreen(),
      ),
    );

    if (result == true) {
      setState(() {
        drivingLicenceCompleted = true;
      });
    }
  }

  Future<void> openVehicleDetails() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VehicleDetailsScreen(),
      ),
    );

    if (result == true) {
      setState(() {
        vehicleDetailsCompleted = true;
      });
    }
  }

  Future<void> openVehicleDocuments() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VehicleDocumentsScreen(),
      ),
    );

    if (result == true) {
      setState(() {
        vehicleDocumentsCompleted = true;
      });
    }
  }

  void continueVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRideScreen(),
      ),
    );
  }

  Widget verificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool completed,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: completed
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  completed
                      ? Icons.check_circle
                      : icon,
                  color: completed
                      ? Colors.green
                      : Colors.black87,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      completed
                          ? 'Completed'
                          : subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: completed
                            ? Colors.green
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                completed
                    ? Icons.check_circle
                    : Icons.arrow_forward_ios,
                size: completed ? 25 : 18,
                color: completed
                    ? Colors.green
                    : Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool allCompleted =
        drivingLicenceCompleted &&
        vehicleDetailsCompleted &&
        vehicleDocumentsCompleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Verification'),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Become a Rider',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Complete your verification before creating a ride.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 30),

              verificationCard(
                title: 'Driving Licence',
                subtitle:
                    'Add your valid driving licence details',
                icon: Icons.credit_card,
                completed: drivingLicenceCompleted,
                onTap: openDrivingLicence,
              ),

              verificationCard(
                title: 'Vehicle Details',
                subtitle:
                    'Add information about your bike',
                icon: Icons.two_wheeler,
                completed: vehicleDetailsCompleted,
                onTap: openVehicleDetails,
              ),

              verificationCard(
                title: 'Vehicle Documents',
                subtitle:
                    'Add RC, insurance and PUC details',
                icon: Icons.description_outlined,
                completed: vehicleDocumentsCompleted,
                onTap: openVehicleDocuments,
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
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
                        'Your verification information will be stored securely and used only for rider verification.',
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
                  onPressed: allCompleted
                      ? continueVerification
                      : null,
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              if (!allCompleted)
                Center(
                  child: Text(
                    'Complete all verification steps to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
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