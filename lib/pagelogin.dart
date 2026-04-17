import 'dart:convert';
import 'dart:developer';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ehr_report/api/api.dart';
import 'package:ehr_report/halamanutama.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  int _constat = 1; // Misalnya, 1 berarti koneksi tersedia
  String _errorMessage = '';
  bool _isObscure = true;
  String _appVer = '0';
  @override
  void initState() {
    super.initState();
    _chekAuth();
    _getAppVersion();
  }
  Future<void> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVer = packageInfo.version;
    });
  }
  

  // Fungsi login
  void _login() async {
    print('mulai login');
    if (_constat == 0) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.infoReverse,
        headerAnimationLoop: false,
        animType: AnimType.bottomSlide,
        title: 'INFO',
        desc: 'Login hanya bisa dilakukan saat indikator koneksi berwarna hijau',
      ).show();
    } else if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });

      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        Fluttertoast.showToast(msg: "Email dan password tidak boleh kosong.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      var data = {'email': email, 'password': password, 'device': 'Mobile EHR'};
      var res = await ApiHandler().authData(data, '/login');
      var body = jsonDecode(res.body);

      if (res.statusCode == 200 && body['success']) {
        SharedPreferences locStor = await SharedPreferences.getInstance();
        locStor.setString('token', jsonEncode(body['token']));
        locStor.setString('user', jsonEncode(body['user']));
        log("Token disimpan: ${body['token']}");

        String? infmsg = body['infomessage']?.toString();
        String? alrmsg = body['alertmessage']?.toString();

        Get.off(() => HomeScreen(
              prevPage: '',
              infoPop: infmsg,
              alertPop: alrmsg,
            ));
      } else {
        String m = body['message'].toString();
        if (m.toLowerCase().contains('server error') ||
            m.toLowerCase().contains('timed out')) {
          m = 'Koneksi Bermasalah';
        }
        AwesomeDialog(
          context: context,
          dialogType: DialogType.infoReverse,
          headerAnimationLoop: false,
          animType: AnimType.bottomSlide,
          title: 'INFO',
          desc: m,
        ).show();
        setState(() {
          _errorMessage = m;
        });
      }

      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background dengan bentuk lengkung
          ClipPath(
            clipper: BackgroundClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              color: const Color(0xFF007BFF),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                    ),
                    const SizedBox(height: 20),

                    // Gambar ilustrasi login
                    Image.asset(
                      'assets/images/fotologin.png',
                      width: 250,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 70),

                    // Form Login
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Login',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person),
                                labelText: 'Email',
                                hintText: 'Example@ehr.co.id',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            TextField(
                              controller: passwordController,
                              obscureText: _isObscure,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscure = !_isObscure;
                                    });
                                  },
                                ),
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Tombol Login
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF007BFF),
                                minimumSize: const Size(200, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'Login',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Versi aplikasi
                    Text(
                      'EHR Report V$_appVer',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _chekAuth() async {
  setState(() {
    _isLoading = true;
  });

  SharedPreferences locStor = await SharedPreferences.getInstance();
  String? token = locStor.getString('token');
  print("Token saat startup: $token");

  if (token == null || token.isEmpty) {
    print("Token kosong, harus login ulang.");
    setState(() {
      _isLoading = false;
    });
    return;
  }

  print("Memulai authCheck...");
  var res = await ApiHandler().authCheck();
  print("Response dari authCheck: ${res.body}");

  if (res.statusCode == 200) {
    var body = jsonDecode(res.body);
    if (body['success']) {
      locStor.setString('user', jsonEncode(body['user']));
      print("Autentikasi berhasil, masuk ke HomeScreen...");
      Get.off(() => HomeScreen(
        prevPage: '',
        // infoPop: body['infomessage']?.toString(),
        alertPop: body['alertmessage']?.toString(),
      ));
      return;
    } else {
      print("authCheck gagal: ${body['message']}");
    }
  } else {
    print("authCheck gagal, status code: ${res.statusCode}");
  }

  print("Login manual diperlukan.");
  _login();

  setState(() {
    _isLoading = false;
  });
}

  }






// Custom clipper for the curved background shape
class BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 100);
    var firstControlPoint = Offset(size.width / 2, size.height);
    var firstEndPoint = Offset(size.width, size.height - 100);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
  
}
