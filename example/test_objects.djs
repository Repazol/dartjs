// Object and Array examples

// Object literal
var store = {
    id: 10,
    name: 'Optovka',
    phones: ["77015578620", "77773443238"]
};

print("Store name: " + store.name);
print("Store ID: " + store.id);
print("First phone: " + store.phones[0]);
print("Second phone: " + store.phones[1]);

// Modify object
store.city = "Almaty";
print("City: " + store.city);

// Bracket access
print("Name via bracket: " + store["name"]);

// Array operations
var arr = [1, 2, 3, 4, 5];
print("Array length: " + arr.length);
print("First element: " + arr[0]);
print("Last element: " + arr[4]);

// Nested objects
var user = {
    name: "Admin",
    settings: {
        theme: "dark",
        language: "ru"
    }
};

print("User: " + user.name);
print("Theme: " + user.settings.theme);
