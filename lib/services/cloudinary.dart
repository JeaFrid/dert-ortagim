import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

Future<String?> uploadVideoToCloudinary(File videoFile) async {
  String cloudName = "dmykgiomj";
  String apiKey = "246933816531216";
  String uploadPreset = "video_preset";

  try {
    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/video/upload");
    final request = http.MultipartRequest("POST", uri);
    request.fields['api_key'] = apiKey;
    request.fields['upload_preset'] = uploadPreset;
    request.files
        .add(await http.MultipartFile.fromPath("file", videoFile.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      if (kDebugMode) {
        print("Video başarıyla yüklendi: $responseData");
      }
      final jsonResponse = jsonDecode(responseData);
      return jsonResponse['secure_url'];
    } else {
      final errorData = await response.stream.bytesToString();
      if (kDebugMode) {
        print(
            "Video yükleme başarısız oldu. Durum Kodu: ${response.statusCode}");
      }
      if (kDebugMode) {
        print("Hata Mesajı: $errorData");
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) {
      print("Hata: $e");
    }
    return null;
  }
}

Future<File?> pickVideo() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

  if (pickedFile != null) {
    return File(pickedFile.path);
  } else {
    print("Video seçilmedi.");
    return null;
  }
}

Future<void> pickAndUploadVideo() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

  if (pickedFile != null) {
    final videoFile = File(pickedFile.path);
    final videoUrl = await uploadVideoToCloudinary(videoFile);

    if (videoUrl != null) {
      if (kDebugMode) {
        print("Video URL'si: $videoUrl");
      }
    } else {
      if (kDebugMode) {
        print("Video yükleme başarısız.");
      }
    }
  } else {
    if (kDebugMode) {
      print("Video seçilmedi.");
    }
  }
}

Future<String?> uploadImageToCloudinary(File imageFile) async {
  String cloudName = "dmykgiomj";
  String apiKey = "246933816531216";
  String uploadPreset =
      "image_preset"; // Fotoğraf için belirlenmiş upload preset

  try {
    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    final request = http.MultipartRequest("POST", uri);
    request.fields['api_key'] = apiKey;
    request.fields['upload_preset'] = uploadPreset;
    request.files
        .add(await http.MultipartFile.fromPath("file", imageFile.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      if (kDebugMode) {
        print("Fotoğraf başarıyla yüklendi: $responseData");
      }
      final jsonResponse = jsonDecode(responseData);
      return jsonResponse['secure_url'];
    } else {
      final errorData = await response.stream.bytesToString();
      if (kDebugMode) {
        print(
            "Fotoğraf yükleme başarısız oldu. Durum Kodu: ${response.statusCode}");
      }
      if (kDebugMode) {
        print("Hata Mesajı: $errorData");
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) {
      print("Hata: $e");
    }
    return null;
  }
}

Future<String?> pickAndUploadImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    final imageFile = File(pickedFile.path);
    final imageUrl = await uploadImageToCloudinary(imageFile);

    if (imageUrl != null) {
      return imageUrl;
    } else {
      return null;
    }
  } else {
    return null;
  }
}
