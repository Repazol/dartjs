// String interpolation test
var name = "World";
var x = 42;

print("Hello, $name!");
print("x = $x");
print("2 + 3 = ${2 + 3}");
print("PI = ${3.14159 * 2}");

// Escape sequences
print("line1\nline2");
print("tab\there");
print("escaped \\ dollar");

// Property access in interpolation
var trigonometry = 0.5;
print('trigonometry: $trigonometry');
print('cos: ${cos(trigonometry)}');
print("trigonometry: $trigonometry\\ncos: ${cos(trigonometry)}");

// Nested expressions
var a = 10;
var b = 20;
print("a + b = ${a + b}");
print("max = ${max(a, b)}");
