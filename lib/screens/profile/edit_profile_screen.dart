import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:fishkart_vendor/services/database/user_database_helper.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'package:fishkart_vendor/services/local_files_access/local_files_access_service.dart';
import 'package:fishkart_vendor/services/base64_image_service/base64_image_service.dart';
import 'package:fishkart_vendor/screens/home/home_screen.dart';
import 'package:flutter_svg/svg.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  // String? _displayPictureUrl; // No longer needed
  bool _loading = true;

  String? _cachedDisplayPicture;
  // Removed unused _userStream field

  @override
  void initState() {
    super.initState();
    UserDatabaseHelper().currentUserDataStream.listen((snapshot) async {
      final data = snapshot.data();
      if (data != null) {
        _nameController.text = data['display_name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        final fetched = data['display_picture'] as String?;
        _cachedDisplayPicture = (fetched != null && fetched.isNotEmpty)
            ? fetched
            : null;
      } else {
        _cachedDisplayPicture = null;
      }
      // Fetch areaLocation
      final areaLocation = await UserDatabaseHelper()
          .getCurrentUserAreaLocation();
      if (areaLocation != null) {
        _locationController.text = areaLocation;
      }
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final uid = AuthentificationService().currentUser.uid;
    await UserDatabaseHelper().updateUser(uid, {
      'display_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'areaLocation': _locationController.text.trim(),
    });
    setState(() => _loading = false);
    Navigator.pop(context);
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _loading = true);
      final result = await choseImageFromLocalFiles(context);
      // Removed unused uid and fileBytes
      // Convert image to base64 and store in Firestore
      final base64String = await Base64ImageService().xFileToBase64(
        result.xFile,
      );
      await UserDatabaseHelper().uploadDisplayPictureForCurrentUser(
        base64String,
      );
      setState(() {
        _cachedDisplayPicture = base64String;
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update picture: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 0,
                        top: 16,
                        right: 0,
                        bottom: 0,
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(
                            CupertinoIcons.back,
                            color: Colors.black,
                            size: 32,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          tooltip: 'Back',
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Profile Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7F9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage:
                                    _cachedDisplayPicture != null &&
                                        _cachedDisplayPicture!.isNotEmpty
                                    ? (_cachedDisplayPicture!.startsWith('http')
                                          ? NetworkImage(_cachedDisplayPicture!)
                                          : _cachedDisplayPicture!.startsWith(
                                              'blob:',
                                            )
                                          ? null
                                          : MemoryImage(
                                                  Base64ImageService()
                                                      .base64ToBytes(
                                                        _cachedDisplayPicture!,
                                                      ),
                                                )
                                                as ImageProvider)
                                    : null,
                              ),
                              Positioned(
                                top: 42,
                                left: 48,
                                child: GestureDetector(
                                  onTap: _pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: Image.asset('icons/edit.png'),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hi, there!',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _nameController.text.toLowerCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Edit Profile Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              const Text(
                                'Edit profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 32,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Name"),
                                    const SizedBox(height: 11),
                                    _buildInput(_nameController, "name"),
                                    const SizedBox(height: 18),
                                    _buildLabel("Email"),
                                    const SizedBox(height: 11),
                                    _buildInput(_emailController, "@gmail.com"),
                                    const SizedBox(height: 18),
                                    _buildLabel("Password"),
                                    const SizedBox(height: 11),
                                    _buildInput(
                                      TextEditingController(
                                        text: "***********",
                                      ),
                                      "***********",
                                      enabled: false,
                                    ),
                                    const SizedBox(height: 18),
                                    _buildLabel("Phone Number"),
                                    const SizedBox(height: 11),
                                    _buildInput(
                                      _phoneController,
                                      "Enter Phone Number",
                                    ),
                                    const SizedBox(height: 18),
                                    _buildLabel("Location"),
                                    const SizedBox(height: 11),
                                    _buildInput(
                                      _locationController,
                                      "Enter Location",
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _save,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 20,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            "Save Changes",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint, {
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
