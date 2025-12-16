import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  @JsonKey(name: 'shop_id')
  final String shopIdData;

  @JsonKey(name: 'email', defaultValue: '')
  final String? emailData;

  @JsonKey(name: 'shop_name')
  final String shopNameData;

  @JsonKey(name: 'shop_type')
  final String shopTypeData;

  @JsonKey(name: 'telegram_chat_id')
  final String? telegramChatIdData;

  @JsonKey(name: 'token')
  final String? token;

  @JsonKey(name: 'created_at')
  final String? createdAtData;

  UserModel({
    required this.shopIdData,
    this.emailData,
    required this.shopNameData,
    required this.shopTypeData,
    this.telegramChatIdData,
    this.token,
    this.createdAtData,
  }) : super(
         shopId: shopIdData,
         email: emailData ?? '',
         shopName: shopNameData,
         shopType: shopTypeData,
         telegramChatId: telegramChatIdData,
         createdAt: DateTime.now(),
       );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return _$UserModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  User toEntity() {
    return User(
      shopId: shopIdData,
      email: emailData ?? '',
      shopName: shopNameData,
      shopType: shopTypeData,
      telegramChatId: telegramChatIdData,
      createdAt: createdAtData != null
          ? DateTime.parse(createdAtData!)
          : DateTime.now(),
    );
  }
}
