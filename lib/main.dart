import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';

void main() {
  // ProviderScope is required for Riverpod to work
  runApp(const ProviderScope(child: MyKhataApp()));
}