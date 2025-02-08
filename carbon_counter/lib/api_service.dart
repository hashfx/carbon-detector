import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carbon_counter/data_model.dart';

class ApiService {
  final String _scriptUrl;

  ApiService(this._scriptUrl);

  Future<List<CarbonData>> getCarbonData() async {
    final response = await http.get(Uri.parse(_scriptUrl));

    if (response.statusCode == 200) {
      // { "data": [ ["time1", "mq7_1", "mq135_1"], ["time2", "mq7_2", "mq135_2"], ...] }

      final decodedData = json.decode(response.body);

      // Check if 'data' key exists and if it's a List
      if (decodedData is Map &&
          decodedData.containsKey('data') &&
          decodedData['data'] is List) {
        final sheetData = decodedData['data'];

        return sheetData.map<CarbonData>((row) {
          if (row is List && row.length == 3) {
            return CarbonData(
              time: row[0].toString(),
              mq7: double.tryParse(row[1].toString()) ?? 0.0,
              mq135: double.tryParse(row[2].toString()) ?? 0.0,
            );
          } else {
            // Handle rows that don't match the expected format
            print("Invalid row format: $row");
            return CarbonData(
              time: '',
              mq7: 0.0,
              mq135: 0.0,
            ); // Or some other default
          }
        }).toList();
      } else {
        // Handle cases where the response format is not as expected
        print("Invalid response format: $decodedData");
        return []; // Return an empty list or handle the error as needed
      }
    } else {
      throw Exception(
        'Failed to load data. Status code: ${response.statusCode}',
      );
    }
  }
}
