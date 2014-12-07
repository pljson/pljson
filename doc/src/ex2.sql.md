```plsql
/*
  lists is also valid json text
*/

set serveroutput on format wrapped;
declare
  obj json_list;
begin
  obj := json_list('[1,2,3,[3, []]]'); --empty list and nested lists are supported
  obj.print;
  dbms_output.put_line(obj.to_char); --equivalent to print
  dbms_output.put_line(obj.to_char(false)); --equivalent to print(false) -- compact
end;
/
```
