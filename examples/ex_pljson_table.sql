
/*
  Copyright (c) 2016 E.I.Sarmas (github.com/dsnz)

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
*/

/*
  E.I.Sarmas (github.com/dsnz)   2016-02-09
  
  implementation and demo for json_table.json_table() functionality
  modelled after Oracle 12c json_table()
  
  this type/package is intended to work within the
  pljson library (https://github.com/pljson)
*/



/*
  test table with 3 rows, each row contains a json document
*/
drop table pljson_table_test;
create table pljson_table_test (num number not null, col clob);
insert into pljson_table_test values(1,
'{"data":
  {
   "name": "name 1",
   "description": "Cloud computing can support a company''s speed and agility, ...",
   "type": "link",
   "created_time": "2015-05-12T16:26:12+0000",
   "shares": { "count": 1 },
   "extra": "x1",
   "maps" : [ true ]
  }
}');
insert into pljson_table_test values(2,
'{"data":
  {
   "name": "name 2",
   "description": "Oracle''s suite of SaaS applications not only reduces costs but...",
   "type": "link",
   "created_time": "2015-05-29T19:23:27+0000",
   "shares": { "count": 5 },
   "extra": "x5",
   "maps" : [ true ]
  }
}');
insert into pljson_table_test values(3,
'{"data":
  {
   "name": "name 3",
   "description": "blah blah...",
   "type": "text",
   "created_time": "2015-12-21T19:23:29+0000",
   "shares": { "count": 100 },
   "extra": null,
   "maps" : [ true, true, false ]
  }
}');

commit;

set linesize 100

/*
  the call format is
  
  <type>.json_table(<json document>, pljson_varray(...), pljson_varray(...), table_mode='cartesian' (default) or 'nested')
  
  where <type> is pljson_table or json_table or pljson_table_impl
  
  pljson_varray is a type used to pass multiple string arguments
  
  1st pljson_varray ('column_paths') contains paths in the document to select and project as columns
  2nd pljson_varray ('column_names') contains names for respective paths that will serve as column names
  
  the names array is optional, if not present the columns are named JSON_1, JSON_2, ...
  
  the value for a column may be a single one (string/number/boolean/number)
  or an array of single values
  
  'cartesian' mode returns the 'cartesian product' of all column values
  'nested' mode is explained in examples later
  
  all returned columns are of type varchar2
  
  it could be easy for the columns to be automatically of type varchar2/number/...
  but this would involve excessive number of transformations from and to
  varchar representation in the implementation and would impact performance
  it is believed that the user of the library can manipulate the varchar2 values
  in the way that better serves his/her application needs
*/

/*
  *** NOTICE ***
  
  json_table() cannot work with all bind variables
  at least one of the 'column_paths' or 'column_names' parameters must be literal
  and for this reason it cannot work with cursor_sharing=force
  this is not a limitation of PLJSON but rather a result of how Oracle Data Cartridge works currently
*/

column name format a10
column extra format a10
column map format a10
column count format a10
column whatelse format a10

/*
  select from a single 'literal' json document
*/
select *
from table(
pljson_table.json_table(
'{"data":
  {
   "name": "name 3",
   "description": "blah blah...",
   "type": "text",
   "created_time": "2015-12-21T19:23:29+0000",
   "shares": { "count": 100 },
   "extra": null,
   "maps" : [ true, true, false ]
  }
}',
pljson_varray('data.name', 'data.extra', 'data.maps', 'data.shares.count', 'data.missing'),
pljson_varray('name', 'extra', 'map', 'count', 'whatelse'))
)
/

/*
  select from a single table
*/
select num, name, map, count
from pljson_table_test pljtt,
table(
pljson_table.json_table(
pljtt.col,
pljson_varray('data.name', 'data.extra', 'data.maps', 'data.shares.count', 'data.missing'),
pljson_varray('name', 'extra', 'map', 'count', 'whatelse'))
)
order by num
/

/*
  select from a single 'literal' json document and joined to other table
*/
select num, name, map, count
from pljson_table_test,
table(
pljson_table.json_table(
'{"data":
  {
   "name": "name 3",
   "description": "blah blah...",
   "type": "text",
   "created_time": "2015-12-21T19:23:29+0000",
   "shares": { "count": 100 },
   "extra": null,
   "maps" : [ true, true, false ]
  }
}',
pljson_varray('data.name', 'data.extra', 'data.maps', 'data.shares.count', 'data.missing'),
pljson_varray('name', 'extra', 'map', 'count', 'whatelse'))
)
order by num
/

/*
  select from a table with json documents projecting all results to new table
*/
select num, name, map, count
from pljson_table_test,
table(
pljson_table.json_table(
col,
pljson_varray('data.name', 'data.extra', 'data.maps', 'data.shares.count', 'data.missing'),
pljson_varray('name', 'extra', 'map', 'count', 'whatelse'))
)
order by num
/

column id format a10
column displayname format a20
column qty format a10
column xid format a10
column xtra format a10

/*
  NEW 'nested' mode, same as NESTED PATH in Oracle 12c json_table but easier and less verbose
  (previous mode is called 'cartesian' and is default)
  
  each path is nested at same level or deeper than previous path
  in order to express this, the path syntax supports '[*]' to indicate a json array
  in this example
  column 1 = value of "id" in each object of main json array
  column 2 = value of "displayname" in same object
  column 3 = value of "qty" in same object
  column 4 = value of "xid" in each object within array "extras" inside object in previous columns
  column 5 = value of "xtra" in same object as previous column
  
  === NOTE ===
  in Oracle 11g and 12c, any run of json_table will produce 2 new types with Oracle generated names (like "SYSTPcHv5nozBRE+I3lWIMic2bQ==")
  for each different select (different in number or names of columns)
  these are temporary and should be cleared automatically within 12 hours
*/
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

column requestor format a20
column state format a10
column phone_type format a10
column phone_num format a20

/*
  NEW 'nested' mode, same as NESTED PATH in Oracle 12c json_table but easier and less verbose
  (previous mode is called 'cartesian' and is default)
  
  each path is nested at same level or deeper than previous path
  in order to express this, the path syntax supports '[*]' to indicate a json array
  an example from Oracle Database JSON Developer's Guide 12c Release 2 (12.2)
  json document in pg. 4-2 and query in pg. 17-6 (enhanced with 2 extra initial columns)
*/
select * from table(pljson_table.json_table('{
  "PONumber" : 1600,
  "Reference" : "ABULL-20140421",
  "Requestor" : "Alexis Bull",
  "User" : "ABULL",
  "CostCenter" : "A50",
  "ShippingInstructions" : {"name" : "Alexis Bull",
                            "Address" : {"street" : "200 Sporting Green",
                                         "city" : "South San Francisco",
                                         "state" : "CA",
                                         "zipCode" : 99236,
                                         "country" : "United States of America"},
                            "Phone"   : [{"type" : "Office", "number" : "909-555-7307"},
                                         {"type" : "Mobile", "number" : "415-555-1234"}]},
  "Special Instructions" : null,
  "AllowPartialShipment" : true,
  "LineItems" : [{"ItemNumber" : 1,
                  "Part" : {"Description" : "One Magic Christmas",
                            "UnitPrice" : 19.95,
                            "UPCCode" : 13131092899},
                            "Quantity" : 9.0},
                 {"ItemNumber" : 2,
                  "Part" : {"Description" : "Lethal Weapon",
                            "UnitPrice" : 19.95,
                            "UPCCode" : 85391628927},
                            "Quantity" : 5.0}]
} ',
  pljson_varray('Requestor', 'ShippingInstructions.Address.state', 'ShippingInstructions.Phone[*].type', 'ShippingInstructions.Phone[*].number'),
  pljson_varray('requestor', 'state', 'phone_type', 'phone_num'),
  table_mode => 'nested'
));

column item_number format a10
column description format a20
column quantity format a10

/*
  NEW 'nested' mode, same as NESTED PATH in Oracle 12c json_table but easier and less verbose
  (previous mode is called 'cartesian' and is default)
  
  each path is nested at same level or deeper than previous path
  in order to express this, the path syntax supports '[*]' to indicate a json array
  an example from Oracle Database JSON Developer's Guide 12c Release 2 (12.2)
  json document in pg. 4-2 and based on query in pg. 17-6 but with new columns illustrating more flexibility
*/
select * from table(pljson_table.json_table('{
  "PONumber" : 1600,
  "Reference" : "ABULL-20140421",
  "Requestor" : "Alexis Bull",
  "User" : "ABULL",
  "CostCenter" : "A50",
  "ShippingInstructions" : {"name" : "Alexis Bull",
                            "Address" : {"street" : "200 Sporting Green",
                                         "city" : "South San Francisco",
                                         "state" : "CA",
                                         "zipCode" : 99236,
                                         "country" : "United States of America"},
                            "Phone"   : [{"type" : "Office", "number" : "909-555-7307"},
                                         {"type" : "Mobile", "number" : "415-555-1234"}]},
  "Special Instructions" : null,
  "AllowPartialShipment" : true,
  "LineItems" : [{"ItemNumber" : 1,
                  "Part" : {"Description" : "One Magic Christmas",
                            "UnitPrice" : 19.95,
                            "UPCCode" : 13131092899},
                            "Quantity" : 9.0},
                 {"ItemNumber" : 2,
                  "Part" : {"Description" : "Lethal Weapon",
                            "UnitPrice" : 19.95,
                            "UPCCode" : 85391628927},
                            "Quantity" : 5.0}]
}',
  pljson_varray('LineItems[*].ItemNumber', 'LineItems[*].Part.Description', 'LineItems[*].Quantity'),
  pljson_varray('item_number', 'description', 'quantity'),
  table_mode => 'nested'
));
