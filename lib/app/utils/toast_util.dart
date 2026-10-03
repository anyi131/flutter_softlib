import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtil {
  /// 错误
  static void error(String message) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// 普通提示
  static void info(String message) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: const Color(0xCC303030),
      textColor: Colors.white,
      fontSize: 15.0,
    );
  }

  /// 成功
  static void success(String message) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
