
create or replace type pljson_varray as table of varchar2(32767);
/

create or replace type pljson_vtab as table of pljson_varray;
/

create or replace type pljson_narray as table of number;
/

create synonym pljson_table for pljson_table_impl;



create or replace type pljson_table_impl as object
(
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
  drop type pljson_table_impl;
  drop type pljson_narray;
  drop type pljson_vtab;
  drop type pljson_varray;
  
  create or replace type pljson_varray as table of varchar2(32767);
  create or replace type pljson_vtab as table of pljson_varray;
  create or replace type pljson_narray as table of number;
  
  create synonym pljson_table for pljson_table_impl;
  */
  
  str clob, -- varchar2(32767),
  paths pljson_varray,
  names pljson_varray,
  data_tab pljson_vtab,
  row_inds pljson_narray,
  ret_type anytype,
  static function ODCITableDescribe(rtype out anytype,
    str clob, paths pljson_varray, names pljson_varray := null) return number,
  static function ODCITablePrepare(sctx out pljson_table_impl, ti in sys.ODCITabFuncInfo,
    str clob, paths pljson_varray, names pljson_varray := null) return number,
  static function ODCITableStart(sctx in out pljson_table_impl,
    str clob, paths pljson_varray, names pljson_varray := null) return number,
  member function ODCITableFetch(self in out pljson_table_impl, nrows in number, outset out anydataset) return number,
  member function ODCITableClose(self in pljson_table_impl) return number,
  static function json_table(str clob, paths pljson_varray, names pljson_varray := null) return anydataset
    pipelined using pljson_table_impl
);
/