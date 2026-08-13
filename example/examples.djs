// Mongol Script Language - Examples

// Basic function
function greet(name) {
    print("Hello, " + name + "!");
}

// Function with multiple parameters
function add(a, b) {
    return a + b;
}

// Variable declarations
var x = 10;
var y = 20;
var result = add(x, y);
print("Sum: " + result);

// Conditionals
if (x > 5) {
    print("x is greater than 5");
} else {
    print("x is 5 or less");
}

// While loop
var i = 0;
while (i < 5) {
    print("i = " + i);
    i = i + 1;
}

// Function call
greet("Mongol");

// Random number
var num = random(1, 100);
print("Random: " + num);
