import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateDeleteRunUi extends StatefulWidget {
  final Map<String, dynamic> runData;
  const UpdateDeleteRunUi({super.key, required this.runData});

  @override
  State<UpdateDeleteRunUi> createState() => _UpdateDeleteRunUiState();
}

class _UpdateDeleteRunUiState extends State<UpdateDeleteRunUi> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _whereCtrl;
  late final TextEditingController _personCtrl;
  late final TextEditingController _distanceCtrl;
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  Uint8List? _newImageBytes;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _whereCtrl = TextEditingController(text: widget.runData['runWhere']?.toString() ?? '');
    _personCtrl = TextEditingController(text: widget.runData['runPerson']?.toString() ?? '');
    _distanceCtrl = TextEditingController(text: widget.runData['runDistance']?.toString() ?? '');
  }

  String? _extractStoragePath(String? url) {
    if (url == null || url.isEmpty) return null;
    final marker = '/object/public/run_bk/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    return url.substring(idx + marker.length).split('?').first;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 75);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() => _newImageBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เลือกรูปไม่ได้บนอุปกรณ์นี้: $e')),
        );
      }
    }
  }

  Future<void> _updateRun() async {
    if (!_formKey.currentState!.validate()) return;
    final distance = int.tryParse(_distanceCtrl.text.trim());
    if (distance == null) return;

    setState(() => _isBusy = true);
    try {
      String? imageUrl = widget.runData['runImageUrl'] as String?;

      if (_newImageBytes != null) {
        final oldPath = _extractStoragePath(imageUrl);
        if (oldPath != null) {
          await _supabase.storage.from('run_bk').remove([oldPath]);
        }
        final fileName = 'run_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('run_bk').uploadBinary(
              fileName,
              _newImageBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        imageUrl = _supabase.storage.from('run_bk').getPublicUrl(fileName);
      }

      await _supabase.from('run_tb').update({
        'runWhere': _whereCtrl.text.trim(),
        'runPerson': _personCtrl.text.trim(),
        'runDistance': distance,
        'runImageUrl': imageUrl,
      }).eq('id', widget.runData['id']);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('แก้ไขไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteRun() async {
    setState(() => _isBusy = true);
    try {
      final oldPath = _extractStoragePath(widget.runData['runImageUrl'] as String?);
      if (oldPath != null) {
        await _supabase.storage.from('run_bk').remove([oldPath]);
      }

      await _supabase.from('run_tb').delete().eq('id', widget.runData['id']);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
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
    final existingUrl = widget.runData['runImageUrl'] as String?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A144A),
        foregroundColor: Colors.white,
        title: const Text('Run Tracker (แก้ไข/ลบ)'),
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
                          title: const Text('ถ่ายรูปใหม่'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('เลือกรูปใหม่จากเครื่อง'),
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
                  child: _newImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_newImageBytes!, fit: BoxFit.cover),
                        )
                      : (existingUrl != null && existingUrl.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(existingUrl, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.add_a_photo, size: 44, color: Colors.grey),
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
                  onPressed: _isBusy ? null : _updateRun,
                  child: const Text('บันทึกการแก้ไข'),
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
                  onPressed: _isBusy ? null : _deleteRun,
                  child: const Text('ลบข้อมูล'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}