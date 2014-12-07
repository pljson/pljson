```plsql
/*
  Working with errors/exceptions
  The parser follows the json specification described @ www.json.org  
*/

set serveroutput on format wrapped;
declare
  scanner_exception exception;
  pragma exception_init(scanner_exception, -20100);
  parser_exception exception;
  pragma exception_init(parser_exception, -20101);

  obj json;
begin
  obj := json('this is not valid json'); 
  --displays ORA-20100: JSON Scanner exception @ line: 1 column: 1 - Expected: 'true'
  --thats because the closest match was a boolean
  obj.print;
exception 
  when scanner_exception then
    dbms_output.put_line(SQLERRM);
  when parser_exception then
    dbms_output.put_line(SQLERRM);
end;
/
```
