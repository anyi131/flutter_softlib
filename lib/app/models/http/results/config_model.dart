import 'package:json_annotation/json_annotation.dart';

part 'config_model.g.dart';

@JsonSerializable()
class ConfigModel {
  @JsonKey(name: "code")
  int? code;
  @JsonKey(name: "msg")
  String? msg;
  @JsonKey(name: "time")
  String? time;
  @JsonKey(name: "data")
  ConfigData? data;

  ConfigModel({this.code, this.msg, this.time, this.data});

  factory ConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigModelToJson(this);
}

@JsonSerializable()
class ConfigData {
  @JsonKey(name: "feedback_group")
  String? feedbackGroup;
  @JsonKey(name: "feedback_user")
  String? feedbackUser;
  @JsonKey(name: "placard")
  String? placard;
  @JsonKey(name: "feedback_group_on")
  int? feedbackGroupOn;
  @JsonKey(name: "feedback_user_on")
  int? feedbackUserOn;

  ConfigData({
    this.feedbackGroup,
    this.feedbackUser,
    this.placard,
    this.feedbackGroupOn,
    this.feedbackUserOn,
  });

  factory ConfigData.fromJson(Map<String, dynamic> json) =>
      _$ConfigDataFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigDataToJson(this);
}
