import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderModel {
  final int number;
  final String data;
  final String time;
  final String status;
  final Delivery delivery;
  final String translationFrom;
  final List<TranslationTo> translationTo;
  final String notes;
  final List<String> files;

  OrderModel({
    required this.number,
    required this.data,
    required this.time,
    required this.status,
    required this.delivery,
    required this.translationFrom,
    required this.translationTo,
    required this.notes,
    required this.files,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      number: json['number']??0,
      data: json['date'] ?? '',  // هنا إذا كانت null نضع سلسلة فارغة
      time: json['time'] ?? '',  // هنا إذا كانت null نضع سلسلة فارغة
      status: json['status'] ?? '',  // هنا إذا كانت null نضع سلسلة فارغة
      delivery: Delivery.fromJson(json['delivery']),
      translationFrom: json['translationfrom'] ?? '',  // هنا إذا كانت null نضع سلسلة فارغة
      translationTo: (json['translationto'] as List)
          .map((item) => TranslationTo.fromJson(item))
          .toList(),
      notes: json['notes'] ?? '',  // إذا كانت null نضع سلسلة فارغة
      files: List<String>.from(json['files'] ?? []),  // إذا كانت null نضع قائمة فارغة
    );
  }
}

class Delivery {
  final String address;
  final String type;

  Delivery({
    required this.address,
    required this.type,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      address: json['address'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class TranslationTo {
  final String name;
  final String arabicName;
  final int cost;

  TranslationTo({
    required this.name,
    required this.arabicName,
    required this.cost,
  });

  factory TranslationTo.fromJson(Map<String, dynamic> json) {
    return TranslationTo(
      name: json['name'],
      arabicName: json['Arabicname'],
      cost: json['cost'],
    );
  }
}


Future<OrderModel> fetchOrderDetails(String orderNumber) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  final response = await http.get(
    Uri.parse('https://wckb4f4m-3000.euw.devtunnels.ms/api/order/$orderNumber'),
    headers: {
      'Content-Type': 'application/json',
      "Authorization": "Bearer ${await _getToken()}",
    },
  );

  if (response.statusCode == 200) {
    return OrderModel.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('فشل في تحميل تفاصيل الطلب: ${response.statusCode}');
  }
}
