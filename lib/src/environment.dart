class Environment {
  final Map<String, dynamic> variables = {};
  Environment? parent;

  Environment([this.parent]);

  dynamic get(String name) {
    if (variables.containsKey(name)) return variables[name];
    if (parent != null) return parent!.get(name);
    throw Exception('Undefined variable: $name');
  }

  void set(String name, dynamic value) {
    if (variables.containsKey(name)) {
      variables[name] = value;
    } else if (parent != null) {
      parent!.set(name, value);
    } else {
      variables[name] = value;
    }
  }

  void define(String name, dynamic value) {
    variables[name] = value;
  }
}
