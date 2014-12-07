```plsql
/*
  Building JSON objects with the API
*/

set serveroutput on format wrapped;
declare
  obj json;
  procedure p(v varchar2) as begin dbms_output.put_line(null);dbms_output.put_line(v); end;
begin
  p('Build a little json structure');
  obj := json(); --an empty structure
  obj.put('A', 'a little string');
  obj.put('B', 123456789);
  obj.put('C', true);
  obj.put('D', false);
  obj.put('F', json_value.makenull);
  obj.print;
  p('add with position');
  obj.put('E', 'Wow thats great!', 5);
  obj.print;
  p('replace ignores position');
  obj.put('C', 'Maybe I should have removed C before the insertion.', 5);
  obj.print;
  p('remove and put');
  obj.remove('C');
  obj.put('C', 'Now it works.', 5);
  obj.print;
  p('you can count the direct members in a json object');
  dbms_output.put_line(obj.count);
  p('you can also test if an element exists (note that due to oracle the method is not named "exists")');
  if(not obj.exist('json is good')) then
    dbms_output.put_line('Well it is!');
    obj.put('json is good', 'Yes sir!', -10); -- defaults to 1
    if(obj.exist('json is good')) then
      obj.print;
      dbms_output.put_line(':-)');
    end if;
  end if;
  p('you can also put json or json_lists as values:');
  obj := json(); --fresh json;
  obj.put('Nested JSON', json('{"lazy construction": true}'));
  obj.put('An array', json_list('[1,2,3,4,5]'));
  obj.print;
end;
/
```
