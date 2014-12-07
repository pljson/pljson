```plsql
/*
  Variables are copied on insertion
*/

set serveroutput on format wrapped;
declare
  obj json;
  obj2 json;
  str varchar2(20);
  pair_value json_value;
  procedure p(v varchar2) as begin dbms_output.put_line(null);dbms_output.put_line(v); end;
begin
  p('Variables are copies');
  obj := json(); --an empty structure
  str := 'ABC';
  obj.put('N1', str);
  str := 'DEF';
  obj.print;
  obj.put('N2', str);
  obj.print;
  
  p('Even nested json are copies');
  obj2 := json('{"a":true}');
  obj.put('N1', obj2);
  obj2.remove('a');
  obj.put('N2', obj2);
  obj.print;
  
  p('Extract data from json');
  pair_value := obj.get('N1');
  --what to do with json_value? get the content into the right type!
  obj2 := json(pair_value); --json construtor with json_value only works if json_value contains a json
  obj2.print;
  --JSON_LIST works in the same manner.
end;
/
```
