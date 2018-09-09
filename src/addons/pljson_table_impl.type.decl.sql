set termout off
create or replace type pljson_varray as table of varchar2(32767);
/
create or replace type pljson_narray as table of number;
/

set termout on
create or replace type pljson_vtab as table of pljson_varray;
/

create or replace type pljson_table_impl as object (
  
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
    E.I.Sarmas (github.com/dsnz)   2016-02-09   first version
    
    E.I.Sarmas (github.com/dsnz)   2017-07-21   minor update, better parameter names
    E.I.Sarmas (github.com/dsnz)   2017-09-23   major update, table_mode = cartesian/nested
  */
  
  /*
    *** NOTICE ***
    
    json_table() cannot work with all bind variables
    at least one of the 'column_paths' or 'column_names' parameters must be literal
    and for this reason it cannot work with cursor_sharing=force
    this is not a limitation of PLJSON but rather a result of how Oracle Data Cartridge works currently
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
  /*
    for 'nested' mode paths must use the [*] path operator
  */
  column_paths pljson_varray,
  column_names pljson_varray,
  table_mode varchar2(20),
  
  /*
    'cartesian' mode uses only
    data_tab, row_ind
  */
  data_tab pljson_vtab,
  /*
    'nested' mode uses only
    row_ind, row_count, nested_path
    column_nested_index
    last_nested_index
    
    for row_ind, row_count, nested_path
    each entry corresponds to a [*] in the full path of the last column
    and there will be the same or fewer entries than columns
    1st nested path corresponds to whole array as '[*]'
    or to root object as '' or to array within root object as 'key1.key2...array[*]'
    
    column_nested_index maps column index to nested_... index
  */
  row_ind pljson_narray,
  row_count pljson_narray,
  /*
    nested_path_full = full path, up to and including last [*], but not dot notation to key
    nested_path_ext = extension to previous nested path
    column_path_part = extension to nested_path_full, the dot notation to key after last [*]
    column_path = nested_path_full || column_path_part
    
    start_column = start column where nested path appears first
    nested_path_literal = nested_path_full with * replaced with literal integers, for fetching
    
    column_path = a[*].b.c[*].e
    nested_path_full = a[*].b.c[*]
    nested_path_ext = .b.c[*]
    column_path_part = .e
  */
  nested_path_full pljson_varray,
  nested_path_ext pljson_varray,
  start_column pljson_narray,
  nested_path_literal pljson_varray,
  
  column_nested_index pljson_narray,
  column_path_part pljson_varray,
  column_val pljson_varray,
  
  /* if the root of the document is array, the size of the array */
  root_array_size number,
  
  /* the parsed json_obj */
  json_obj pljson,
  
  ret_type anytype,
  
  static function ODCITableDescribe(
    rtype out anytype,
    json_str clob, column_paths pljson_varray, column_names pljson_varray := null,
    table_mode varchar2 := 'cartesian'
  ) return number,
  
  static function ODCITablePrepare(
    sctx out pljson_table_impl,
    ti in sys.ODCITabFuncInfo,
    json_str clob, column_paths pljson_varray, column_names pljson_varray := null,
    table_mode varchar2 := 'cartesian'
  ) return number,
  
  static function ODCITableStart(
    sctx in out pljson_table_impl,
    json_str clob, column_paths pljson_varray, column_names pljson_varray := null,
    table_mode varchar2 := 'cartesian'
  ) return number,
  
  member function ODCITableFetch(
    self in out pljson_table_impl, nrows in number, outset out anydataset
  ) return number,
  
  member function ODCITableClose(self in pljson_table_impl) return number,
  
  static function json_table(
    json_str clob, column_paths pljson_varray, column_names pljson_varray := null,
    table_mode varchar2 := 'cartesian'
  ) return anydataset
  pipelined using pljson_table_impl
);
/
show err

create synonym pljson_table for pljson_table_impl;