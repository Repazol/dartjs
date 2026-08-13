// Anonymous function test
function add(a, b) {
    return a + b;
}

var fn = function(x) {
    return x * 2;
};

print("Result: " + fn(5));
print("Add: " + add(3, 4));

// Callback with anonymous function
setTimeOut(function() {
    print("Delayed message!");
}, 500);

print("Immediate");
