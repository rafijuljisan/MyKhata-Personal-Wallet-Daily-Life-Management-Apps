import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A class to hold the profile data
class ShopProfile {
  final String name;
  final String address;
  final String phone;

  ShopProfile({this.name = "", this.address = "", this.phone = ""});
}

// The Notifier to manage the state
class ShopProfileNotifier extends Notifier<ShopProfile> {
  @override
  ShopProfile build() {
    // Load initial state (We will load real data in loadProfile)
    return ShopProfile(name: "My Shop", address: "", phone: "");
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('shop_name') ?? "My Shop";
    final address = prefs.getString('shop_address') ?? "";
    final phone = prefs.getString('shop_phone') ?? "";
    state = ShopProfile(name: name, address: address, phone: phone);
  }

  Future<void> updateProfile(String name, String address, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shop_name', name);
    await prefs.setString('shop_address', address);
    await prefs.setString('shop_phone', phone);
    state = ShopProfile(name: name, address: address, phone: phone);
  }
}

final shopProfileProvider = NotifierProvider<ShopProfileNotifier, ShopProfile>(() {
  return ShopProfileNotifier();
});