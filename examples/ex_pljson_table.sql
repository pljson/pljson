
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

/*
  the call format is
  
  <type>.json_table(<json document>, pljson_varray(...), pljson_varray())
  
  where <type> is pljson_table or json_table or pljson_table_impl
  
  pljson_varray is a type used to pass multiple string arguments
  
  1st pljson_varray contains 'paths' in the document to select and project as columns
  2nd pljson_varray contains 'names' for respective paths that will serve as 'column names'
  
  the names array is optional, if not present the columns are named JSON_1, JSON_2, ...
  
  the value for a column may be a single one (string/number/boolean/number)
  or an array of single values
  
  the final table contains the 'cartesian product' of all column values
  (this is equivalent to the 'NESTED PATH' of json_table() in Oracle12c)
  
  all returned columns are of type varchar2
  
  it could be easy for the columns to be automatically of type varchar2/number/...
  but this would involve excessive number of transformations from and to
  varchar representation in the implementation and would impact performance
  it is believed that the user of the library can manipulate the varchar2 values
  in the way that better serves his/her application needs
*/



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
pljson_varray('data.name', 'data.extra', 'data.maps', 'data.shares.count'),
pljson_varray('name', 'extra', 'map', 'count'))
)
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
pljson_varray('data.name', 'data.extra', 'data.maps', 'data.shares.count'),
pljson_varray('name', 'extra', 'map', 'count'))
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
pljson_varray('data.name', 'data.extra', 'data.maps', 'data.shares.count'),
pljson_varray('name', 'extra', 'map', 'count'))
)
order by num
/