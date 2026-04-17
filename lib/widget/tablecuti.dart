import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ehr_report/api/api.dart';

class Tablecuti extends StatefulWidget {
  final String pegawaiId;
  const Tablecuti({Key? key, required this.pegawaiId}) : super(key: key);

  @override
  State<Tablecuti> createState() => _TablecutiState();
}

class _TablecutiState extends State<Tablecuti> {
  bool isLoading = true;
  List<Map<String, dynamic>> dataCuti = [];
  int currentPage = 0;
  final int itemsPerPage = 4;

  @override
  void initState() {
    super.initState();
    fetchtabelcuti();
  }

  Future<void> fetchtabelcuti() async {
  debugPrint('fetchWidgetkpi() dipanggil dengan pegawaiId: ${widget.pegawaiId}');
  String apiUrl = '/detailcutireport/${widget.pegawaiId}';

  try {
    debugPrint('Mengirim request ke API: $apiUrl');

    var response = await ApiHandler().getData(apiUrl).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Request timeout');
      },
    );

    debugPrint('API Response Status Code: ${response.statusCode}');
    debugPrint('API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data_cuti')) {
        var dataList = jsonResponse['data_cuti'];

        if (dataList is List) {
          setState(() {
            dataCuti = List<Map<String, dynamic>>.from(dataList);
            isLoading = false;
          });

          debugPrint('Data Cuti: $dataCuti');
          return;
        }
      } else {
        debugPrint('Format response tidak sesuai yang diharapkan: $jsonResponse');
      }
    } else {
      debugPrint('Request gagal dengan status code: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error saat fetch data cuti: $e');
  }

  setState(() {
    isLoading = false;
  });
}
String formatTanggal(String? tanggal) {
  if (tanggal == null || tanggal.isEmpty) return 'N/A';
  try {
    DateTime date = DateTime.parse(tanggal);
    return DateFormat("d MMMM yyyy", "id_ID").format(date);
  } catch (e) {
    return 'Invalid Date';
  }
}



@override
Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.all(8),
    child: isLoading
        ? Center(child: CircularProgressIndicator())
        : dataCuti.isEmpty
            ? Center(child: Text('Tidak ada data cuti'))
            : SizedBox(
                height: MediaQuery.of(context).size.height * 0.5, // Batasi tinggi maksimal
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: AlwaysScrollableScrollPhysics(), // Tambahkan scrolling
                  itemCount: dataCuti.length,
                  itemBuilder: (context, index) {
                    var cuti = dataCuti[index];
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cuti['nama_cuti'] ?? 'N/A',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                                SizedBox(width: 5),
                                Text(
                                  "Mulai: ${formatTanggal(cuti['tgl_mulai'])}",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.event, size: 16, color: Colors.red),
                                SizedBox(width: 5),
                                Text(
                                  "Selesai: ${formatTanggal(cuti['tgl_selesai'])}",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Keterangan: ${cuti['keterangan'] ?? 'N/A'}",
                              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Status: ${cuti['status_cuti'] == null ? 'N/A' : (cuti['status_cuti'] == 1 ? 'Diterima' : 'Belum Diterima')}",
                              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                            ),

                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
  );
}
}
//   @override
// Widget build(BuildContext context) {
//   return Container(
//     padding: EdgeInsets.all(8),
//     child: isLoading
//         ? Center(child: CircularProgressIndicator())
//         : dataCuti.isEmpty
//             ? Center(child: Text('Tidak ada data cuti'))
//             : SizedBox(
//                 height: MediaQuery.of(context).size.height * 0.5, // Maksimal 50% dari tinggi layar
//                 child: SingleChildScrollView(
//                   scrollDirection: Axis.vertical, // Scroll vertikal
//                   child: SingleChildScrollView(
//                     scrollDirection: Axis.horizontal, // Scroll horizontal
//                     child: DataTable(
//                       columnSpacing: 12,
//                       headingRowColor:
//                           MaterialStateColor.resolveWith((states) => Colors.blueGrey.shade800),
//                       columns: const [
//                         DataColumn(
//                             label: Text('Jenis Cuti', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
//                         DataColumn(
//                             label: Text('Tanggal Mulai', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
//                         DataColumn(
//                             label: Text('Tanggal Selesai', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
//                         DataColumn(
//                             label: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
//                       ],
//                       rows: dataCuti
//                           .map(
//                             (cuti) => DataRow(cells: [
//                               DataCell(Text(cuti['nama_cuti'] ?? 'N/A')),
//                               DataCell(Text(formatTanggal(cuti['tgl_mulai']))), // Format tanggal
//                               DataCell(Text(formatTanggal(cuti['tgl_selesai']))), // Format tanggal
//                               DataCell(Text(cuti['keterangan'] ?? 'N/A')),
//                             ]),
//                           )
//                           .toList(),
//                     ),
//                   ),
//                 ),
//               ),
//   );
// }