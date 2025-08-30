import 'package:get/get.dart';

import '../controllers/nav_controller.dart';
import '../controllers/speed_controller.dart';
import '../controllers/history_controller.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // Persist navigation controller
    Get.put(NavController(), permanent: true);

    // Feature controllers
    Get.lazyPut<SpeedController>(() => SpeedController(), fenix: true);
    Get.lazyPut<HistoryController>(() => HistoryController(), fenix: true);
  }
}
