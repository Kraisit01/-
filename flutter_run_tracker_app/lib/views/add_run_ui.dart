import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddRunUi extends StatefulWidget {
  const AddRunUi({super.key});

  @override
  State<AddRunUi> createState() => _AddRunUiState();
}

class _AddRunUiState extends State<AddRunUi> {
  final _formKey = GlobalKey<FormState>();
  final _whereCtrl = TextEditingController();
  final _personCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  XFile? _pickedFile;
  Uint8List? _imageBytes;
  bool _isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 75);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedFile = picked;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เลือกรูปไม่ได้บนอุปกรณ์นี้: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _whereCtrl.clear();
    _personCtrl.clear();
    _distanceCtrl.clear();
    setState(() {
      _pickedFile = null;
      _imageBytes = null;
    });
  }

  Future<void> _saveRun() async {
    if (!_formKey.currentState!.validate()) return;
    final distance = int.tryParse(_distanceCtrl.text.trim());
    if (distance == null) return;

    setState(() => _isSaving = true);
    try {
      String? imageUrl;
      if (_pickedFile != null && _imageBytes != null) {
        final fileName = 'run_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('run_bk').uploadBinary(
              fileName,
              _imageBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        imageUrl = _supabase.storage.from('run_bk').getPublicUrl(fileName);
      }

      await _supabase.from('run_tb').insert({
        'runWhere': _whereCtrl.text.trim(),
        'runPerson': _personCtrl.text.trim(),
        'runDistance': distance,
        'runImageUrl': imageUrl,
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _whereCtrl.dispose();
    _personCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A144A),
        foregroundColor: Colors.white,
        title: const Text('Run Tracker (เพิ่ม)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('ถ่ายรูป'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('เลือกรูปจากเครื่อง'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 44, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('แตะเพื่อถ่ายรูปหรือเลือกรูป'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whereCtrl,
                decoration: const InputDecoration(
                  labelText: 'วิ่งที่ไหน',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'กรุณากรอกสถานที่วิ่ง' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _personCtrl,
                decoration: const InputDecoration(
                  labelText: 'วิ่งกับใคร',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'กรุณากรอกข้อมูลคนวิ่ง' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _distanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ระยะทาง (กม.)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'กรุณากรอกระยะทาง';
                  if (int.tryParse(v.trim()) == null) return 'กรอกเฉพาะตัวเลข';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSaving ? null : _saveRun,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('บันทึกการวิ่ง'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSaving ? null : _clearForm,
                  child: const Text('ยกเลิก'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}