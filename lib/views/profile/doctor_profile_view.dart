import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile/doctor_profile_controller.dart';
import '../../core/constants.dart';

class DoctorProfileView extends GetView<DoctorProfileController> {
  const DoctorProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Personal Profile'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading && controller.profile.value == null) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        final user = controller.profile.value;
        if (user == null) {
          return Center(
            child: Text(
              'Failed to load profile'.tr,
              style: TextStyle(color: context.theme.hintColor),
            ),
          );
        }

        return RefreshIndicator(
          color: context.theme.primaryColor,
          onRefresh: controller.fetchProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // ─── Avatar & Name ───
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: context.theme.primaryColor.withOpacity(
                          0.1,
                        ),
                        backgroundImage:
                            (user.profilePicture != null &&
                                user.profilePicture!.isNotEmpty)
                            ? NetworkImage(
                                '$baseUrl/storage/${user.profilePicture}',
                              )
                            : null,
                        child:
                            (user.profilePicture == null ||
                                user.profilePicture!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: context.theme.primaryColor,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.education,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.theme.hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ─── Info Fields ───
                Container(
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.theme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        context,
                        Icons.person_outline,
                        'First Name'.tr,
                        user.firstName,
                        'first_name',
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context,
                        Icons.person_outline,
                        'Last Name'.tr,
                        user.lastName,
                        'last_name',
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context,
                        Icons.phone_outlined,
                        'Phone Number'.tr,
                        user.phoneNumber,
                        'phone_number',
                        isPhone: true,
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context,
                        Icons.email_outlined,
                        'Email'.tr,
                        user.email,
                        'email',
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context,
                        Icons.location_on_outlined,
                        'Address'.tr,
                        user.address,
                        'address',
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context,
                        Icons.work_outline,
                        'Experience Years'.tr,
                        '${user.experienceYears}',
                        'experience_years',
                        isNumber: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    String apiFieldKey, {
    bool isPhone = false,
    bool isNumber = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.theme.primaryColor, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: context.theme.hintColor),
      ),
      subtitle: Text(
        value.isEmpty ? 'Not set'.tr : value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: context.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Icon(
        Icons.edit_outlined,
        size: 18,
        color: context.theme.hintColor,
      ),
      onTap: () => _showEditDialog(
        context,
        label,
        value,
        apiFieldKey,
        isPhone,
        isNumber,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: context.theme.dividerColor.withOpacity(0.3),
      height: 1,
      indent: 70,
      endIndent: 20,
    );
  }

  void _showEditDialog(
    BuildContext context,
    String label,
    String currentValue,
    String apiFieldKey,
    bool isPhone,
    bool isNumber,
  ) {
    final TextEditingController textController = TextEditingController(
      text: currentValue,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit'.tr + ' ' + label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: textController,
                  keyboardType: isPhone
                      ? TextInputType.phone
                      : (isNumber ? TextInputType.number : TextInputType.text),
                  style: TextStyle(color: context.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.theme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                context.theme.scaffoldBackgroundColor,
                            foregroundColor: context.textTheme.bodyLarge?.color,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: context.theme.dividerColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 👈 زر الحفظ
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            controller.updateProfileField(
                              apiFieldKey,
                              textController.text,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.theme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Save'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
