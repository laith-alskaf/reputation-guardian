// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  shopIdData: json['shop_id'] as String,
  emailData: json['email'] as String? ?? '',
  shopNameData: json['shop_name'] as String,
  shopTypeData: json['shop_type'] as String,
  telegramChatIdData: json['telegram_chat_id'] as String?,
  token: json['token'] as String?,
  createdAtData: json['created_at'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'shop_id': instance.shopIdData,
  'email': instance.emailData,
  'shop_name': instance.shopNameData,
  'shop_type': instance.shopTypeData,
  'telegram_chat_id': instance.telegramChatIdData,
  'token': instance.token,
  'created_at': instance.createdAtData,
};
