import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:web_scraper/web_scraper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double externalHumidity = 0.0; // 외부 습도 (%)
  double internalHumidity = Random().nextDouble() * 100; // 내부 습도 (%)
  List<double> humidityData = [30.0, 40.0, 35.0, 45.0, 50.0, 55.0, 60.0];
  late Timer timer;
  bool isHumidifierOn = false;
  int a = Random().nextInt(2);

  @override
  void initState() {
    super.initState();
    _fetchExternalHumidity(); // 외부 습도 데이터를 가져오는 함수 호출
    // 2초마다 습도 업데이트를 위한 타이머 설정
    timer = Timer.periodic(Duration(seconds: 2), (Timer t) {
      setState(() {
        internalHumidity = Random().nextDouble() * 100; // 내부 습도 랜덤 업데이트
        // 내부 습도에 따라 humidityData 업데이트
        humidityData.add(internalHumidity);
        if (humidityData.length > 7) {
          humidityData.removeAt(0); // 최대 7개 데이터 유지
        }
      });
    });
  }

  @override
  void dispose() {
    timer.cancel(); // 타이머 해제
    super.dispose();
  }

  Future<void> _fetchExternalHumidity() async {
    final webScraper = WebScraper('https://m.search.naver.com');

    if (await webScraper.loadWebPage(
        '/search.naver?sm=mtp_hty.top&where=m&query=%EC%B2%9C%ED%98%B8%EB%8F%99+%EB%82%A0%EC%94%A8')) {
      List<Map<String, dynamic>> elements =
          webScraper.getElement('div.temperature_info > dl > div > dd', []);
      if (elements.isNotEmpty) {
        String humidityText = elements[0]['title'] ?? 'N/A';
        setState(() {
          externalHumidity =
              double.tryParse(humidityText.replaceAll('%', '').trim()) ?? 0.0;
          print('Humidity: $externalHumidity');
        });
      } else {
        print('Humidity element not found.');
      }
    } else {
      print('Failed to load webpage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.blueAccent,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('습도 정보'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: HumidifierStatus(isOn: a == 1),
              ),
              SizedBox(height: 30),
              _buildHumidityCard('외부 습도', externalHumidity),
              SizedBox(height: 20),
              _buildHumidityCardWithChart('현재 습도', internalHumidity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHumidityCard(String title, double humidity) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '${humidity.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHumidityCardWithChart(String title, double humidity) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '${humidity.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 2.0,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: humidityData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue, // Set line colors here
                      barWidth: 2,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        },
                        interval: 20,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.blueAccent, width: 1),
                  ),
                  minX: 0,
                  maxX: (humidityData.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HumidifierStatus extends StatelessWidget {
  final bool isOn;

  HumidifierStatus({required this.isOn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: isOn ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOn ? Icons.check_circle : Icons.cancel,
            color: isOn ? Colors.green : Colors.red,
            size: 24,
          ),
          SizedBox(width: 10),
          Text(
            isOn ? 'Humidifier ON' : 'Humidifier OFF',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isOn ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
