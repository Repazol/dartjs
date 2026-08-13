var str='0123456789';
var fields='id,name,address';
var fieldsArray=split(',',fields);
print('fields: $fieldsArray');
var l=length(str);
print('length: $l'); // ==10
var subStr=substr(1,3,str);// == 123
var data=json('{"id":10,"name":"Ivan"}');
print('data: $data');
var jsonStr=jsonEncode(fieldsArray);
print('jsonStr: $jsonStr');

var c=contains(toLowerCase('12'), toLowerCase('4325212542432'));
var c1=contains(toLowerCase('4325212542432'),toLowerCase('12'));
print('c: $c c1:$c1');