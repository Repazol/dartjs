// External command handler example

// Register command handler
onCommand(function(){
    print('Command: ' + name + ' (type: ' + type + ')');

    // Handle external commands
    if (name == 'db') {
        return {host:'localhost',port:5432,user:'admin'};
    }
    if (name == 'config') {
        return {version:'1.0',debug:true};
    }

    // Return true to suppress error, or null/undefined to throw
    print('Unknown command: ' + name);
    return true;
});

// These variables are undefined but handled by onCommand
print('DB: ', db);
print('DB.host: ' + db.host);

print('Config: ', config);
print('Config.version: ' + config.version);

// This will trigger onCommand but still show error message
var unknown = unknownVar;
