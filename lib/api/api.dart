import 'dart:convert';
import 'dart:developer';
import 'package:ehr_report/pagelogin.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:platform_device_id/platform_device_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io' show Platform;
import 'package:safe_device/safe_device.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class ApiHandler {
  String _apiurl = 'https://your.domainnamegoeshere.xyz/api/ehrreport';

  String _token = '';
  String _devid = '';
  String _devinf = '';
  String _appver = '0';
  int _deftimout = 60;

  _connectionCheck() async {
    print('tes connectioncheck');
    SharedPreferences locStor = await SharedPreferences.getInstance();
    if (locStor.getString('con_type') == '2') {
      // _apiurl = 'https://app.koneksiehr.id/api/ehrreport';
    }
    String? usr = locStor.getString('user');
    if (usr != null) {
      try {
        var usrDat = jsonDecode(usr);
        if (usrDat is Map) {
          int? usrTmo = int.tryParse(usrDat['timeout_duration']);
          if (usrTmo != null) {
            _deftimout = usrTmo;
          }
        }
      } catch (e) {}
    }
  }

  _getToken() async {
    print('tes gettoken');
    SharedPreferences locStor = await SharedPreferences.getInstance();
    if (locStor.getString('token') != null &&
        locStor.getString('token') != '' &&
        locStor.getString('token') != 'null') {
      _token = jsonDecode(locStor.getString('token') ?? '')['token'];
      // log(_token.toString());
    } else {
      _token = '';
    }
    //  String? rawToken = locStor.getString('token');

// if (rawToken != null && rawToken.isNotEmpty && rawToken != 'null') {
//   _token = rawToken; // Gunakan token mentah langsung
//   log('Token: $_token');
// } else {
//   _token = '';
//   print('Token is null or empty');
// }
    // String? deviceId = await PlatformDeviceId.getDeviceId;
    // if (deviceId != null) {
    //   _devid = deviceId;
    // }
    // final deviceInfoPlugin = DeviceInfoPlugin();
    // final deviceInfo = await deviceInfoPlugin.deviceInfo;
    // final Map allInfo = deviceInfo.data;
    // if (deviceInfo != null) {
    //   _devinf = jsonEncode(allInfo);
    // }
  }

  _getappver() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appver = packageInfo.version;
    } catch (e) {}
  }

  authData(data, apiUrl, {bldctx = null}) async {
    print('tes authdata');
    EasyLoading.show(status: 'Loading', maskType: EasyLoadingMaskType.black);
    await _connectionCheck();
    await _fakecheck();
    await _getappver();
    log('API URL: $apiUrl');

    final fcmToken = await FirebaseMessaging.instance.getToken();
    // final fcmToken = null;

    var fullUrl = _apiurl + apiUrl + '?fbtoken=' + fcmToken.toString();
    var res = await http
        .post(Uri.parse(fullUrl),
            body: jsonEncode(data), headers: _setHeaders())
        .onError((error, stackTrace) => http.Response(
            jsonEncode({'success': false, 'message': error.toString()}), 401))
        .timeout(Duration(seconds: _deftimout), onTimeout: () {
      Fluttertoast.showToast(msg: 'Request Timed Out');
      return http.Response(
          jsonEncode({'success': false, 'message': 'Request Timed Out'}), 401);
    });
    EasyLoading.dismiss();
    if (res.statusCode == 408) {
      _changeConMethod(b: bldctx);
    } else if (res.statusCode == 401) {
      SharedPreferences locStor = await SharedPreferences.getInstance();
      locStor.setString('user', '');
      locStor.setString('token', '');
      var body = jsonDecode(res.body);
      if (body is Map) {
        if (body['message'].toString().contains('Failed host lookup')) {
          _changeConMethod(b: bldctx);
        }
      }
    }
    return res;
  }
  authOut({bldctx = null}) async {
    print('tes authout');
    EasyLoading.show(status: 'Loading', maskType: EasyLoadingMaskType.black);
    await _connectionCheck();
    await _getappver();

    var fullUrl = '$_apiurl/logout';
    await _getToken();
    var res = await http
        .get(Uri.parse(fullUrl), headers: _setHeaders())
        .onError((error, stackTrace) => http.Response(
            jsonEncode({'success': false, 'message': error.toString()}), 401))
        .timeout(Duration(seconds: _deftimout), onTimeout: () {
      Fluttertoast.showToast(msg: 'Request Timed Out');
      return http.Response(
          jsonEncode({'success': false, 'message': 'Request Timed Out'}), 401);
    });
    EasyLoading.dismiss();
    if (res.statusCode == 408) {
      _changeConMethod(b: bldctx);
    } else if (res.statusCode == 401) {
      SharedPreferences locStor = await SharedPreferences.getInstance();
      locStor.setString('user', '');
      locStor.setString('token', '');
      var body = jsonDecode(res.body);
      if (body is Map) {
        if (body['message'].toString().contains('Failed host lookup')) {
          _changeConMethod(b: bldctx);
        }
      }
    }
    if (res.statusCode == 200) {
      SharedPreferences locStor = await SharedPreferences.getInstance();
      locStor.setString('user', '');
      locStor.setString('token', '');
      Get.offAll(() => const LoginPage());
    }
  }

  authCheck({bldctx = null}) async {
    print('tes authcheck');
    EasyLoading.show(status: 'Loading', maskType: EasyLoadingMaskType.black);
    await _connectionCheck();
    await _fakecheck();
    await _getappver();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    // final fcmToken = null;
    var fullUrl = '$_apiurl/auth-check?fbtoken=$fcmToken';
    await _getToken();
    var res = await http
        .get(Uri.parse(fullUrl), headers: _setHeaders())
        .onError((error, stackTrace) => http.Response(
            jsonEncode({'success': false, 'message': error.toString()}), 401))
        .timeout(Duration(seconds: _deftimout), onTimeout: () {
      Fluttertoast.showToast(msg: 'Request Timed Out');
      return http.Response(
          jsonEncode({'success': false, 'message': 'Request Timed Out'}), 401);
    });
    EasyLoading.dismiss();
    if (res.statusCode == 408) {
      _changeConMethod(b: bldctx);
    } else if (res.statusCode == 401) {
      SharedPreferences locStor = await SharedPreferences.getInstance();
      locStor.setString('user', '');
      locStor.setString('token', '');
      var body = jsonDecode(res.body);
      if (body is Map) {
        if (body['message'].toString().contains('Failed host lookup')) {
          _changeConMethod(b: bldctx);
        }
      }
    }
    return res;
  }

  _fakecheck() async {
    print('tes fakecheck');
  }

  checkCon() async {
    log('Starting connection check...');
    print('halo bandung');
    await _fakecheck();
    await _getappver();
    String fullUrl = 'https://your.domainnamegoeshere.xyz';
    SharedPreferences locStor = await SharedPreferences.getInstance();
    if (locStor.getString('con_type') == '2') {
      fullUrl = 'https://app.koneksiehr.id/api';
    }
    await _getToken();
    var res = await http
        .get(Uri.parse(fullUrl), headers: _setHeaders())
        .onError((error, stackTrace) => http.Response(
            jsonEncode({'success': false, 'message': error.toString()}), 401))
        .timeout(Duration(seconds: _deftimout), onTimeout: () {
      Fluttertoast.showToast(msg: 'Request Timed Out');
      return http.Response(
          jsonEncode({'success': false, 'message': 'Request Timed Out'}), 401);
    });
    return res;
  }

  getData(apiUrl, {bldctx = null}) async {
    print('tes getdata');
    EasyLoading.show(status: 'Loading', maskType: EasyLoadingMaskType.black);
    await _connectionCheck();
    await _fakecheck();
    await _getappver();
    var fullUrl = _apiurl + apiUrl;
    await _getToken();
    var res = await http
        .get(Uri.parse(fullUrl), headers: _setHeaders())
        .onError((error, stackTrace) => http.Response(
            jsonEncode({'success': false, 'message': error.toString()}), 401))
        .timeout(Duration(seconds: _deftimout), onTimeout: () {
      Fluttertoast.showToast(msg: 'Request Timed Out');
      return http.Response(
          jsonEncode({'success': false, 'message': 'Request Timed Out'}), 408);
    });
    EasyLoading.dismiss();
    // log(res.statusCode.toString());
    if (res.statusCode == 408) {
      _changeConMethod(b: bldctx);
    } else if (res.statusCode == 401) {
      var body = jsonDecode(res.body);
      if (body is Map) {
        if (body['message'].toString().contains('Failed host lookup')) {
          _changeConMethod(b: bldctx);
        }
      }
    }
    return res;
  }

  _changeConMethod({b}) async {
    print('tes conmethod');
    SharedPreferences locStor = await SharedPreferences.getInstance();

    String? nw = locStor.getString('con_type');

    if (nw != null && nw == '1') {
      locStor.setString('con_type', '2');
    } else {
      locStor.setString('con_type', '1');
    }
    if (b != null && b is BuildContext) {
      AwesomeDialog(
        context: b,
        dialogType: DialogType.warning,
        title: 'PERINGATAN!',
        desc: 'Koneksi Terputus',
        btnCancel: null,
        btnOkOnPress: () {},
      ).show().then((value) => Get.offAll(() => LoginPage()));
    } else {
      Get.offAll(() => LoginPage());
    }
    // Get.offAll(LoginPage());
  }

  postData(apiUrl, data, {bldctx = null}) async {
    print('tes postdata');
    EasyLoading.show(status: 'Loading', maskType: EasyLoadingMaskType.black);
    await _connectionCheck();
    await _fakecheck();
    await _getappver();
    var fullUrl = _apiurl + apiUrl;
    await _getToken();
    var res = await http
        .post(Uri.parse(fullUrl), body: data, headers: _setHeaders())
        .onError((error, stackTrace) => http.Response(
            jsonEncode({'success': false, 'message': error.toString()}), 401))
        .timeout(Duration(seconds: _deftimout), onTimeout: () {
      Fluttertoast.showToast(msg: 'Request Timed Out');
      return http.Response(
          jsonEncode({'success': false, 'message': 'Request Timed Out'}), 408);
    });
    EasyLoading.dismiss();
    if (res.statusCode == 408) {
      _changeConMethod(b: bldctx);
    } else if (res.statusCode == 401) {
      var body = jsonDecode(res.body);
      if (body is Map) {
        if (body['message'].toString().contains('Failed host lookup')) {
          _changeConMethod(b: bldctx);
        }
      }
    }
    return res;
  }

  _setHeaders({String content_type = 'application/json'}) => {
        'Fltappver': _appver,
        'Deviceid': _devid,
        'Deviceinfo': _devinf,
        'Content-type': content_type,
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token'
      };
}
