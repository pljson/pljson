# PL/JSON

**PL/JSON** provides packages and APIs for dealing with JSON formatted data within PL/SQL code.
General information about JSON is available at http://www.json.org.

## This is version 3.0 RC
It passes the tests (except the test for helper package and I work on this)
but needs some more polishing and testing and
hopefuly by the end of November 2018 it will be ready

The main difference with version 2.0 is in that now there is an object type for each json element
they are

| | |
|:---|:---|
|pljson | for json object|
|pljson_list | for json array|
|pljson_string | for json string|
|pljson_number | for json number|
|pljson_bool | for json true/false|
|pljson_null | for json null|

and all these object descend from pljson_element

while in version 2.0 the object type pljson_value holds json string, number, boolean true/false, null and pljson or pljson_list objects

this is mainly a cleaner version and I hope to cleanup old code as well

PLJSON evolved from version 1.0 using sys.anydata and worked with early Oracle releases
to version 2.0 where sys.anydata was removed and an object oriented design was used but
the object design wasn't the most appropriate one and mirrored the objects of version 1.0 so that
there was almost 100% compatibility with version 1.0 code

the code changes for version 3.0 are very few, mainly
1. use new cosntructors instead of pljson_value()
2. remove the need to call the 'to_json_value()' method
3. optionally use new helpful methods

both PLJSON version 3.0 and version 2.0 are to be maintained together for quite a long time

## A demo of things you can do with PL/JSON
```
declare
  obj pljson;
  list pljson_list;
begin

  obj := pljson('
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
  -- equivalent to print
  dbms_output.put_line(obj.to_char);

  -- print compact way
  obj.print(false);
  -- equivalent to print compact way
  dbms_output.put_line(obj.to_char(false));

  -- add to json object
  obj.put('g', 'a little string');
  -- remove from json object
  obj.remove('g');

  -- count of direct members in json object
  dbms_output.put_line(obj.count);

  -- test if an element exists
  if not obj.exist('json is good') then
    obj.put('json is good', 'Yes!');
    if obj.exist('json is good') then
      obj.print;
      dbms_output.put_line(':-)');
    end if;
  end if;

  -- you can build lists (arrays) too
  list := pljson_list(); --fresh list;
  list.append(pljson('{"lazy construction": true}'));
  list.append(pljson_list('[1,2,3,4,5]'));
  list.print;
    -- empty list and nested lists are supported
  list := pljson_list('[1,2,3,[3, []]]');
  list.print;
  -- count of direct members in json list
  dbms_output.put_line(list.count);

  -- you can also put json object or json lists as values
  obj.put('nested json', pljson('{"lazy construction": true}'));
  obj.put('an array', pljson_list('[1,2,3,4,5]'));
  obj.print;

  -- support for dates
  obj.put('a date', pljson_ext.to_json_string(to_date('2017-10-21', 'YYYY-MM-DD')));
  -- and convert it back
  dbms_output.put_line(pljson_ext.to_date(obj.get('a date')));

  obj := pljson(
    '{
      "a" : true,
      "b" : [1,2,"3"],
      "c" : {
        "d" : [["array of array"], null, { "e": 7913 }]
      }
    }');

  -- get elements using a json path expression
  -- pljson supports a simple dot path expression and '[n]' for arrays
  -- it never raises an exception (null is returned instead)
  -- arrays are 1-indexed
  -- the empty string as path returns the entire json object
  -- can 'get_string', 'get_number', etc.
  dbms_output.put_line(pljson_ext.get_number(obj, 'c.d[3].e'));

  -- all pljson_... objects are copies
  -- so modification in place is difficult
  -- but put with path can do it
  pljson_ext.put(obj, 'c.d[3].e', 123);
  obj.print;

  -- if you provide an invalid path then an error is raised
  -- you can, however, specify a path that doesn't exists but should be created
  -- arrays are 1-indexed.
  -- gaps will be filled with json null(s)
  obj := pljson();
  pljson_ext.put(obj, 'a[2].data.value[1][2].myarray', pljson_list('[1,2,3]'));
  obj.print;
  -- fill the holes
  pljson_ext.put(obj, 'a[1]', 'filler1');
  pljson_ext.put(obj, 'a[2].data.value[1][1]', 'filler2');
  obj.print;
  -- replace larger structures:
  pljson_ext.put(obj, 'a[2].data', 7913);
  obj.print;

  obj := pljson(
    '{
      "a" : true,
      "b" : [1,2,"3"],
      "c" : {
        "d" : [["array of array"], null, { "e": 7913 }]
      }
    }');
  obj.print;

  -- remove element
  pljson_ext.remove(obj, 'c.d[3].e');
  obj.print;
  -- remove array of array
  pljson_ext.remove(obj, 'c.d[1]');
  obj.print;
  -- remove null element
  pljson_ext.remove(obj, 'c.d[1]');
  obj.print;

  -- you can ignore check for duplicate keys
  obj := pljson();
  -- enables fast construction without checks for duplicate keys
  obj.check_duplicate(false);
  for i in 1 .. 10 loop
    obj.put('a'||i, i);
  end loop;
  obj.put('a'||5, 'tada');
  obj.print;
  obj.check_duplicate(true);
  -- fix possible duplicates but does not preserve order
  obj.remove_duplicates();
  obj.print;

  -- create json objects and lists from sql statements
  list := pljson_dyn.executeList('select * from tab');
  list.print;
  obj := pljson_dyn.executeObject('select * from tab');
  obj.print;
end;
/
```

### View json data as table (also works for json strings stored in table)
```
select * from table(pljson_table.json_table(
  '[
    { "id": 0, "displayname": "Back",  "qty": 5, "extras": [ { "xid": 1, "xtra": "extra_1" }, { "xid": 21, "xtra": "extra_21" } ] },
    { "id": 2, "displayname": "Front", "qty": 2, "extras": [ { "xid": 9, "xtra": "extra_9" }, { "xid": 90, "xtra": "extra_90" } ] },
    { "id": 3, "displayname": "Middle", "qty": 9, "extras": [ { "xid": 5, "xtra": "extra_5" }, { "xid": 20, "xtra": "extra_20" } ] }
  ]',
  pljson_varray('[*].id', '[*].displayname', '[*].qty', '[*].extras[*].xid', '[*].extras[*].xtra'),
  pljson_varray('id', 'displayname', 'qty', 'xid', 'xtra'),
  table_mode => 'nested'
));
```
returns

|ID | DISPLAYNAME|QTY|XID|XTRA|
|:---|:---|:---|:---|:---|
| 0	| Back	| 5	| 1	| extra_1 |
| 0	| Back	| 5	| 21|	extra_21|
| 2	| Front	| 2	| 9 |	extra_9 |
| 2	| Front	| 2	| 90|	extra_90|
| 3	| Middle| 9	| 5 |	extra_5 |
| 3 |	Middle| 9	| 20|	extra_20|

###### and many other (automatic support for Double numbers or Oracle numbers, base64 encode/decode, XML to json, etc.)

## Install

1.  Download the latest release -- https://github.com/pljson/pljson/releases
2.  Extract the zip file
3.  Use `sql*plus`, or something capable of running `sql*plus` scripts, to
    run the `install.sql` script.
4.  To test the implementation, run the `/testsuite/testall.sql` script
 
Warning:

this installation currently works in the installation schema only, but
soon there will be an installation option to work for other schemas too


**NOTICE:**

All pljson types and packages start with 'PLJSON'.
In earlier releases they started with 'JSON', but this conflicted with new
native json support in Oracle 12c so they were renamed to start with PLJSON,

Most of the examples use the old naming starting with 'JSON'.
When you try the examples, and in your code, to use `PLJSON_...` instead of `JSON_...`.
also the examples work with version 2.0 and have not been updated yet to version 3.0
but the differences are minor (see the initial description)

## Documentation

see the version 2 documentation and study the main type specifications first,
later you can study the package specifications
and I will update this README for more information

## Project folders and files

+ **install.sql** install the pljson packages and types in your schema
+ **uininstall.sql** completely uninstall packages and types
+ **src/**  source code in PL/SQL, it is accessed by the install and uninstall scripts
+ **examples/** useful examples to learn how to use pljson
+ **testsuite/** a set of testsuites to verify installation, just run **testall.sql**
+ **testsuite-utplsql/** the same set of testsuites but utilizing the utplsql framework (which you must install separately), just run ut_testall.sql

## Contributing

Please follow the [contributing guidelines](CONTRIBUTING.md) to submit fixes or new features.

## License

[MIT License](LICENSE)
