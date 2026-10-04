import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';

// Profile screen where users can view their account details,
// update their display name, change their password, and sign out
class ProfileScreen extends StatefulWidget {
  final VoidCallback? toggleTheme;
  final bool isDarkMode;

  const ProfileScreen({super.key, this.toggleTheme, this.isDarkMode = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = AppFirebaseService.currentUserName;
  String userEmail = AppFirebaseService.currentUserEmail;

  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;
  bool isUpdatingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = AppFirebaseService().currentUser;
    userName = AppFirebaseService.formatName(user);
    userEmail = user?.email ?? AppFirebaseService.currentUserEmail;
    loadProfile();
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Load user information
  void loadProfile() async {
    final user = AppFirebaseService().currentUser;
    if (user != null) {
      userEmail = user.email ?? AppFirebaseService.currentUserEmail;
      String? foundName;
      if (user.displayName != null && user.displayName!.isNotEmpty && user.displayName != "User") {
        foundName = user.displayName;
      } else {
        final profile = await AppFirebaseService().getUserProfile(user.uid);
        if (profile != null && profile['name'] != null && profile['name'].toString().isNotEmpty && profile['name'].toString() != "User") {
          foundName = profile['name'].toString();
        }
      }
      userName = AppFirebaseService.formatName(user, foundName);
      AppFirebaseService.currentUserName = userName;
      if (mounted) setState(() {});
    }
  }

  // Dialog to edit user's display name
  void editNameDialog() {
    final nameCtrl = TextEditingController(text: userName);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(dialogCtx);
                await AppFirebaseService().updateDisplayName(newName);
                setState(() => userName = newName);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name updated successfully!'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Update password handler
  void handleUpdatePassword() async {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields'), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => isUpdatingPassword = true);

    try {
      await AppFirebaseService().updatePassword(newPass);
      newPasswordController.clear();
      confirmPasswordController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => isUpdatingPassword = false);
    }
  }

  // Sign out confirmation dialog
  void confirmSignOut() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await AppFirebaseService().signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
                ),
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppFirebaseService().currentUser;
    final displayName = (userName.isNotEmpty && userName != "User")
        ? userName
        : AppFirebaseService.formatName(user);
    final displayEmail = userEmail.isNotEmpty
        ? userEmail
        : (user?.email ?? AppFirebaseService.currentUserEmail);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (widget.toggleTheme != null)
            IconButton(
              icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
              onPressed: widget.toggleTheme,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. User Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Color(0xFFDCE7EE),
                      child: Icon(Icons.person, size: 44, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                          tooltip: 'Edit Name',
                          onPressed: editNameDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(displayEmail.isEmpty ? 'No email associated' : displayEmail, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Edit Password Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_reset, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Edit Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: hideNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(hideNewPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => hideNewPassword = !hideNewPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: hideConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(hideConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => hideConfirmPassword = !hideConfirmPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: isUpdatingPassword ? null : handleUpdatePassword,
                      child: isUpdatingPassword
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.logout, color: AppColors.danger),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                onPressed: confirmSignOut,
              ),
            ),
            const SizedBox(height: 24),

            // Footer
            const Text('Personal Finance Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const Text('© 2026 Personal Finance Tracker v1.0.0', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
