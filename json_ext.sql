create or replace package json_ext as
  /*
  Copyright (c) 2009 Jonas Krogsboell

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
  
  /* This package contains extra methods to lookup types and
     an easy way of adding date values in json - without changing the structure */
  
  --removes the need for gettypename hassle on anydata
  function is_varchar2(v anydata) return boolean;
  function is_number(v anydata) return boolean;
  function is_json(v anydata) return boolean;
  function is_json_list(v anydata) return boolean;
  function is_json_bool(v anydata) return boolean;
  function is_json_null(v anydata) return boolean;
  
  --JSON Path getters
  function get_anydata(obj json, path varchar2) return anydata;
  function get_varchar2(obj json, path varchar2) return varchar2;
  function get_number(obj json, path varchar2) return number;
  function get_json(obj json, path varchar2) return json;
  function get_json_list(obj json, path varchar2) return json_list;
  function get_json_bool(obj json, path varchar2) return json_bool;
  function get_json_null(obj json, path varchar2) return json_null;
  --JSON Path putters
  procedure put(obj in out nocopy json, path varchar2, elem varchar2);
  procedure put(obj in out nocopy json, path varchar2, elem number);
  procedure put(obj in out nocopy json, path varchar2, elem json);
  procedure put(obj in out nocopy json, path varchar2, elem json_list);
  procedure put(obj in out nocopy json, path varchar2, elem json_bool);
  procedure put(obj in out nocopy json, path varchar2, elem json_null);

  procedure remove(obj in out nocopy json, path varchar2);
  
  --extra function checks if number has no fraction
  function is_integer(v anydata) return boolean;
  
  format_string varchar2(30) := 'yyyy-mm-dd hh24:mi:ss';
  --extension enables json to store dates without comprimising the implementation
  function to_anydata(d date) return anydata;
  --notice that a date type in json is also a varchar2
  function is_date(v anydata) return boolean;
  --convertion is needed to extract dates 
  --(json_ext.to_date will not work along with the normal to_date function - any fix will be appreciated)
  function to_date2(v anydata) return date;
  --JSON Path with date
  function get_date(obj json, path varchar2) return date;
  procedure put(obj in out nocopy json, path varchar2, elem date);
  
end json_ext;
/
create or replace package body json_ext as
  --removes the need for gettypename hassle on anydata
  function is_varchar2(v anydata) return boolean as
  begin
    return (v.gettypename = 'SYS.VARCHAR2');
  end;
  
  function is_number(v anydata) return boolean as
  begin
    return (v.gettypename = 'SYS.NUMBER');
  end;

  function is_json(v anydata) return boolean as
  begin
    return (v.gettypename = sys_context('userenv', 'current_schema')||'.JSON');
  end;
  
  function is_json_list(v anydata) return boolean as
  begin
    return (v.gettypename = sys_context('userenv', 'current_schema')||'.JSON_LIST');
  end;
  
  function is_json_bool(v anydata) return boolean as
  begin
    return (v.gettypename = sys_context('userenv', 'current_schema')||'.JSON_BOOL');
  end;
  
  function is_json_null(v anydata) return boolean as
  begin
    return (v.gettypename = sys_context('userenv', 'current_schema')||'.JSON_NULL');
  end;
  
  --extra function checks if number has no fraction
  function is_integer(v anydata) return boolean as
    myint number(38); --the oracle way to specify an integer
  begin
    if(is_number(v)) then
      myint := json.to_number(v);
      return (myint = json.to_number(v)); --no rounding errors?
    else
      return false;
    end if;
  end;
  
  --extension enables json to store dates without comprimising the implementation
  function to_anydata(d date) return anydata as
  begin
    return anydata.convertvarchar2(to_char(d, format_string));
  end;
  
  --notice that a date type in json is also a varchar2
  function is_date(v anydata) return boolean as
    temp date;
  begin
    temp := json_ext.to_date2(v);
    return true;
  exception
    when others then 
      return false;
  end;
  
  --convertion is needed to extract dates
  function to_date2(v anydata) return date as
    temp varchar2(30);
  begin
    if(is_varchar2(v)) then
      temp := json.to_varchar2(v);
      return to_date(temp, format_string);
    else
      raise_application_error(-20110, 'Anydata did not contain a date-value');
    end if;
  exception
    when others then
      raise_application_error(-20110, 'Anydata did not contain a date on the format: '||format_string);
  end;

  --JSON Path getters
  function get_anydata(obj json, path varchar2) return anydata as
    t_obj json;
    returndata anydata := null;
    
    s_indx number := 1;
    e_indx number := 1;
    subpath varchar2(32676);

    function get_data(obj json, subpath varchar2) return anydata as
      s_bracket number;
      e_bracket number;
      list_indx number;
      innerlist json_list;
      list_elem anydata;
    begin
      s_bracket := instr(subpath,'[');
      e_bracket := instr(subpath,']');
      if(s_bracket != 0) then
        innerlist := json.to_json_list(obj.get(substr(subpath, 1, s_bracket-1)));
        while (s_bracket != 0) loop
          list_indx := to_number(substr(subpath, s_bracket+1, e_bracket-s_bracket-1));
          list_elem := innerlist.get_elem(list_indx);
          s_bracket := instr(subpath,'[', e_bracket);
          e_bracket := instr(subpath,']', s_bracket);
          if(s_bracket != 0) then
            innerlist := json.to_json_list(list_elem);
          end if;
        end loop;
        return list_elem;
      else 
        return obj.get(subpath);
      end if;
    end get_data;

  begin
    t_obj := obj;
    --until e_indx = 0 read to next .
    if(path is null) then return obj.to_anydata; end if;
    while (e_indx != 0) loop
      e_indx := instr(path,'.',s_indx,1);
      if(e_indx = 0) then subpath := substr(path, s_indx);
      else subpath := substr(path, s_indx, e_indx-s_indx); end if;
--      dbms_output.put_line(s_indx||' to '||e_indx||' : '||subpath);
      s_indx := e_indx+1;  
      returndata := get_data(t_obj, subpath);
      if(e_indx != 0) then
        t_obj := json.to_json(returndata);
      end if;
    end loop;
   
    return returndata;
  exception
    when others then return null;
  end;

  function get_varchar2(obj json, path varchar2) return varchar2 as 
    temp anydata;
  begin 
    temp := get_anydata(obj, path);
    if(temp is null or not is_varchar2(temp)) then 
      return null; 
    else 
      return json.to_varchar2(temp);
    end if;
  end;
  
  function get_number(obj json, path varchar2) return number as 
    temp anydata;
  begin 
    temp := get_anydata(obj, path);
    if(temp is null or not is_number(temp)) then 
      return null; 
    else 
      return json.to_number(temp);
    end if;
  end;
  
  function get_json(obj json, path varchar2) return json as 
    temp anydata;
  begin 
    temp := get_anydata(obj, path);
    if(temp is null or not is_json(temp)) then 
      return null; 
    else 
      return json.to_json(temp);
    end if;
  end;
  
  function get_json_list(obj json, path varchar2) return json_list as 
    temp anydata;
  begin 
    temp := get_anydata(obj, path);
    if(temp is null or not is_json_list(temp)) then 
      return null; 
    else 
      return json.to_json_list(temp);
    end if;
  end;
  
  function get_json_bool(obj json, path varchar2) return json_bool as 
    temp anydata;
  begin 
    temp := get_anydata(obj, path);
    if(temp is null or not is_json_bool(temp)) then 
      return null; 
    else 
      return json.to_json_bool(temp);
    end if;
  end;
  
  function get_json_null(obj json, path varchar2) return json_null as 
    temp anydata;
  begin 
    temp := get_anydata(obj, path);
    if(temp is null or not is_json_null(temp)) then 
      return null; 
    else 
      return json.to_json_null(temp);
    end if;
  end;
  
  function get_date(obj json, path varchar2) return date as 
    temp anydata;
  begin 
    temp := get_anydata(obj, path);
    if(temp is null or not is_date(temp)) then 
      return null; 
    else 
      return json_ext.to_date2(temp);
    end if;
  end;
  
  /* JSON Path putter internal function */
  /* I know the code is crap - feel free to rewrite it */ 
  procedure put_internal(obj in out nocopy json, path varchar2, elem varchar2, del boolean default false) as
    /* variables */
    type indekses is table of number(38) index by pls_integer;
    build json;
    s_build varchar2(32000) := '{"';
    e_build varchar2(32000) := '}';
    tok varchar2(4);
    i number := 1;
    startnum number;
    inarray boolean := false;
    levels number := 0;
    indxs indekses;
    indx_indx number := 1;
    str VARCHAR2(32000);
    dot boolean := false;
    v_del boolean := del;
    /* creates a simple json with nulls */
    function fix_indxs(node anydata, indxs indekses, indx number) return anydata as
      j_node json;
      j_list json_list;
      num number;
    begin
      if(indxs.count < indx) then return node; end if;
      if(json_ext.is_json(node)) then
        j_node := json.to_json(node);
        j_node.json_data(1).member_data := fix_indxs(j_node.json_data(1).member_data, indxs, indx);
        return j_node.to_anydata;
      elsif(json_ext.is_json_list(node)) then
        j_list := json.to_json_list(node);
        num := indxs(indx);
        for i in 1 .. (num-1) loop
          j_list.add_elem(json_null(), 1);
        end loop;
        j_list.list_data(num).element_data := fix_indxs(j_list.list_data(num).element_data, indxs, indx+1);
        return anydata.convertobject(j_list);
      else
        dbms_output.put_line('Should never come here!');
        null;
      end if;
    end;
    
    /* Join the data */
    function join_data(o_node anydata, n_node anydata, levels number) return anydata as
      o_obj json; o_list json_list;
      n_obj json; n_list json_list;
    begin
      /* code used for remove start*/
      if(levels = 1 and v_del = true) then
        --dbms_output.put_line('delete here');
        if(json_ext.is_json(o_node)) then
          o_obj := json.to_json(o_node);   
          n_obj := json.to_json(n_node);   
          o_obj.remove(n_obj.json_data(1).member_name);
          return o_obj.to_anydata;
        elsif(json_ext.is_json_list(o_node)) then
          o_list := json.to_json_list(o_node);
          n_list := json.to_json_list(n_node);
          o_list.remove_elem(n_list.count);
          return anydata.convertobject(o_list);
        else 
          dbms_output.put_line('error here');
          return o_node;
        end if;  
      /* code used for remove end */
      elsif(o_node.gettypename = n_node.gettypename and levels > 0) then
        if(json_ext.is_json(n_node)) then
          o_obj := json.to_json(o_node);   
          n_obj := json.to_json(n_node);   
          if(o_obj.exist(n_obj.json_data(1).member_name)) then
            --join the subtrees
            n_obj.json_data(1).member_data := join_data(o_obj.get(n_obj.json_data(1).member_name), 
                                                        n_obj.json_data(1).member_data, levels-1);
          end if;
            --add the new tree
          --dbms_output.put_line('putting in tree '||n_obj.json_data(1).member_name);
          o_obj.put(n_obj.json_data(1).member_name, n_obj.json_data(1).member_data);
          return o_obj.to_anydata;
        elsif(json_ext.is_json_list(n_node)) then
          o_list := json.to_json_list(o_node);
          n_list := json.to_json_list(n_node);
                  
          if(n_list.count > o_list.count) then
            for i in o_list.count+1 .. n_list.count loop
              o_list.add_elem(n_list.get_elem(i));
            end loop;
          else 
            o_list.list_data(n_list.count).element_data := join_data(o_list.list_data(n_list.count).element_data,
                                                                     n_list.list_data(n_list.count).element_data, levels-1);
          end if;
          --return the modified list;
          return anydata.convertobject(o_list);
        else 
          return n_node; --simple node
        end if;
      else
        return n_node;
      end if;
    end join_data;
  
    /* fix then join */
    function join_anydata(o1 anydata, o2 anydata, indxs indekses, levels number) return anydata as
      temp anydata;
    begin
      temp := fix_indxs(o2, indxs, 1);
      if(o1 is null or o1.gettypename != o2.gettypename) then
        --replace o1 with o2
        return temp;
      else 
        return join_data(o1, temp, levels);
      end if;
    end;
    
    /* process the two jsons */
    function join_jsons(obj in out nocopy json, build json, indxs indekses, levels number) return json as
      m_name varchar2(4000);
      edit anydata;
    begin
      m_name := build.json_data(1).member_name;
      edit := join_anydata(obj.get(m_name), build.get(m_name), indxs, levels);
      if(v_del = true and levels = 0) then
        obj.remove(m_name);
      else 
        obj.put(m_name, edit);
      end if;
      return obj;
    end;
  
  begin
    if(substr(path, 1, 1) = '.') then raise_application_error(-20110, 'Path error: . not a valid start'); end if;  
    if(path is null) then raise_application_error(-20110, 'Path error: no path'); end if;  
    while (i <= length(path)) loop
      tok := substr(path, i, 1);  
      if(tok = '.') then 
        if(dot) then raise_application_error(-20110, 'Path error: .. not allowed'); end if;
        dot := true;
        if(inarray) then 
          s_build := s_build || '{"';
        else 
          s_build := s_build || '":{"';
        end if;
        inarray := false;
        e_build := '}' || e_build;
        levels := levels + 1;
      elsif (tok = '[') then
        dot := false;
        if(inarray) then s_build := s_build || '[';
        else s_build := s_build || '":['; end if;
        e_build := ']' || e_build;
        startnum := i+1;
        i := instr(path, ']', i);
        indxs(indx_indx) := to_number(substr(path, startnum, i-startnum));      
        indx_indx := indx_indx + 1;
        inarray := true;
        levels := levels + 1;
      else 
        dot := false;
        inarray := false;
        s_build := s_build || tok;
      end if;
      i := i + 1;
    end loop;
    if(dot) then raise_application_error(-20110, 'Path error: . not a proper ending'); end if;
    if(not inarray) then s_build := s_build||'":'; end if;
    str := s_build||elem|| e_build;
    --dbms_output.put_line(str);
    begin
      build := json(str);
    exception
      when others then raise_application_error(-20110, 'Path error: consult the documentation');
    end;
    --dbms_output.put_line(levels);
    
    --build is ok - now put the right index on the lists  
    for i in 1 .. indxs.count loop
      if(indxs(i) < 1) then
        raise_application_error(-20110, 'Path error: index should be positive integers');
      end if;
      --dbms_output.put_line(indxs(i));
    end loop;
    
    obj := join_jsons(obj, build, indxs, levels);
  end put_internal;
  /* JSON Path putter internal end */  

  /* JSON Path putters */  
  procedure put(obj in out nocopy json, path varchar2, elem varchar2) as
  begin 
    put_internal(obj, path, '"'||elem||'"');
  end;
  
  procedure put(obj in out nocopy json, path varchar2, elem number) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, to_char(elem, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,'''));
  end;

  procedure put(obj in out nocopy json, path varchar2, elem json) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, elem.to_char);
  end;

  procedure put(obj in out nocopy json, path varchar2, elem json_list) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, elem.to_char);
  end;

  procedure put(obj in out nocopy json, path varchar2, elem json_bool) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, elem.to_char);
  end;

  procedure put(obj in out nocopy json, path varchar2, elem json_null) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, 'null');
  end;

  procedure put(obj in out nocopy json, path varchar2, elem date) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, '"'||json.to_varchar2(json_ext.to_anydata(elem))||'"');
  end;

  procedure remove(obj in out nocopy json, path varchar2) as
  begin
    if(json_ext.get_anydata(obj,path) is not null) then
      json_ext.put_internal(obj,path,'"delete me"', true);
    end if;
  end remove;

end json_ext;
/
