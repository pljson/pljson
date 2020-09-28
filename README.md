<img alt="language" src="https://img.shields.io/badge/language-PLSQL%2FSQL-brightgreen?labelColor=orange">

<img alt="platform" src="https://img.shields.io/badge/platform-Oracle-red?labelColor=brightgreen">

<img alt="version" src="https://img.shields.io/github/package-json/v/pljson/pljson/develop_v3?color=orange&label=version&labelColor=brightgreen">

# PL/JSON

**PL/JSON** provides packages and APIs for dealing with JSON formatted data within PL/SQL code.
General information about JSON is available at http://www.json.org.

## Latest release 3.4.1 (2020-09-28)

## This is version 3
You should move to version 3. It's cleaner and faster.
(note: that it fails the test for helper package and I will work on this)

The main difference with version 2 is in that now there is an object type for each json element.
The types are

| | |
|:---|:---|
|**pljson** | for json object|
|**pljson_list** | for json array|
|**pljson_string** | for json string|
|**pljson_number** | for json number|
|**pljson_bool** | for json true/false|
|**pljson_null** | for json null|

and all these types descend from type **pljson_element**

while in version 2 the object type pljson_value is a container that contains one of
string, number, boolean true/false, null, pljson or pljson_list

This is a cleaner design and the benefit is easier coding and faster and more memory efficient code.

In the JSON standard, a document consists of "value(s)"
so we should name the parent of all objects pljson_value
however this name has been so much ingrained with version 1 and version 2
that it is felt that a new name should be used and so the parent is now named pljson_element.
Old code uses a lot pljson_value() constructors while new code has no such constructors
but instead has specific constructors for string, number, etc.
and so code compatibility could not be maintained even if the name of pljson_value was kept.

PLJSON evolved from version 1 using sys.anydata and worked with early Oracle releases
to version 2 where sys.anydata was removed and an object oriented design was used but
the object design wasn't the most appropriate one and mirrored the objects of version 1 so that
there was almost 100% compatibility with version 1 code.

The api changes for version 3 are few, mainly
1. use new constructors instead of pljson_value()
2. remove the need to call the 'to_json_value()' method
3. optionally use many new helpful methods for easier coding

Both PLJSON version 3 and version 2 will be maintained together for quite a long time
and there will be effort that there is as much common code as possible between the two versions
but new features and improvements will be delivered first to version 3.

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

##### and many other (automatic support for Double numbers or Oracle numbers, base64 encode/decode, XML to json, etc.)

### Notes about PLJSON path operations

- never raise an exception (null is returned instead)
- arrays are 1-indexed
- use dots to navigate through the json nested objects
- the empty string as path returns the entire json object
- 7 get types are supported: string, number, bool, null, json, json_list and date
- spaces inside [ ] are not important, but are important otherwise
- keys made with non-standard javascript characters must be enclosed in double quotes

## Install

1.  Download the latest release -- https://github.com/pljson/pljson/releases
2.  Extract the zip file
3.  Use `sql*plus`, or something capable of running `sql*plus` scripts, to
    run the `install.sql` script.
4.  To test the implementation, run the `/testsuite/testall.sql` script
 
Warning:

This installation currently works in the installation schema only (ie. you can't use it from other schema).

If you used version 2 in past and want to use the new version 3 in the same schema then
you must first uninstall version 2 (use uninstall.sql of version 2) and then install version 3.

**NOTICE:**

All pljson types and packages start with 'PLJSON'.
In earlier releases they started with 'JSON', but this conflicted with new
native json support in Oracle 12c so they were renamed to start with PLJSON.
For backwards compatibility in version 2 there are created corresponding synonyms
starting with 'JSON'. In version 3 no such synonyms are created.

Most of the examples use the old naming starting with 'JSON'.
When you try the examples, and in your code, use `PLJSON_...` instead of `JSON_...`.
Also, the example code was made with version 2 api and has not been updated to version 3 api yet
but the differences are minor (see the initial description) and most code should work without change.

## Documentation

See the version 2 documentation and study the main type specifications first.
Later you can study the package specifications
and I will also keep updating this README for more information.

## Project folders and files

+ **install.sql** install the pljson packages and types in your schema
+ **uininstall.sql** completely uninstall packages and types
+ **src/**  source code in PL/SQL, it is accessed by the install and uninstall scripts
+ **examples/** useful examples to learn how to use pljson
+ **testsuite/** a set of testsuites to verify installation, just run **testall.sql**
+ **testsuite-utplsql/** the same set of testsuites but utilizing the utplsql framework (which you must install separately), just run ut_testall.sql

## Support
To report bugs, suggest improvements, or ask questions, please create a new issue.

## Contributing

Please follow the [contributing guidelines](CONTRIBUTING.md) to submit fixes or new features.

## License

[MIT License](LICENSE)
