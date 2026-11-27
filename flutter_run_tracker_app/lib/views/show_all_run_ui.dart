import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_run_ui.dart';
import 'update_delete_run_ui.dart';

class ShowAllRunUi extends StatefulWidget {
  const ShowAllRunUi({super.key});

  @override
  State<ShowAllRunUi> createState() => _ShowAllRunUiState();
}

class _ShowAllRunUiState extends State<ShowAllRunUi> {
  final supabase = Supabase.instance.client;
  List<dynamic> runs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRuns();
  }

  Future<void> fetchRuns() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('run_tb')
          .select()
          .order('created_at', ascending: false);
      setState(() {
       runs = List<dynamic>.from(data);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A144A),
        foregroundColor: Colors.white,
        title: const Text('Run Tracker'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : runs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_run, size: 72, color: Colors.indigo),
                      SizedBox(height: 12),
                      Text(
                        'วิ่งกันเถอะ!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text('ยังไม่มีข้อมูลการวิ่ง กดปุ่ม + ด้านล่างเพื่อเพิ่ม'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchRuns,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: runs.length,
                    itemBuilder: (context, index) {
                      final item = runs[index];
                      final imgUrl = item['runImageUrl'] as String?;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: (imgUrl != null && imgUrl.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imgUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image, size: 40),
                                  ),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.directions_run),
                                ),
                          title: Text(
                            item['runWhere']?.toString() ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'ไปกับ: ${item['runPerson'] ?? '-'} • ${item['runDistance'] ?? 0} กม.',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UpdateDeleteRunUi(runData: item),
                              ),
                            );
                            if (changed == true) fetchRuns();
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0A144A),
        foregroundColor: Colors.white,
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddRunUi()),
          );
          if (added == true) fetchRuns();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}