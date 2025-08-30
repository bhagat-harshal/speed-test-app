import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/history_controller.dart';
import '../models/speed_result.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatTs(DateTime dt) {
    final d = dt.toLocal();
    // yyyy-mm-dd hh:mm
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HistoryController>();
    return Obx(() {
      if (ctrl.loading.value && ctrl.items.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: ctrl.refreshList,
        child: ctrl.items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No results yet. Run a test to see history.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 88, top: 8),
                itemCount: ctrl.items.length + 1,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // header with actions
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            'History',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Refresh',
                            onPressed: ctrl.refreshList,
                            icon: const Icon(Icons.refresh),
                          ),
                          IconButton(
                            tooltip: 'Clear all',
                            onPressed: ctrl.items.isEmpty
                                ? null
                                : () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Clear all results?'),
                                        content: const Text('This action cannot be undone.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Clear'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      await ctrl.clearAll();
                                    }
                                  },
                            icon: const Icon(Icons.delete_sweep),
                          ),
                        ],
                      ),
                    );
                  }
                  final SpeedResult item = ctrl.items[index - 1];
                  return Dismissible(
                    key: ValueKey(item.id ?? item.timestamp.toIso8601String()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete result?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) async {
                      if (item.id != null) {
                        await ctrl.deleteItem(item.id!);
                      } else {
                        await ctrl.refreshList();
                      }
                    },
                    child: ListTile(
                      title: Text(
                        '${item.downloadMbps.toStringAsFixed(1)} ↓  |  ${item.uploadMbps.toStringAsFixed(1)} ↑  Mbps',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${_formatTs(item.timestamp)}  •  ${item.connectionType}  •  ${item.pingMs.toStringAsFixed(0)} ms',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      leading: const Icon(Icons.history),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Placeholder for details view in future
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Result details'),
                            content: Text(
                              'Time: ${_formatTs(item.timestamp)}\n'
                              'Connection: ${item.connectionType}\n'
                              'Ping: ${item.pingMs.toStringAsFixed(0)} ms\n'
                              'Download: ${item.downloadMbps.toStringAsFixed(2)} Mbps\n'
                              'Upload: ${item.uploadMbps.toStringAsFixed(2)} Mbps',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      );
    });
  }
}
