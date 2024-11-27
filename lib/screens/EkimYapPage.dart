import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EkimYapPage extends StatefulWidget {
  const EkimYapPage({Key? key}) : super(key: key);

  @override
  _EkimYapPageState createState() => _EkimYapPageState();
}

class _EkimYapPageState extends State<EkimYapPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _plantingAmountController = TextEditingController();
  final TextEditingController _landIdController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    final url = Uri.parse('http://10.0.2.2:8080/api/sowings');
    final body = json.encode({
      "landId": int.parse(_landIdController.text),
      "plantingAmount": int.parse(_plantingAmountController.text),
      "sowingDate": _selectedDate?.toIso8601String(),
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print('HTTP Status Code: ${response.statusCode}'); // HTTP durum kodunu yazdırır

      if (response.statusCode == 201) {
        _showSnackbar('Ekim başarıyla kaydedildi!', Colors.green);
      } else {
        _showSnackbar('Hata oluştu! HTTP Durum Kodu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      print('Hata: $e'); // Hatanın detaylarını konsola yazdırır
      _showSnackbar('Bir hata oluştu: $e', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekim Yap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _landIdController,
                decoration: const InputDecoration(
                  labelText: 'Arazi ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen Arazi ID giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plantingAmountController,
                decoration: const InputDecoration(
                  labelText: 'Ekim Miktarı',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen ekim miktarını giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate == null
                        ? 'Tarih Seçilmedi'
                        : 'Seçilen Tarih: ${_selectedDate!.toLocal()}'.split(' ')[0],
                  ),
                  ElevatedButton(
                    onPressed: () => _pickDate(context),
                    child: const Text('Tarih Seç'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Ekim Yap'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
