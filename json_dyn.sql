create or replace package json_dyn as
 /*
  Copyright (c) 2010 Jonas Krogsboell

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

  null_as_empty_string   boolean := true;  --varchar2
  include_dates          boolean := true;  --date
  
  /* list with objects */
  function executeList(stmt varchar2) return json_list;
  
  /* object with lists */
  function executeObject(stmt varchar2) return json;

end json_dyn;
/

create or replace package body json_dyn as

  /* list with objects */
  function executeList(stmt varchar2) return json_list as
    l_cur number;
    l_dtbl dbms_sql.desc_tab;
    l_cnt number;
    l_status number;
    l_val varchar2(4000);
    outer_list json_list := json_list();
    inner_obj json;
    conv number;
    read_date date;
  begin
    l_cur := dbms_sql.open_cursor;
    dbms_sql.parse(l_cur, stmt, dbms_sql.native);
    dbms_sql.describe_columns(l_cur, l_cnt, l_dtbl);
    for i in 1..l_cnt loop
      dbms_sql.define_column(l_cur,i,l_val,4000);
    end loop;
    l_status := dbms_sql.execute(l_cur);
    
    --loop through rows 
    while ( dbms_sql.fetch_rows(l_cur) > 0 ) loop
      inner_obj := json(); --init for each row
      --loop through columns
      for i in 1..l_cnt loop
        case l_dtbl(i).col_type
        --handling string types
        when 1 then -- varchar2
          dbms_sql.column_value(l_cur,i,l_val);
          if(l_val is null) then
            if(null_as_empty_string) then 
              inner_obj.put(l_dtbl(i).col_name, ''); --treatet as emptystring?
            else 
              inner_obj.put(l_dtbl(i).col_name, json_value.makenull); --null
            end if;
          else
            declare 
              v json_value;
            begin
              v := json_parser.parse_any('"'||l_val||'"');
              inner_obj.put(l_dtbl(i).col_name, v); --null
            exception when others then
              inner_obj.put(l_dtbl(i).col_name, json_value.makenull); --null
            end;
          end if;
          --dbms_output.put_line(l_dtbl(i).col_name||' --> '||l_val||'varchar2' ||l_dtbl(i).col_type);
        --handling number types
        when 2 then -- number
          dbms_sql.column_value(l_cur,i,l_val);
          conv := l_val;
          inner_obj.put(l_dtbl(i).col_name, conv);
          -- dbms_output.put_line(l_dtbl(i).col_name||' --> '||l_val||'number ' ||l_dtbl(i).col_type);
        when 12 then -- date
          if(include_dates) then
            dbms_sql.column_value(l_cur,i,l_val);
            read_date := l_val;
            inner_obj.put(l_dtbl(i).col_name, json_ext.to_json_value(read_date));
          end if;
          --dbms_output.put_line(l_dtbl(i).col_name||' --> '||l_val||'date ' ||l_dtbl(i).col_type);
        else null; --discard other types
        end case;
      end loop;
      outer_list.add_elem(inner_obj.to_json_value);
    end loop;
    dbms_sql.close_cursor(l_cur);
    return outer_list;
  end executeList;

  /* object with lists */
  function executeObject(stmt varchar2) return json as
    l_cur number;
    l_dtbl dbms_sql.desc_tab;
    l_cnt number;
    l_status number;
    l_val varchar2(4000);
    inner_list_names json_list := json_list();
    inner_list_data json_list := json_list();
    data_list json_list;
    outer_obj json := json();
    conv number;
    read_date date;
  begin
    l_cur := dbms_sql.open_cursor;
    dbms_sql.parse(l_cur, stmt, dbms_sql.native);
    dbms_sql.describe_columns(l_cur, l_cnt, l_dtbl);
    for i in 1..l_cnt loop
      dbms_sql.define_column(l_cur,i,l_val,4000);
    end loop;
    l_status := dbms_sql.execute(l_cur);
    
    --build up name_list
    for i in 1..l_cnt loop
      case l_dtbl(i).col_type
        when 1 then inner_list_names.add_elem(l_dtbl(i).col_name);
        when 2 then inner_list_names.add_elem(l_dtbl(i).col_name);
        when 12 then if(include_dates) then inner_list_names.add_elem(l_dtbl(i).col_name); end if;
        else null;
      end case;
    end loop;

    --loop through rows 
    while ( dbms_sql.fetch_rows(l_cur) > 0 ) loop
      data_list := json_list();
      --loop through columns
      for i in 1..l_cnt loop
        case l_dtbl(i).col_type
        --handling string types
        when 1 then -- varchar2
          dbms_sql.column_value(l_cur,i,l_val);
          if(l_val is null) then
            if(null_as_empty_string) then 
              data_list.add_elem(''); --treatet as emptystring?
            else 
              data_list.add_elem(json_value.makenull); --null
            end if;
          else
            declare 
              v json_value;
            begin
              v := json_parser.parse_any('"'||l_val||'"');
              data_list.add_elem(v); --null
            exception when others then
              data_list.add_elem(json_value.makenull); --null
            end;
          end if;
          --dbms_output.put_line(l_dtbl(i).col_name||' --> '||l_val||'varchar2' ||l_dtbl(i).col_type);
        --handling number types
        when 2 then -- number
          dbms_sql.column_value(l_cur,i,l_val);
          conv := l_val;
          data_list.add_elem(conv);
          -- dbms_output.put_line(l_dtbl(i).col_name||' --> '||l_val||'number ' ||l_dtbl(i).col_type);
        when 12 then -- date
          if(include_dates) then
            dbms_sql.column_value(l_cur,i,l_val);
            read_date := l_val;
            data_list.add_elem(json_ext.to_json_value(read_date));
          end if;
          --dbms_output.put_line(l_dtbl(i).col_name||' --> '||l_val||'date ' ||l_dtbl(i).col_type);
        else null; --discard other types
        end case;
      end loop;
      inner_list_data.add_elem(data_list);
    end loop;
    
    outer_obj.put('names', inner_list_names.to_json_value);
    outer_obj.put('data', inner_list_data.to_json_value);
    dbms_sql.close_cursor(l_cur);
    return outer_obj;
  end executeObject;

end json_dyn;
/