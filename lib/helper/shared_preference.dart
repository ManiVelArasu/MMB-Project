import 'package:shared_preferences/shared_preferences.dart';

class SharedPreference {
  //region String Save
  Future<bool> putStringPreference(String strKey, String? strValue) async {
    final SharedPreferences sharedPreferences =
    await SharedPreferences.getInstance();
    strValue = strValue ?? "";
    sharedPreferences.setString(strKey, strValue);
    return sharedPreferences.commit();
  }

  Future<String> getStringPreference(String strKey) async {
    final SharedPreferences sharedPreferences =
    await SharedPreferences.getInstance();
    String? strValue = sharedPreferences.getString(strKey);
    strValue = strValue ?? "";
    return strValue;
  }
  //endregion

  //region Int Save
  Future<bool> putIntPreference(String strKey, int? intValue) async {
    final SharedPreferences sharedPreferences =
    await SharedPreferences.getInstance();
    intValue = intValue ?? 0;
    sharedPreferences.setInt(strKey, intValue);
    return sharedPreferences.commit();
  }

  Future<int> getIntPreference(String strKey) async {
    final SharedPreferences sharedPreferences =
    await SharedPreferences.getInstance();
    int? intValue = sharedPreferences.getInt(strKey);
    intValue = intValue ?? 0;
    return intValue;
  }

  //endregion

  //region Bool Save
  Future<bool> putBoolPreference(String strKey, bool? blnValue) async {
    final SharedPreferences sharedPreferences =
    await SharedPreferences.getInstance();
    blnValue = blnValue ?? false;
    sharedPreferences.setBool(strKey, blnValue);
    return sharedPreferences.commit();
  }

  Future<bool> getBoolPreference(String strKey) async {
    final SharedPreferences sharedPreferences =
    await SharedPreferences.getInstance();
    bool? blnValue = sharedPreferences.getBool(strKey);
    blnValue = blnValue ?? false;
    return blnValue;
  }
//endregion
}
//TODO 'sharedPreferences.commit() is deprecated'