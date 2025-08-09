import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:fishkart_vendor/services/database/user_database_helper.dart';
import 'package:fishkart_vendor/services/authentification/authentification_service.dart';
import 'package:fishkart_vendor/services/local_files_access/local_files_access_service.dart';
import 'package:fishkart_vendor/services/base64_image_service/base64_image_service.dart';
import 'package:fishkart_vendor/screens/home/home_screen.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 0,
                        top: 16.h,
                        right: 0,
                        bottom: 0,
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(
                            CupertinoIcons.back,
                            color: Colors.black,
                            size: 32.sp,
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

                    SizedBox(height: 8.h),

                    // Profile Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7F9),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15.r,
                            offset: Offset(0, 15.h),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 40.r,
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
                                top: 48.h,
                                left: 38.w,
                                child: GestureDetector(
                                  onTap: _pickAndUploadImage,
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    child: Icon(
                                      Icons.edit_square,
                                      color: Colors.black,
                                      size: 20.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 16.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, there!',
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _nameController.text.toLowerCase(),
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Edit Profile Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 0,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4.h),
                              Text(
                                'Edit profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 40.w,
                                  vertical: 32.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 20.r,
                                      offset: Offset(0, 10.h),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Name"),
                                    SizedBox(height: 11.h),
                                    _buildInput(_nameController, "name"),
                                    SizedBox(height: 18.h),
                                    _buildLabel("Email"),
                                    SizedBox(height: 11.h),
                                    _buildInput(_emailController, "@gmail.com"),
                                    SizedBox(height: 18.h),
                                    _buildLabel("Password"),
                                    SizedBox(height: 11.h),
                                    _buildInput(
                                      TextEditingController(
                                        text: "***********",
                                      ),
                                      "***********",
                                      enabled: false,
                                    ),
                                    SizedBox(height: 18.h),
                                    _buildLabel("Phone Number"),
                                    SizedBox(height: 11.h),
                                    _buildInput(
                                      _phoneController,
                                      "Enter Phone Number",
                                    ),
                                    SizedBox(height: 18.h),
                                    _buildLabel("Location"),
                                    SizedBox(height: 11.h),
                                    _buildInput(
                                      _locationController,
                                      "Enter Location",
                                    ),
                                    SizedBox(height: 24.h),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.w,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _save,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            padding: EdgeInsets.symmetric(
                                              vertical: 20.h,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                          ),
                                          child: Text(
                                            "Save Changes",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24.h),
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
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14.sp,
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
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black54, fontSize: 14.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black12),
          borderRadius: BorderRadius.circular(12.r),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black12),
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}
