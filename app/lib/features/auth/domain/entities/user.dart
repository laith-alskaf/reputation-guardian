import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String shopId;
  final String email;
  final String shopName;
  final String shopType;
  final String? telegramChatId;
  final DateTime createdAt;

  const User({
    required this.shopId,
    required this.email,
    required this.shopName,
    required this.shopType,
    this.telegramChatId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    shopId,
    email,
    shopName,
    shopType,
    telegramChatId,
    createdAt,
  ];
}
