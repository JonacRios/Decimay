import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class ImageUploadService {
  static Future<String?> uploadImage(File imageFile, String ip, String port) async {
    try {
      final uri = Uri.parse('http://$ip:$port/upload/');
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = json.decode(responseBody);
        return decodedResponse['prediction'].toString();
      } else {
        return null; // En caso de error, retornamos null
      }
    } catch (e) {
      return null; // En caso de excepción, retornamos null
    }
  }
}
