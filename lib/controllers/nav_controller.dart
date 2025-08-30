import 'package:get/get.dart';

class NavController extends GetxController {
  final currentIndex = 0.obs;

  void setIndex(int index) {
    currentIndex.value = index;
  }

  String get title {
    switch (currentIndex.value) {
      case 0:
        return 'Speed Test';
      case 1:
        return 'Results History';
      case 2:
        return 'Settings';
      default:
        return 'Speed Test';
    }
  }
}
