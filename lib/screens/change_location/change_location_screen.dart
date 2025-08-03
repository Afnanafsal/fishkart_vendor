import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishkart_vendor/services/database/user_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart_vendor/providers/user_providers.dart'
    as user_providers;

class ChangeLocationScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ChangeLocationScreen> createState() =>
      _ChangeLocationScreenState();
}

class _ChangeLocationScreenState extends ConsumerState<ChangeLocationScreen> {
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final currentLocation = ref
        .read(user_providers.signUpFormDataProvider)
        .areaLocation;
    _locationController = TextEditingController(text: currentLocation);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 80),
              // Logo
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Shadows Into Light Two',
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'Fish',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: 'Kart',
                      style: TextStyle(color: Color(0xFF29465B)),
                    ),
                    WidgetSpan(child: SizedBox(width: 8)),
                    TextSpan(
                      text: 'vendor',
                      style: TextStyle(color: Color.fromARGB(255, 249, 172, 7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
              Center(
                child: Container(
                  width: 380,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Current Area Location",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Current area location field from Firestore
                      StreamBuilder<DocumentSnapshot>(
                        stream: UserDatabaseHelper().currentUserDataStream,
                        builder: (context, snapshot) {
                          String currentLocation = "";
                          if (snapshot.hasData && snapshot.data != null) {
                            final data = snapshot.data?.data() as Map<String, dynamic>?;
                            currentLocation = data?['areaLocation'] ?? "";
                          }
                          return Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              currentLocation.isNotEmpty ? currentLocation : "No area set",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "New Area Location",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          hintText: 'Enter new area location',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                        onChanged: (value) {
                          ref.read(user_providers.signUpFormDataProvider.notifier).updateAreaLocation(value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Area location cannot be empty";
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 220,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34495E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await _updateLocationButtonCallback(context, ref);
                            },
                            child: const Text(
                              "Update",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateLocationButtonCallback(BuildContext context, WidgetRef ref) async {
    final newLocation = _locationController.text;
    if (newLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Area location cannot be empty")),
      );
      return;
    }
    bool status = false;
    String snackbarMessage = "";
    try {
      // Update area location in Firestore
      status = await UserDatabaseHelper().updateAreaLocationForCurrentUser(newLocation);
      if (status) {
        ref.read(user_providers.signUpFormDataProvider.notifier).updateAreaLocation(newLocation);
        snackbarMessage = "Area location updated successfully";
      } else {
        snackbarMessage = "Failed to update area location";
      }
    } catch (e) {
      snackbarMessage = "Something went wrong";
    } finally {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackbarMessage)),
      );
      if (status) {
        Navigator.pop(context);
      }
    }
  }
}
