import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/components/api_response.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String baseUrl = "https://vps113666.serveur-vps.net/api";
  // final String baseUrl = "https://84ca44e231ae.ngrok-free.app/api";
  final storage = FlutterSecureStorage();

  Future<String?> submitDeposit({
    required double amount,
    required String token,
    required String type,
  }) async {
    final url = Uri.parse("$baseUrl/transactions");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "amount": amount,
          "type": type,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reference']; 
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      throw Exception('Erreur réseau ou serveur inaccessible');
    }
  }

  Future<ApiResponse?> submitWithDraw({
    required double amount,
    required String token,
    required String type,
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/retrait");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "amount": amount,
          "type": type,
          "phone": phone,
          "password": password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return ApiResponse(
            success: true, message:data['message'],data:data['reference']);
        // return data['reference'];
      } else {
        final error = jsonDecode(response.body);
          return ApiResponse(success: false, message:error['message']);
      }
    } catch (e) {
      throw Exception('Erreur réseau ou serveur inaccessible');
    }
  }

  Future<bool> changeName({
    required String name,
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/update-name");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "name": name,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      throw Exception('Erreur réseau ou serveur inaccessible');
    }
  }
  Future<bool> sendComment(String comment, {
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/sendComment");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "content": comment,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      throw Exception('Erreur réseau ou serveur inaccessible');
    }
  }
Future<dynamic> subscribeToPlan(String token, String planKey) async {
  final url = Uri.parse('$baseUrl/subscriptions');
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'plan_key': planKey,
    }),
  );

   if (response.statusCode == 201 || response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Erreur lors paiement de l’abonnement : ${response.body}');
  }
}

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
          jsonDecode(response.body)['message'] ?? 'Erreur inconnue');
    }
  }
  Future<bool> updateBeneficiaries({
    required beneficiaries,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/beneficiaries'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'beneficiaries': beneficiaries,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
          jsonDecode(response.body)['message'] ?? 'Erreur inconnue');
    }
  }

  Future<ApiResponse> sendDisbursementToAPI(BuildContext context,
      Map<String, dynamic> payload, String token, double walletBalance) async {
    final url = Uri.parse("$baseUrl/budgets");

    if (token.isEmpty) {
      return ApiResponse(
          success: false,
          message: "Token manquant. Veuillez vous reconnecter.");
    }

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse(
            success: true, message: "Budget créé avec succès");
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['message'] ?? 'Erreur inconnue';

        return ApiResponse(
            success: false, message: errorMessage, code: response.statusCode);
      }
    } catch (e) {
      return ApiResponse(
          success: false, message: "Erreur réseau ou serveur inaccessible");
    }
  }

  Future<String?> checkTransactionStatus(
      String transactionId, String token) async {
    final url = Uri.parse("$baseUrl/transactions/$transactionId/status");

    try {
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['status']; // Ex: SUCCESS, PENDING, FAILED
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> login(
    String phoneNumber, String password) async {
  final url = Uri.parse('$baseUrl/login');

  try {
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone_number': phoneNumber,
        'password': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String token = data['token'];
      Map<String, dynamic> user = data['user'];
      await storage.write(key: "token", value: token);
      await storage.write(key: "refresh_token", value: data['refresh_token']);
      print('Connecté en tant que ${user['name']} avec token: $token');
      return data;
    } else {
      print('Erreur de connexion : ${response.body}');
      return null;
    }
  } catch (e) {
    print('Erreur réseau : $e');
    return null;
  }
}


  Future<bool> refreshToken() async {
    final refreshToken = await storage.read(key: "refresh_token");
    String? token = await storage.read(key: "token");

    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/refresh'),
      headers: {
        "Authorization": "Bearer $refreshToken",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: "token", value: data["token"]);
      return true;
    } else {
      await logout(token); // refresh expiré → déconnexion
      return false;
    }
  }

  Future<http.Response> authorizedRequest(
    Uri url, {
    String method = "GET",
    Map<String, String>? headers,
    Object? body,
  }) async {
    String? accessToken = await storage.read(key: "token");

    headers ??= {};
    headers["Authorization"] = "Bearer $accessToken";
    headers["Content-Type"] = "application/json";

    http.Response response;

    if (method == "POST") {
      response = await http.post(url, headers: headers, body: body);
    } else {
      response = await http.get(url, headers: headers);
    }

    // Si token expiré → refresh
    if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        accessToken = await storage.read(key: "token");
        headers["Authorization"] = "Bearer $accessToken";

        if (method == "POST") {
          response = await http.post(url, headers: headers, body: body);
        } else {
          response = await http.get(url, headers: headers);
        }
      }
    }

    return response;
  }

Future<Map<String, dynamic>?> register(
    String name, String lastName, String phoneNumber, String password, String codeCommercial) async {

  String fullName = "$firstName $lastName";

  final response = await http.post(
    Uri.parse('$baseUrl/register'),
    body: {
      'name': fullName,
      'phone_number': phoneNumber,
      'password': password,
      'codeCommercial': codeCommercial,
    },
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      "success": true,
      "message": data["message"] ?? "Inscription réussi",
      "data": data
    }; // On retourne tout le body pour récupérer message et status
  } else {
    final error = jsonDecode(response.body);
    return {
      "success": false,
      "message": error["message"] ?? "Erreur d'inscription"
    };
  }
}

  Future<bool> logout(token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return response.statusCode == 200;
    } else {
      print("Erreur de déconnexion :${response.statusCode} ${response.body}");
      return false;
    }
  }

  // Future<Map<String, dynamic>?> getUserProfile(token) async {
  //   // String? token = await storage.read(key: "token");
  //   if (token == null) return null;

  //   final response = await http.get(
  //     Uri.parse('$baseUrl/user'),
  //     headers: {'Authorization': 'Bearer $token'},
  //   );

  //   if (response.statusCode == 201 || response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     return null;
  //   }
  // }
Future<Map<String, dynamic>?> getUserProfile(String token) async {
  final url = Uri.parse('$baseUrl/user');

  final response = await http.get(
    url,
    headers: {
      'Accept': 'application/json', // très important
      'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
    try {
      return jsonDecode(response.body);
    } catch (e) {
      return null;
    }
  } else {
    return null;
  }
}

  Future<Map<String, dynamic>?> getCurrentUser({required String token}) async {
    final url = Uri.parse('$baseUrl/user');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Erreur: ${response.body}');
      }
    } catch (e) {
      print('Erreur réseau: $e');
    }

    return null;
  }
}
