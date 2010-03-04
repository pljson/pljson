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
  
  --JSON Path getters
  function get_json_value(obj json, v_path varchar2) return json_value;
  function get_string(obj json, path varchar2) return varchar2;
  function get_number(obj json, path varchar2) return number;
  function get_json(obj json, path varchar2) return json;
  function get_json_list(obj json, path varchar2) return json_list;
  function get_bool(obj json, path varchar2) return boolean;

  --JSON Path putters
  procedure put(obj in out nocopy json, path varchar2, elem varchar2);
  procedure put(obj in out nocopy json, path varchar2, elem number);
  procedure put(obj in out nocopy json, path varchar2, elem json);
  procedure put(obj in out nocopy json, path varchar2, elem json_list);
  procedure put(obj in out nocopy json, path varchar2, elem boolean);
  procedure put(obj in out nocopy json, path varchar2, elem json_value);

  procedure remove(obj in out nocopy json, path varchar2);
  
  --Pretty print with JSON Path
  function pp(obj json, v_path varchar2) return varchar2; 
  procedure pp(obj json, v_path varchar2); --using dbms_output.put_line
  procedure pp_htp(obj json, v_path varchar2); --using htp.print

  --extra function checks if number has no fraction
  function is_integer(v json_value) return boolean;
  
  format_string varchar2(30) := 'yyyy-mm-dd hh24:mi:ss';
  --extension enables json to store dates without comprimising the implementation
  function to_json_value(d date) return json_value;
  --notice that a date type in json is also a varchar2
  function is_date(v json_value) return boolean;
  --convertion is needed to extract dates 
  --(json_ext.to_date will not work along with the normal to_date function - any fix will be appreciated)
  function to_date2(v json_value) return date;
  --JSON Path with date
  function get_date(obj json, path varchar2) return date;
  procedure put(obj in out nocopy json, path varchar2, elem date);
  
  --experimental support of binary data with base64
  function base64(binarydata blob) return json_list;
  function base64(l json_list) return blob;
  
end json_ext;
/
create or replace package body json_ext as
  
  --extra function checks if number has no fraction
  function is_integer(v json_value) return boolean as
    myint number(38); --the oracle way to specify an integer
  begin
    if(v.is_number) then
      myint := v.get_number;
      return (myint = v.get_number); --no rounding errors?
    else
      return false;
    end if;
  end;
  
  --extension enables json to store dates without comprimising the implementation
  function to_json_value(d date) return json_value as
  begin
    return json_value(to_char(d, format_string));
  end;
  
  --notice that a date type in json is also a varchar2
  function is_date(v json_value) return boolean as
    temp date;
  begin
    temp := json_ext.to_date2(v);
    return true;
  exception
    when others then 
      return false;
  end;
  
  --convertion is needed to extract dates
  function to_date2(v json_value) return date as
  begin
    if(v.is_string) then
      return to_date(v.get_string, format_string);
    else
      raise_application_error(-20110, 'Anydata did not contain a date-value');
    end if;
  exception
    when others then
      raise_application_error(-20110, 'Anydata did not contain a date on the format: '||format_string);
  end;

  --JSON Path getters
  function get_json_value(obj json, v_path varchar2) return json_value as
    path varchar2(32767);
    t_obj json;
    returndata json_value := null;
    
    s_indx number := 1;
    e_indx number := 1;
    subpath varchar2(32676);

    function get_data(obj json, subpath varchar2) return json_value as
      s_bracket number;
      e_bracket number;
      list_indx number;
      innerlist json_list;
      list_elem json_value;
    begin
      s_bracket := instr(subpath,'[');
      e_bracket := instr(subpath,']');
      if(s_bracket != 0) then
        innerlist := json_list(obj.get(substr(subpath, 1, s_bracket-1)));
        while (s_bracket != 0) loop
          list_indx := to_number(substr(subpath, s_bracket+1, e_bracket-s_bracket-1));
          list_elem := innerlist.get_elem(list_indx);
          s_bracket := instr(subpath,'[', e_bracket);
          e_bracket := instr(subpath,']', s_bracket);
          if(s_bracket != 0) then
            innerlist := json_list(list_elem);
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
    if(v_path is null) then return obj.to_json_value; end if;
    path := regexp_replace(v_path, '(\s)*\[(\s)*"', '.');
    path := regexp_replace(path, '"(\s)*\](\s)*', '');
    if(substr(path, 1, 1) = '.') then path := substr(path, 2); end if;
    while (e_indx != 0) loop
      e_indx := instr(path,'.',s_indx,1);
      if(e_indx = 0) then subpath := substr(path, s_indx);
      else subpath := substr(path, s_indx, e_indx-s_indx); end if;
--      dbms_output.put_line(s_indx||' to '||e_indx||' : '||subpath);
      s_indx := e_indx+1;  
      returndata := get_data(t_obj, subpath);
      if(e_indx != 0) then
        t_obj := json(returndata);
      end if;
    end loop;
   
    return returndata;
  exception
    when others then return null;
  end;

  function get_string(obj json, path varchar2) return varchar2 as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path);
    if(temp is null or not temp.is_string) then 
      return null; 
    else 
      return temp.get_string;
    end if;
  end;
  
  function get_number(obj json, path varchar2) return number as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path);
    if(temp is null or not temp.is_number) then 
      return null; 
    else 
      return temp.get_number;
    end if;
  end;
  
  function get_json(obj json, path varchar2) return json as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path);
    if(temp is null or not temp.is_object) then 
      return null; 
    else 
      return json(temp);
    end if;
  end;
  
  function get_json_list(obj json, path varchar2) return json_list as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path);
    if(temp is null or not temp.is_array) then 
      return null; 
    else 
      return json_list(temp);
    end if;
  end;
  
  function get_bool(obj json, path varchar2) return boolean as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path);
    if(temp is null or not temp.is_bool) then 
      return null; 
    else 
      return temp.get_bool;
    end if;
  end;
  
  function get_date(obj json, path varchar2) return date as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path);
    if(temp is null or not is_date(temp)) then 
      return null; 
    else 
      return json_ext.to_date2(temp);
    end if;
  end;
  
  /* JSON Path putter internal function */
  /* I know the code is crap - feel free to rewrite it */ 
  procedure put_internal(obj in out nocopy json, v_path varchar2, elem json_value, del boolean default false) as
    path varchar2(32767);
    -- variables 
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
    -- creates a simple json with nulls 
    function fix_indxs(node json_value, indxs indekses, indx number) return json_value as
      j_node json;
      j_list json_list;
      num number;
      savename varchar2(4000);
    begin
      if(indxs.count < indx) then return node; end if;
      if(node.is_object) then
--        dbms_output.put_line('A');
--        node.print;
        j_node := json(node);
        savename := j_node.json_data(1).mapname;
--        dbms_output.put_line('SN'||savename);
        j_node.json_data(1) := fix_indxs(j_node.json_data(1), indxs, indx);
--        dbms_output.put_line('B');
--        j_node.print;
        j_node.json_data(1).mapname := savename;
        j_node.json_data(1).mapindx := 1;
--        dbms_output.put_line('C');
--        j_node.print;
        return j_node.to_json_value;
      elsif(node.is_array) then
        j_list := json_list(node);
        num := indxs(indx);
        for i in 1 .. (num-1) loop
          j_list.add_elem(json_value.makenull, 1);
        end loop;
        j_list.list_data(num) := fix_indxs(j_list.list_data(num), indxs, indx+1);
        return j_list.to_json_value;
      else
        dbms_output.put_line('Should never come here!');
        null;
      end if;
    end;
    
    -- Join the data 
    function join_data(o_node json_value, n_node json_value, levels number) return json_value as
      o_obj json; o_list json_list;
      n_obj json; n_list json_list;
      savename varchar2(4000);
    begin
      -- code used for remove start
      if(levels = 1 and v_del = true) then
        --dbms_output.put_line('delete here');
        if(o_node.is_object) then
          o_obj := json(o_node);   
          n_obj := json(n_node);   
          o_obj.remove(n_obj.json_data(1).mapname);
          return o_obj.to_json_value;
        elsif(o_node.is_array) then
          o_list := json_list(o_node);
          n_list := json_list(n_node);
          o_list.remove_elem(n_list.count);
          return o_list.to_json_value;
        else 
          dbms_output.put_line('error here');
          return o_node;
        end if;  
      -- code used for remove end 
      elsif(o_node.typeval = n_node.typeval and levels > 0) then
        if(n_node.is_object) then
          o_obj := json(o_node);   
          n_obj := json(n_node);   
--          dbms_output.put_line('Here');
          savename := n_obj.json_data(1).mapname;
          if(o_obj.exist(n_obj.json_data(1).mapname)) then
            --join the subtrees
  --          dbms_output.put_line('SN'||savename);
            n_obj.json_data(1) := join_data(o_obj.get(n_obj.json_data(1).mapname), 
                                                        n_obj.json_data(1), levels-1);
          end if;
          n_obj.json_data(1).mapname := savename;                                                        
          n_obj.json_data(1).mapindx := 1;
            --add the new tree
          --dbms_output.put_line('putting in tree '||n_obj.json_data(1).mapname);
--          dbms_output.put_line('aname '||savename);
--          n_obj.json_data(1).print;
--          o_obj.print;
--          dbms_output.put_line('adata '||n_obj.json_data(1).to_char(false));
          o_obj.put(n_obj.json_data(1).mapname, n_obj.json_data(1));
          
--          dbms_output.put_line('b '||savename);
          return o_obj.to_json_value;
        elsif(n_node.is_array) then
          o_list := json_list(o_node);
          n_list := json_list(n_node);
                  
          if(n_list.count > o_list.count) then
            for i in o_list.count+1 .. n_list.count loop
              o_list.add_elem(n_list.get_elem(i));
            end loop;
          else 
            o_list.list_data(n_list.count) := join_data(o_list.list_data(n_list.count),
                                                                     n_list.list_data(n_list.count), levels-1);
          end if;
          --return the modified list;
          return o_list.to_json_value;
        else 
          return n_node; --simple node
        end if;
      else
        return n_node;
      end if;
    end join_data;
  
    -- fix then join 
    function join_json_value(o1 json_value, o2 json_value, indxs indekses, levels number) return json_value as
      temp json_value;
    begin
      temp := fix_indxs(o2, indxs, 1);
      if(o1 is null or o1.typeval != o2.typeval) then
        --replace o1 with o2
--        dbms_output.put_line('Temp o1 null');
--        temp.print;
        return temp;
      else 
--        dbms_output.put_line('Temp before');
--        temp.print;
        temp := join_data(o1, temp, levels); 
--        dbms_output.put_line('Temp after');
--        temp.print;
        return temp;
      end if;
    end;
    
    -- process the two jsons 
    function join_jsons(obj in out nocopy json, build json, indxs indekses, levels number) return json as
      m_name varchar2(4000);
      edit json_value;
    begin
      m_name := build.json_data(1).mapname;
      edit := join_json_value(obj.get(m_name), build.get(m_name), indxs, levels);
      if(v_del = true and levels = 0) then
        obj.remove(m_name);
      else 
        obj.put(m_name, edit);        
      end if;
      return obj;
    end;
  
  begin
    if(substr(v_path, 1, 1) = '.') then raise_application_error(-20110, 'Path error: . not a valid start'); end if;  
    if(v_path is null) then raise_application_error(-20110, 'Path error: no path'); end if;  
    path := regexp_replace(v_path, '(\s)*\[(\s)*"', '.');
    path := regexp_replace(path, '"(\s)*\](\s)*', '');
    if(substr(path, 1, 1) = '.') then path := substr(path, 2); end if;
    --dbms_output.put_line('PATH: '||path);
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
    if(elem.is_string) then s_build := s_build || '"'; e_build := '"'||e_build; end if;
    str := s_build|| json_printer.pretty_print_any(elem) ||e_build;
    --dbms_output.put_line(str);
    begin
      build := json(str);
      --build.print;
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

--    dbms_output.put_line('obj bef');
--    obj.print(false);
    obj := join_jsons(obj, build, indxs, levels);
--    dbms_output.put_line('obj aft');
--    obj.print(false);
  end put_internal;
  /* JSON Path putter internal end */  

  /* JSON Path putters */  
  procedure put(obj in out nocopy json, path varchar2, elem varchar2) as
  begin 
    put_internal(obj, path, json_value(elem));
  end;
  
  procedure put(obj in out nocopy json, path varchar2, elem number) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, json_value(elem));
  end;

  procedure put(obj in out nocopy json, path varchar2, elem json) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, elem.to_json_value);
  end;

  procedure put(obj in out nocopy json, path varchar2, elem json_list) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, elem.to_json_value);
  end;

  procedure put(obj in out nocopy json, path varchar2, elem boolean) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, json_value(elem));
  end;

  procedure put(obj in out nocopy json, path varchar2, elem json_value) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, json_value);
  end;

  procedure put(obj in out nocopy json, path varchar2, elem date) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, json_ext.to_json_value(elem));
  end;

  procedure remove(obj in out nocopy json, path varchar2) as
  begin
    if(json_ext.get_json_value(obj,path) is not null) then
      json_ext.put_internal(obj,path,json_value('delete me'), true);
    end if;
  end remove;

    --Pretty print with JSON Path
  function pp(obj json, v_path varchar2) return varchar2 as
    json_part json_value;
  begin
    json_part := json_ext.get_json_value(obj, v_path);
    if(json_part is null) then 
      return ''; 
    else 
      return json_printer.pretty_print_any(json_part); 
    end if;
  end pp;
  
  procedure pp(obj json, v_path varchar2) as --using dbms_output.put_line
  begin
    dbms_output.put_line(pp(obj, v_path));
  end pp;
  
  -- spaces = false!
  procedure pp_htp(obj json, v_path varchar2) as --using htp.print
    json_part json_value;
  begin
    json_part := json_ext.get_json_value(obj, v_path);
    if(json_part is null) then htp.print; else 
      htp.print(json_printer.pretty_print_any(json_part, false)); 
    end if;
  end pp_htp;
  
  function base64(binarydata blob) return json_list as
    obj json_list := json_list();
    c clob := empty_clob();
    benc blob;    
  
    v_blob_offset NUMBER := 1;
    v_clob_offset NUMBER := 1;
    v_lang_context NUMBER := DBMS_LOB.DEFAULT_LANG_CTX;
    v_warning NUMBER;
    v_amount PLS_INTEGER;
--    temp varchar2(32767);

    FUNCTION encodeBlob2Base64(pBlobIn IN BLOB) RETURN BLOB IS
      vAmount NUMBER := 45;
      vBlobEnc BLOB := empty_blob();
      vBlobEncLen NUMBER := 0;
      vBlobInLen NUMBER := 0;
      vBuffer RAW(45);
      vOffset NUMBER := 1;
    BEGIN
      dbms_output.put_line('Start base64 encoding.');
      vBlobInLen := dbms_lob.getlength(pBlobIn);
      dbms_output.put_line('<BlobInLength>' || vBlobInLen);
      dbms_lob.createtemporary(vBlobEnc, TRUE);
      LOOP
        IF vOffset >= vBlobInLen THEN
          EXIT;
        END IF;
        dbms_lob.read(pBlobIn, vAmount, vOffset, vBuffer);
        BEGIN
          dbms_lob.append(vBlobEnc, utl_encode.base64_encode(vBuffer));
        EXCEPTION
          WHEN OTHERS THEN
          dbms_output.put_line('<vAmount>' || vAmount || '<vOffset>' || vOffset || '<vBuffer>' || vBuffer);
          dbms_output.put_line('ERROR IN append: ' || SQLERRM);
          RAISE;
        END;
        vOffset := vOffset + vAmount;
      END LOOP;
      vBlobEncLen := dbms_lob.getlength(vBlobEnc);
      dbms_output.put_line('<BlobEncLength>' || vBlobEncLen);
      dbms_output.put_line('Finshed base64 encoding.');
      RETURN vBlobEnc;
    END encodeBlob2Base64;
  begin
    benc := encodeBlob2Base64(binarydata);
    dbms_lob.createtemporary(c, TRUE);
    v_amount := DBMS_LOB.GETLENGTH(benc);
    DBMS_LOB.CONVERTTOCLOB(c, benc, v_amount, v_clob_offset, v_blob_offset, 1, v_lang_context, v_warning);
  
    v_amount := DBMS_LOB.GETLENGTH(c);
    v_clob_offset := 1;
    --dbms_output.put_line('V amount: '||v_amount);
    while(v_clob_offset < v_amount) loop
      --dbms_output.put_line(v_offset);
      --temp := ;
      --dbms_output.put_line('size: '||length(temp));
      obj.add_elem(dbms_lob.SUBSTR(c, 4000,v_clob_offset));
      v_clob_offset := v_clob_offset + 4000;
    end loop;
    dbms_lob.freetemporary(benc);
    dbms_lob.freetemporary(c);
  --dbms_output.put_line(obj.count);
  --dbms_output.put_line(obj.get_last().to_char);
    return obj;
  
  end base64;


  function base64(l json_list) return blob as
    c clob := empty_clob();
    b blob := empty_blob();
    bret blob;
  
    v_blob_offset NUMBER := 1;
    v_clob_offset NUMBER := 1;
    v_lang_context NUMBER := DBMS_LOB.DEFAULT_LANG_CTX;
    v_warning NUMBER;
    v_amount PLS_INTEGER;

    FUNCTION decodeBase642Blob(pBlobIn IN BLOB) RETURN BLOB IS
      vAmount NUMBER := 256;--32;
      vBlobDec BLOB := empty_blob();
      vBlobDecLen NUMBER := 0;
      vBlobInLen NUMBER := 0;
      vBuffer RAW(256);--32);
      vOffset NUMBER := 1;
    BEGIN
      dbms_output.put_line('Start base64 decoding.');
      vBlobInLen := dbms_lob.getlength(pBlobIn);
      dbms_output.put_line('<BlobInLength>' || vBlobInLen);
      dbms_lob.createtemporary(vBlobDec, TRUE);
      LOOP
        IF vOffset >= vBlobInLen THEN
          EXIT;
        END IF;
        dbms_lob.read(pBlobIn, vAmount, vOffset, vBuffer);
        BEGIN
          dbms_lob.append(vBlobDec, utl_encode.base64_decode(vBuffer));
        EXCEPTION
          WHEN OTHERS THEN
          dbms_output.put_line('<vAmount>' || vAmount || '<vOffset>' || vOffset || '<vBuffer>' || vBuffer);
          dbms_output.put_line('ERROR IN append: ' || SQLERRM);
          RAISE;
        END;
        vOffset := vOffset + vAmount;
      END LOOP;
      vBlobDecLen := dbms_lob.getlength(vBlobDec);
      dbms_output.put_line('<BlobDecLength>' || vBlobDecLen);
      dbms_output.put_line('Finshed base64 decoding.');
      RETURN vBlobDec;
    END decodeBase642Blob;
  begin
    dbms_lob.createtemporary(c, TRUE);
    for i in 1 .. l.count loop
      dbms_lob.append(c, l.get_elem(i).to_char(false));
    end loop;
    v_amount := DBMS_LOB.GETLENGTH(c);
--    dbms_output.put_line('L C'||v_amount);
    
    dbms_lob.createtemporary(b, TRUE);
    DBMS_LOB.CONVERTTOBLOB(b, c, v_amount, v_clob_offset, v_blob_offset, 1, v_lang_context, v_warning);
    dbms_lob.freetemporary(c);
    v_amount := DBMS_LOB.GETLENGTH(b);
--    dbms_output.put_line('L B'||v_amount);
    
    bret := decodeBase642Blob(b); 
    dbms_lob.freetemporary(b);
    return bret;
  
  end base64;


end json_ext;
/
