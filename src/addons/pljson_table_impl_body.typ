
create or replace type body pljson_table_impl as

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
  
  static function ODCITableDescribe(rtype out anytype,
    str clob, paths pljson_varray, names pljson_varray := null) return number is
    atyp anytype;
  begin
    --dbms_output.put_line('>>Describe');
    
    anytype.begincreate(dbms_types.typecode_object, atyp);
    if names is null then
      for i in paths.FIRST .. paths.LAST loop
        atyp.addattr('JSON_' || ltrim(to_char(i)), dbms_types.typecode_varchar2, null, null, 32767, null, null);
      end loop;
    else
      for i in names.FIRST .. names.LAST loop
        atyp.addattr(upper(names(i)), dbms_types.typecode_varchar2, null, null, 32767, null, null);
      end loop;
    end if;
    atyp.endcreate;
    
    anytype.begincreate(dbms_types.typecode_table, rtype);
    rtype.SetInfo(null, null, null, null, null, atyp, dbms_types.typecode_object, 0);
    rtype.endcreate();
    
    return odciconst.success;
  exception
    when others then
      return odciconst.error;
  end;
  
  static function ODCITablePrepare(sctx out pljson_table_impl, ti in sys.ODCITabFuncInfo,
    str clob, paths pljson_varray, names pljson_varray := null) return number is
    elem_typ sys.anytype;
    prec  pls_integer;
    scale pls_integer;
    len   pls_integer;
    csid  pls_integer;
    csfrm pls_integer;
    tc    pls_integer;
    aname varchar2(30);
  begin
    --dbms_output.put_line('>>Prepare');
    
    tc := ti.RetType.GetAttrElemInfo(1, prec, scale, len, csid, csfrm, elem_typ, aname);
    sctx := pljson_table_impl(str, paths, names, pljson_vtab(), pljson_narray(), elem_typ);
    return odciconst.success;
  end;
  
  static function ODCITableStart(sctx in out pljson_table_impl,
    str clob, paths pljson_varray, names pljson_varray := null) return number is
    json_obj pljson;
    json_val pljson_value;
    buf varchar2(32767);
    --data_tab pljson_vtab := pljson_vtab();
    json_array pljson_list;
    json_elem pljson_value;
    value_array pljson_varray := pljson_varray();
  begin
    --dbms_output.put_line('>>Start');
    
    sctx.data_tab.delete;
    --dbms_output.put_line('json_str='||str);
    json_obj := pljson(str);
    for i in paths.FIRST .. paths.LAST loop
      --dbms_output.put_line('path='||paths(i));
      json_val := pljson_ext.get_json_value(json_obj, paths(i));
      --dbms_output.put_line('type='||json_val.get_type());
      case json_val.typeval
        --when 1 then 'object';
        when 2 then -- 'array';
          json_array := pljson_list(json_val);
          value_array.delete;
          for j in 1 .. json_array.count loop
            json_elem := json_array.get(j);
            case json_elem.typeval
              --when 1 then 'object';
              --when 2 then -- 'array';
              when 3 then -- 'string';
                buf := json_elem.get_string();
                --dbms_output.put_line('res[]='||buf);
                value_array.extend(); value_array(value_array.LAST) := buf;
              when 4 then -- 'number';
                buf := to_char(json_elem.get_number());
                --dbms_output.put_line('res[]='||buf);
                value_array.extend(); value_array(value_array.LAST) := buf;
              when 5 then -- 'bool';
                buf := case json_elem.get_bool() when true then 'true' when false then 'false' end;
                --dbms_output.put_line('res[]='||buf);
                value_array.extend(); value_array(value_array.LAST) := buf;
              when 6 then -- 'null';
                buf := null;
                --dbms_output.put_line('res[]='||buf);
                value_array.extend(); value_array(value_array.LAST) := buf;
              else
                -- if object is unknown or does not exist add new element of type null
                buf := null;
                --dbms_output.put_line('res='||buf);
                sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
            end case;
          end loop;
          sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := value_array;
        when 3 then -- 'string';
          buf := json_val.get_string();
          --dbms_output.put_line('res='||buf);
          sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
        when 4 then -- 'number';
          buf := to_char(json_val.get_number());
          --dbms_output.put_line('res='||buf);
          sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
        when 5 then -- 'bool';
          buf := case json_val.get_bool() when true then 'true' when false then 'false' end;
          --dbms_output.put_line('res='||buf);
          sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
        when 6 then -- 'null';
          buf := null;
          --dbms_output.put_line('res='||buf);
          sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
        else
          -- if object is unknown or does not exist add new element of type null
          buf := null;
          --dbms_output.put_line('res='||buf);
          sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
      end case;
    end loop;
    
    --dbms_output.put_line('initialize row indexes');
    sctx.row_inds.delete;
    --for i in data_tab.FIRST .. data_tab.LAST loop
    for i in paths.FIRST .. paths.LAST loop
      sctx.row_inds.extend();
      sctx.row_inds(sctx.row_inds.LAST) := 1;
    end loop;
    
    return odciconst.success;
  end;
  
  member function ODCITableFetch(self in out pljson_table_impl, nrows in number, outset out anydataset) return number is
    --data_row pljson_varray := pljson_varray();
    --type index_array is table of number;
    --row_inds index_array := index_array();
    j number;
    num_rows number := 0;
  begin
    --dbms_output.put_line('>>Fetch');
    
    anydataset.begincreate(dbms_types.typecode_object, self.ret_type, outset);
    
    /* iterative cartesian product algorithm */
    <<main_loop>>
    while True loop
      exit when num_rows = nrows or row_inds(1) = 0;
      --data_row.delete;
      outset.addinstance;
      outset.piecewise();
      --dbms_output.put_line('put one row piece');
      for i in data_tab.FIRST .. data_tab.LAST loop
        --data_row.extend();
        --data_row(data_row.LAST) := data_tab(i)(row_inds(i));
        --dbms_output.put_line('json_'||ltrim(to_char(i)));
        --dbms_output.put_line('['||ltrim(to_char(row_inds(i)))||']');
        --dbms_output.put_line('='||data_tab(i)(row_inds(i)));
        outset.setvarchar2(data_tab(i)(row_inds(i)));
      end loop;
      --pipe row(data_row);
      num_rows := num_rows + 1;
      
      --dbms_output.put_line('adjust row indexes');
      j := row_inds.COUNT;
      <<index_loop>>
      while True loop
        row_inds(j) := row_inds(j) + 1;
        if row_inds(j) <= data_tab(j).COUNT then
          exit index_loop;
        end if;
        row_inds(j) := 1;
        j := j - 1;
        if j < 1 then
          row_inds(1) := 0; -- hack to indicate end of all fetches
          exit main_loop;
        end if;
      end loop;
    end loop;
    
    /* check for possible bug if by chance no new rows produced */
    --dbms_output.put_line('finish, num_rows='||ltrim(to_char(num_rows)));
    outset.endcreate;
    
    return odciconst.success;
  end;
  
  member function ODCITableClose(self in pljson_table_impl) return number is
  begin
    --dbms_output.put_line('>>Close');
    return odciconst.success;
  end;

end;
/