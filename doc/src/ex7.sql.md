```plsql
/*
  Using the JSON_EXT package
*/

set serveroutput on format wrapped;
declare
  obj json := json();
  testdate date := date '2009-12-24'; --Xmas
  procedure p(v varchar2) as begin dbms_output.put_line(null);dbms_output.put_line(v); end;
begin
  obj.put('My favorite date', json_ext.to_json_value(testdate));
  obj.print;
  if(json_ext.is_date(obj.get('My favorite date'))) then
    p('We can also test the value');
  end if;
  p('And convert it back');
  dbms_output.put_line(json_ext.to_date2(obj.get('My favorite date')));
end;
/
```
