```plsql
/*
  Building JSON_List with the API
*/

set serveroutput on format wrapped;
declare
  obj json_list;
  procedure p(v varchar2) as begin dbms_output.put_line(null);dbms_output.put_line(v); end;
begin
  p('Building the first list');
  obj := json_list(); --an empty structure
  obj.append('a little string');
  obj.append(123456789);
  obj.append(true);
  obj.append(false);
  obj.append(json_value);
  obj.print;
  p('add with position');
  obj.append('Wow thats great!', 5);
  obj.print;
  p('remove with position');
  obj.remove(4);
  obj.print;
  p('remove first');
  obj.remove_first;
  obj.print;
  p('remove last');
  obj.remove_last;
  obj.print;
  p('you can display the size of an list');
  dbms_output.put_line(obj.count);
  p('you can also add json or json_lists as values:');
  obj := json_list(); --fresh list;
  obj.append(json('{"lazy construction": true}').to_json_value);
  obj.append(json_list('[1,2,3,4,5]'));
  obj.print;
  p('however notice that we had to use the "to_json_value" function on the json object');
end;
/
```
