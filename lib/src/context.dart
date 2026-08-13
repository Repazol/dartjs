import 'environment.dart';

class DartJSContext {
  final Environment env;

  DartJSContext([Map<String, dynamic>? initialVariables]) : env = Environment() {
    if (initialVariables != null) {
      for (final entry in initialVariables.entries) {
        env.define(entry.key, entry.value);
      }
    }
  }

  dynamic get(String name) => env.get(name);
  void set(String name, dynamic value) => env.define(name, value);
  bool has(String name) {
    try {
      env.get(name);
      return true;
    } catch (_) {
      return false;
    }
  }
}
