```plsql
/*
    json parses varchar2 strings 
    max json length is 32000, 
    max pair_name length is 4000, 
    max string length is 4000
*/

set serveroutput on format wrapped;
declare
  obj json;
begin
  obj := json('{"a": true }');
  obj.print;
  --more complex json:
  obj := json('
{
  "a": null,
  "b": 12.243,
  "c": 2e-3,
  "d": [true, false, "abdc", [1,2,3]],
  "e": [3, {"e2":3}],
  "f": {
    "f2":true
  }
}');
  obj.print;
  obj.print(false); --compact way
end;
/
```
