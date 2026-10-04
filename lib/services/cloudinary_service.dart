import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Simple Cloudinary Image Upload Service
class CloudinaryService {
  static const String cloudName = 'YOUR_CLOUDINARY_CLOUD_NAME';
  static const String uploadPreset = 'personal_finance_receipts';

  static bool get isConfigured =>
      cloudName != 'YOUR_CLOUDINARY_CLOUD_NAME' && cloudName.isNotEmpty;

  // Upload an image file to Cloudinary and return the public URL
  Future<String> uploadImage(File imageFile) async {
    if (!isConfigured) return '';

    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['secure_url'] ?? '';
      }
    } catch (_) {}
    return '';
  }
}
