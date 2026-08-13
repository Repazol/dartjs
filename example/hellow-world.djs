function log(logStr){
	//print logStr to console
	print(logStr);
}

function calcFunc(a,b,c){
	var f=random(1,100);
	return a*f+b*c;
}

var store={id:10,name:'Optovka',phones:["77015578620","77773443238"]};
print('Store ' + store);
print('Store.keys ' + store.keys());
var hasProperty=store.hasProperty('name');
print('hasProperty ' + hasProperty);
if (hasProperty){
	print('Good');
}

var arr=[];
for(var i=0;i<10;i++){
	arr.push(parseInt(i));
}
print('Arr: ',arr);
setTimeOut(function(){ log("Func="+calcFunc(20,30,50)); },1000);//print log after second
print('End');
try{
var a=1/0;
print('a :',a);

var user=http.getJson('https://jsonplaceholder.typicode.com/users/1/todos',{id:'2'},{token:'1223344'});
print('User: ',user);

http.getJson(
	'https://jsonplaceholder.typicode.com/users/1/todos',//URL
	{id:'10'},//QUERY
	{token:'IOU*(uyojdlkjsla'},//HEADERS
	function(data){//success if code==200
		print('GET :',data);

	},
	function(error,code){//error if code!=200 or bad json
		print('HttpError :',error+'('+code+')');
	}
);
} catch (e){
  print("Error: $e");
}

setLabel('label','Title');
var result = serverTime();
print('Server time: `$result`');

var trigonometry={
	sin:sin(PI/2),
	cos:cos(PI/2),
	sqrt2:SQRT2,
	e:E,
}
print ('trigonometry: ${trigonometry}\ncos: ${trigonometry.cos}');

var str='0123456789';
var fields='id,name,address';
var fieldsArray=split(',',fields);
print('fields: $fieldsArray');
var l=length(str);
print('length: $l'); // ==10
var subStr=substr(1,3,str);// == 123

var yesNo=random(1,2)==1?"Yes":"No";
print("yesNo: $yesNo");