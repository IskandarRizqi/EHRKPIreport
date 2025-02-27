import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:kpi/api/api.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({required this.prevPage, super.key});
  final String prevPage;

  @override
  _AbsensiPageState createState() => _AbsensiPageState();
}

class AbsensiData {
  final String pegawai_id;
  final String nama;
  final String jabatan;
  final String profil;
  final String usia;
  final String nip;
  final String cabang;

  AbsensiData({
    required this.pegawai_id,
    required this.nama,
    required this.jabatan,
    required this.profil,
    required this.usia,
    required this.nip,
    required this.cabang,
  });

  factory AbsensiData.fromJson(Map<String, dynamic> json) {
    return AbsensiData(
      pegawai_id: json['pegawai_id'] ?? '',
      nama: json['nama'] ?? '',
      jabatan: json['jabatan'] ?? '',
      profil: json['profil'] ?? '',
      usia: json['usia'] != null ? json['usia'].toString() : '0',
      nip: json['nip'] != null ? json['nip'].toString() : '',
      cabang: json['cabang'] ?? '',
    );
  }
}

class _AbsensiPageState extends State<AbsensiPage> {
  List<AbsensiData> absensiDataList = []; // Variabel untuk menyimpan data
  bool isLoading = true;
  String search = "";
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    fetchAbsensiData(); // Panggil fungsi untuk mengambil data saat inisialisasi
  }

  Future<void> fetchAbsensiData({String? query}) async {
    try {
      setState(() {
        isLoading = true; // Set loading true saat mulai mengambil data
      });

      var url = '/absensireport';
      if (query != null && query.isNotEmpty) {
        url += '?search=$query';
      }
      var dat = await ApiHandler().getData(url);
      debugPrint('API Response Status Code: ${dat.statusCode}');
      debugPrint('API Response Body: ${dat.body}');
      if (dat.statusCode == 200 && dat.body != null) {
        final Map<String, dynamic> jsonResponse = jsonDecode(dat.body);
        
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          final List<dynamic> data = jsonResponse['data'];
          List<AbsensiData> tempList = 
              data.map((item) => AbsensiData.fromJson(item)).toList();

          setState(() {
            absensiDataList = tempList; // Simpan data ke variabel
            isLoading = false; // Set loading false setelah data didapat
          });
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to fetch data. Status code: ${dat.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Set loading false jika ada error
      });
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchAbsensiData(query: value);
    });

    setState(() {
      search = value;
    });
  }
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Absen',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color(0xFF007BFF),
        centerTitle: true,
        elevation: 0,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.search, color: Colors.white),
          //   onPressed: () {},
          // ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  onChanged: _onSearchChanged, // Panggil otomatis saat mengetik
                  decoration: InputDecoration(
                    labelText: "Search berdasarkan nama",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    suffixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 700,
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : absensiDataList.isEmpty
                        ? Center(child: Text('No data found.'))
                        : ListView.builder(
                            itemCount: absensiDataList.length,
                            itemBuilder: (context, index) {
                              final absensi = absensiDataList[index];
                              return AbsensiCard(absensi: absensi);
                            },
                          ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  //   child: Text(
                  //     'Presentase Absensi',
                  //     style: TextStyle(
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.bold,
                  //       color: Colors.black,
                  //     ),
                  //   ),
                  // ),
                  SizedBox(height: 50),
                  // SizedBox(
                  //   height: 200,
                  //   child: AttendanceChart(),
                  // ),
                  // SizedBox(height: 16),
                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       LegendIndicator(color: Colors.green, text: 'Hadir'),
                  //       SizedBox(width: 16),
                  //       LegendIndicator(color: Colors.yellow, text: 'Terlambat'),
                  //       SizedBox(width: 16),
                  //       LegendIndicator(color: Colors.red, text: 'Tidak Hadir'),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AbsensiCard extends StatelessWidget {
  final AbsensiData absensi;

  const AbsensiCard({Key? key, required this.absensi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  // Get.to(()=> AbsensiDetailPage(absensiData:absensi));
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AbsensiDetailPage(pegawaiId: absensi.pegawai_id),
                    ),
                  );
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(30),
                        image: DecorationImage(
                          image: absensi.profil.isNotEmpty &&
                                  Uri.tryParse(absensi.profil)?.hasAbsolutePath ==
                                      true
                              ? NetworkImage(absensi.profil)
                              : AssetImage('assets/images/defaultimg.jpg')
                                  as ImageProvider,
                                  fit: BoxFit.cover
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            absensi.nama,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            absensi.jabatan,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'NIP: ${absensi.nip}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Kantor: ${absensi.cabang}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceSearchDelegate extends SearchDelegate<String> {
  final List<AbsensiData> absensi;

  AttendanceSearchDelegate(this.absensi);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = absensi
        .where((absensi) =>
            absensi.nama.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index].nama),
          onTap: () {
            close(context, results[index].nama);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = absensi
        .where((absensi) =>
            absensi.nama.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index].nama),
          onTap: () {
            query = suggestions[index].nama;
            showResults(context);
          },
        );
      },
    );
  }
}

// Attendance Chart class
// class AttendanceChart extends StatelessWidget {
//   final List<AttendanceData> attendanceData = [
//     AttendanceData('Jan', 22, 5, 3),
//     AttendanceData('Feb', 23, 1, 2),
//     AttendanceData('Mar', 24, 1, 1),
//     AttendanceData('Apr', 21, 3, 4),
//     AttendanceData('Mei', 23, 4, 2),
//     AttendanceData('Juni', 21, 3, 4),
//     AttendanceData('Juli', 22, 1, 3),
//     AttendanceData('Agst', 25, 3, 0),
//     AttendanceData('Sept', 21, 3, 4),
//     AttendanceData('Okt', 24, 5, 1),
//     AttendanceData('Nov', 20, 3, 5),
//     AttendanceData('Des', 24, 1, 1),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return BarChart(
//       BarChartData(
//         alignment: BarChartAlignment.spaceAround,
//         maxY: 25,
//         barTouchData: BarTouchData(enabled: false),
//         titlesData: FlTitlesData(
//           leftTitles: SideTitles(
//             showTitles: true,
//             getTextStyles: (value) => const TextStyle(
//               color: Colors.black,
//               fontSize: 12,
//             ),
//             margin: 6,
//           ),
//           bottomTitles: SideTitles(
//             showTitles: true,
//             getTextStyles: (value) => const TextStyle(
//               color: Colors.black,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//             getTitles: (double value) {
//               return attendanceData[value.toInt()].month;
//             },
//             margin: 8,
//           ),
//         ),
//         gridData: FlGridData(show: true),
//         borderData: FlBorderData(
//           show: false,
//         ),
//         barGroups: attendanceData
//             .asMap()
//             .entries
//             .map(
//               (entry) => BarChartGroupData(
//                 x: entry.key,
//                 barRods: [
//                   BarChartRodData(
//                     y: entry.value.attended.toDouble(),
//                     colors: [Colors.green],
//                   ),
//                   BarChartRodData(
//                     y: entry.value.late.toDouble(),
//                     colors: [Colors.yellow],
//                   ),
//                   BarChartRodData(
//                     y: entry.value.absent.toDouble(),
//                     colors: [Colors.red],
//                   ),
//                 ],
//                 showingTooltipIndicators: [0],
//               ),
//             )
//             .toList(),
//       ),
//     );
//   }
// }

class AttendanceData {
  final String month;
  final int attended;
  final int late;
  final int absent;

  AttendanceData(this.month, this.attended, this.late, this.absent);
}

class LegendIndicator extends StatelessWidget {
  final Color color;
  final String text;

  const LegendIndicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
class DetailAbsensiData {
  final String nama;
  final String jabatan_pegawai;
  final String nip;
  final int usia;
  final String kantor_cabang_pegawai;
  final String avatar;

  DetailAbsensiData({
    required this.nama,
    required this.jabatan_pegawai,
    required this.nip,
    required this.usia,
    required this.kantor_cabang_pegawai,
    required this.avatar,
  });

  factory DetailAbsensiData.fromJson(Map<String, dynamic> json) {
    return DetailAbsensiData(
      nama: json['nama'],
      jabatan_pegawai: json['jabatan'],
      nip: json['nip'],
      usia: json['usia'],
      kantor_cabang_pegawai: json['cabang'],
      avatar: json['avatar'],
    );
  }
}

class AbsensiBulanData {
  final String bulanTahun;
  final int total;

  AbsensiBulanData({
    required this.bulanTahun,
    required this.total,
  });

  factory AbsensiBulanData.fromJson(Map<String, dynamic> json) {
    return AbsensiBulanData(
      bulanTahun: json['bulan_tahun'],
      total: json['total'],
    );
  }
}

class AbsensiDetailPage extends StatefulWidget {
  final String pegawaiId;
  //  final AbsensiData absensiData;
  const AbsensiDetailPage({required this.pegawaiId, Key? key}) : super(key: key);
  @override
  _AbsensiDetailPageState createState() => _AbsensiDetailPageState();
}
class _AbsensiDetailPageState extends State<AbsensiDetailPage> {
  DetailAbsensiData? detailAbsensiData;
  List<AbsensiBulanData> absensiBulanData = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchDetailAbsensi();
  }
  Future<void> fetchDetailAbsensi() async {
  String apiUrl = '/detailabsensireport/${widget.pegawaiId}';

  try {
    var response = await ApiHandler().getData(apiUrl);
    debugPrint('API Response Status Code: ${response.statusCode}');
    debugPrint('API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse is List && jsonResponse.isNotEmpty) {
        // Mengambil data detail pegawai dari item pertama
        var detailData = jsonResponse[0];
        setState(() {
          // Parsing data pegawai
          detailAbsensiData = DetailAbsensiData.fromJson(detailData);
          
          // Mengambil data absensi per bulan (selain item pertama)
          absensiBulanData = jsonResponse
              .map<AbsensiBulanData>((item) => AbsensiBulanData.fromJson(item))
              .toList();

          isLoading = false;
        });
      } else {
        debugPrint('Data tidak valid');
        setState(() => isLoading = false);
      }
    } else {
      debugPrint('Gagal mengambil data Absensi detail');
      setState(() => isLoading = false);
    }
  } catch (e) {
    debugPrint('Error: $e');
    setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Absensi',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Color(0xFF007BFF),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee details
            Card(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(30),
                          image: DecorationImage(
                            image: (detailAbsensiData?.avatar ?? '').isNotEmpty &&
                              Uri.tryParse(detailAbsensiData?.avatar ?? '')?.hasAbsolutePath == true
                          ? NetworkImage(detailAbsensiData!.avatar) // Gunakan ! karena sudah dicek null-nya
                          : const AssetImage('assets/images/profile.jpeg') as ImageProvider,
                          fit: BoxFit.cover
                          ),
                        ),
                      ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${detailAbsensiData?.nama}',
                        style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${detailAbsensiData?.jabatan_pegawai}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF007BFF),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'NIP: ${detailAbsensiData?.nip}',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Usia : ${detailAbsensiData?.usia} Tahun',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Kantor : ${detailAbsensiData?.kantor_cabang_pegawai}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      // Row(
                      //   children: [
                      //     Text(
                      //       'INDEX RATA-RATA KPI 4.0',
                      //       style: TextStyle(
                      //         fontWeight: FontWeight.bold,
                      //         color: Color(0xFF007BFF),
                      //       ),
                      //     ),
                      //     SizedBox(width: 8),
                      //     Row(
                      //       children: [
                      //         Icon(Icons.star,
                      //             color: Colors.amber,
                      //             size: 15), // Changed to gold
                      //         Icon(Icons.star,
                      //             color: Colors.amber,
                      //             size: 15), // Changed to gold
                      //         Icon(Icons.star,
                      //             color: Colors.amber,
                      //             size: 15), // Changed to gold
                      //         Icon(Icons.star,
                      //             color: Colors.amber,
                      //             size: 15), // Changed to gold
                      //         Icon(Icons.star_border,
                      //             color: Colors.amber,
                      //             size: 15), // Changed to golds.star,
                      //       ],
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            if (absensiBulanData != null && absensiBulanData!.isNotEmpty)
  Expanded(
    child: Table(
      border: TableBorder.all(color: Colors.grey), // Adds borders to the table
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(2), // Width for the month column
        1: FlexColumnWidth(1), // Width for the hadir (attendance) column
        // 2: FlexColumnWidth(1), // Width for the cuti (leave) column
      },
      children: [
        _buildTableHeaderRow(), // Table header
        ...absensiBulanData!.map((data) => _buildTableRow(data)).toList(), // Map each data to table rows
      ],
    ),
  ),
            // Add spacing before attendance section
            // _buildAttendanceTable()
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(AbsensiBulanData data) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          data.bulanTahun, // Display the month
          style: TextStyle(fontSize: 14, color: Colors.black),
          textAlign: TextAlign.center,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          '${data.total} h', // Display the attendance total
          style: TextStyle(fontSize: 14, color: Colors.black),
          textAlign: TextAlign.center,
        ),
      ),
      // Padding(
      //   padding: const EdgeInsets.all(8.0),
      //   child: Text(
      //     '0 h', // Placeholder for "Cuti" (Leave), replace with actual data if available
      //     style: TextStyle(fontSize: 14, color: Colors.black),
      //     textAlign: TextAlign.center,
      //   ),
      // ),
    ],
  );
}

  // Helper method to build attendance rows
  // Widget _buildAttendanceTable() {
  //   return Table(
  //     border: TableBorder.all(color: Colors.grey), // Adds borders to the table
  //     columnWidths: const <int, TableColumnWidth>{
  //       0: FlexColumnWidth(2), // Width for the month column
  //       1: FlexColumnWidth(1), // Width for the hadir (attendance) column
  //       2: FlexColumnWidth(1), // Width for the cuti (leave) column
  //     },
  //     children: [
  //       _buildTableHeaderRow(), // Table header
  //       _buildTableRow('Januari', '23 h', '2 h'), // Data for January
  //       _buildTableRow('Februari', '23 h', '2 h'), // Data for February
  //       _buildTableRow('Maret', '23 h', '2 h'), // Data for March
  //       // Add more rows as needed
  //     ],
  //   );
  // }

  // Helper method to build the table header
  TableRow _buildTableHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(
        color:  Colors.blue[50], // Blue background for header
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10), // Rounded top corners
          topRight: Radius.circular(10),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Bulan', // Month
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Hadir', // Attendance
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: Text(
        //     'Cuti', // Leave
        //     style: TextStyle(
        //         fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
        //     textAlign: TextAlign.center,
        //   ),
        // ),
      ],
    );
  }

  // Helper method to build a table row for attendance data
  // TableRow _buildTableRow(String month, String hadir, String cuti) {
  //   return TableRow(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: month == 'Maret' // Apply rounded corners to last row
  //           ? BorderRadius.only(
  //               bottomLeft: Radius.circular(10), // Rounded bottom corners
  //               bottomRight: Radius.circular(10),
  //             )
  //           : BorderRadius.zero,
  //     ),
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.all(8.0),
  //         child: Text(
  //           month,
  //           style: TextStyle(fontSize: 16),
  //           textAlign: TextAlign.center,
  //         ),
  //       ),
  //       Padding(
  //         padding: const EdgeInsets.all(8.0),
  //         child: Text(
  //           hadir,
  //           style: TextStyle(fontSize: 16),
  //           textAlign: TextAlign.center,
  //         ),
  //       ),
  //       Padding(
  //         padding: const EdgeInsets.all(8.0),
  //         child: Text(
  //           cuti,
  //           style: TextStyle(fontSize: 16),
  //           textAlign: TextAlign.center,
  //         ),
  //       ),
  //     ],
  //   );
  // }
}

class Group56 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.all(8.0), // Adds padding around the whole container
      child: Container(
        width: 342,
        height: 251,
        decoration: BoxDecoration(
          color: Colors.white, // Background color for the whole container
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Color(0xFFCCCCCC), width: 1),
          boxShadow: [
            // Adds a shadow for a 3D effect
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Container
            _buildHeaderContainer(),
            // Header Texts
            _buildHeaderRow(),
            // Static Data Rows
            Expanded(child: _buildDataRows()),
          ],
        ),
      ),
    );
  }

  // Method to build header container
  // Method to build header container
  Container _buildHeaderContainer() {
    return Container(
      width: 340,
      height: 37,
      decoration: BoxDecoration(
        color: Color(0xFFCCCCCC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(bottom: BorderSide(width: 1, color: Color(0xFFCCCCCC))),
      ),
      child: Center(
        // Center the text within the container
        child: Text(
          'Kehadiran', // Text to display
          style: TextStyle(
            color: Colors.black, // Text color
            fontSize: 13, // Font size
            fontFamily: 'Poppins', // Font family
            fontWeight: FontWeight.w500, // Font weight
          ),
        ),
      ),
    );
  }

  // Method to build header row
  Row _buildHeaderRow() {
    List<String> headers = [
      'Kd',
      'Cabang',
      'H',
      'T',
      'T H',
      'PA',
      'P',
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: headers.map((header) => _buildHeaderText(header)).toList(),
    );
  }

  // Method to build header text
  // Method to build header text
  Widget _buildHeaderText(String text) {
    return SizedBox(
      width: 45,
      height: 18,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center, // Center the text
      ),
    );
  }

  // Method to build the data rows
  Widget _buildDataRows() {
    List<List<String>> dataRows = [
      ['1.1', 'Semarang', '20', '3', '5', '-', '2'],
      ['1.2', 'Pekalongan', '22', '1', '3', '2', '1'],
      ['1.3', 'Tegal', '21', '1', '4', '3', '1'],
      ['1.4', 'Boyolali', '24', '-', '1', '2', '2'],
      ['1.5', 'Temanggung', '24', '3', '1', '1', '3'],
      ['1.6', 'Jepara', '21', '2', '4', '1', '-'],
      ['1.7', 'Klaten', '22', '1', '3', '-', '2'],
    ];

    return ListView.builder(
      itemCount: dataRows.length,
      itemBuilder: (context, index) {
        return _buildRow(dataRows[index]);
      },
    );
  }

  // Method to build a row of data
  Widget _buildRow(List<String> values) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(width: 1, color: Colors.grey.withOpacity(0.5))),
      ),
      child: Row(
        children: values.map((value) => _buildCell(value)).toList(),
      ),
    );
  }

  // Method to build individual cell
  Widget _buildCell(String value) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
            vertical: 10), // Increased padding for better spacing
        child: Text(
          value,
          maxLines: 1, // Limit to one line
          overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            color: Colors.black, // Ensure text is readable
          ),
        ),
      ),
    );
  }
}