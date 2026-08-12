
import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  Future<void> setUser(String user) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString('user', user);
  }

  Future<String> getUser() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString('user') ?? '';
  }

  Future<void> setTheme(String value) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString('theme', value);
  }

  Future<String?> getTheme() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('theme');
  }
}
