import 'package:flutter/material.dart';

class TaxiFareUi extends StatefulWidget {
  const TaxiFareUi({super.key});

  @override
  State<TaxiFareUi> createState() => _TaxiFareUiState();
}

class _TaxiFareUiState extends State<TaxiFareUi> {
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _trafficController = TextEditingController();

  double _totalFare = 0.0;
  String? _errorMessage;

  @override
  void dispose() {
    _distanceController.dispose();
    _trafficController.dispose();
    super.dispose();
  }

  double _calculateTaxiFare(double distanceKm, double trafficMinutes) {
    double fare = 0.0;

    if (distanceKm > 0) {
      // กิโลเมตรแรก: 35 บาท
      fare += 35.0;

      // กิโลเมตรที่ 2-10: กิโลเมตรละ 6.50 บาท
      if (distanceKm > 1) {
        final double tier1 = (distanceKm.clamp(1.0, 10.0)) - 1.0;
        fare += tier1 * 6.50;
      }

      // กิโลเมตรที่ 10-20: กิโลเมตรละ 7.00 บาท
      if (distanceKm > 10) {
        final double tier2 = (distanceKm.clamp(10.0, 20.0)) - 10.0;
        fare += tier2 * 7.00;
      }

      // กิโลเมตรที่ 20-40: กิโลเมตรละ 8.00 บาท
      if (distanceKm > 20) {
        final double tier3 = (distanceKm.clamp(20.0, 40.0)) - 20.0;
        fare += tier3 * 8.00;
      }

      // กิโลเมตรที่ 40-60: กิโลเมตรละ 8.50 บาท
      if (distanceKm > 40) {
        final double tier4 = (distanceKm.clamp(40.0, 60.0)) - 40.0;
        fare += tier4 * 8.50;
      }

      // กิโลเมตรที่ 60-80: กิโลเมตรละ 9.00 บาท
      if (distanceKm > 60) {
        final double tier5 = (distanceKm.clamp(60.0, 80.0)) - 60.0;
        fare += tier5 * 9.00;
      }

      // ระยะทางเกิน 80 กม. ขึ้นไป: กิโลเมตรละ 10.50 บาท
      if (distanceKm > 80) {
        final double tier6 = distanceKm - 80.0;
        fare += tier6 * 10.50;
      }
    }

    // รถติด คิดนาทีละ 3.00 บาท
    fare += trafficMinutes * 3.00;

    return fare;
  }

  void _onCalculate() {
    final String distText = _distanceController.text.trim();
    final String timeText = _trafficController.text.trim();

    if (distText.isEmpty || timeText.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกข้อมูลให้ครบถ้วน';
      });
      return;
    }

    final double? distance = double.tryParse(distText);
    final double? traffic = double.tryParse(timeText);

    if (distance == null || traffic == null || distance < 0 || traffic < 0) {
      setState(() {
        _errorMessage = 'กรุณากรอกตัวเลขให้ถูกต้อง';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _totalFare = _calculateTaxiFare(distance, traffic);
    });
  }

  void _onReset() {
    _distanceController.clear();
    _trafficController.clear();
    setState(() {
      _errorMessage = null;
      _totalFare = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: const Text(
          'Taxi Fare',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                'assets/images/taxi.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'คำนวณค่าโดยสารแท็กซี่',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ระยะทาง (กิโลเมตร) 🛣️',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'กรุณากรอกระยะทาง',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'เวลารถติด (นาที) ⏰',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _trafficController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'กรุณากรอกเวลารถติด',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onCalculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'คำนวณค่าโดยสาร',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _onReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9E9E9E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2C6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'ค่าโดยสารแท็กซี่',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _totalFare.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'บาท',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFF44336),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}