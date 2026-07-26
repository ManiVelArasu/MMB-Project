import 'package:flutter/cupertino.dart';
/*import 'package:provider_base/core/rout_config/app_routs.dart' hide AppRouter;*/
import '../rout_config/app_navigator.dart';
import '../rout_config/app_routs.dart';
import 'my_notifier.dart';


class LocaleProvider extends ChangeNotifier with MyNotifier {

  LocaleProvider(){
    init();
  }
  
  Future<void> init()async{
  await Future.delayed(Duration(seconds: 1));
  //AppRouter.pushReplacement(AppRoutes.bottomNav);
  }

}
