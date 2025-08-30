import 'package:get/get.dart';

import '../data/app_database.dart';
import '../data/result_repository.dart';
import '../models/speed_result.dart';

class HistoryController extends GetxController {
  final repo = ResultRepository.instance;

  final items = <SpeedResult>[].obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await AppDatabase.instance.init();
    await refreshList();
  }

  Future<void> refreshList() async {
    loading.value = true;
    try {
      final list = await repo.getAll(newestFirst: true);
      items.assignAll(list);
    } finally {
      loading.value = false;
    }
  }

  Future<void> deleteItem(int id) async {
    await repo.delete(id);
    await refreshList();
  }

  Future<void> clearAll() async {
    await repo.clear();
    await refreshList();
  }
}
