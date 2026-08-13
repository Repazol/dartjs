var s = "hello world";

// Методы
print(s.length);
print(s.toUpperCase());
print(s.toLowerCase());
print(s.trim());
print(s.contains("world"));
print(s.startsWith("hello"));
print(s.endsWith("world"));
print(s.indexOf("world"));
print(s.replace("world", "Mongol"));
print(s.substring(0, 5));
print(s.charAt(1));
var sp=s.split(" ");
print("sp: $sp (${sp.length()})");

// Свойство .length (без скобок)
print(s.length);

// Цепочка
print("  hi  ".trim().toUpperCase());

// padStart / padEnd
print("42".padStart(6, "0"));
print("hi".padEnd(6, "."));

// repeat
print("ab".repeat(3));

// indexOf -1 если нет
print(s.indexOf("xyz"));
