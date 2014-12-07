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
  function parsePath(json_path varchar2, base number default 1) return json_list;
  
  --JSON Path getters
  function get_json_value(obj json, v_path varchar2, base number default 1) return json_value;
  function get_string(obj json, path varchar2,       base number default 1) return varchar2;
  function get_number(obj json, path varchar2,       base number default 1) return number;
  function get_json(obj json, path varchar2,         base number default 1) return json;
  function get_json_list(obj json, path varchar2,    base number default 1) return json_list;
  function get_bool(obj json, path varchar2,         base number default 1) return boolean;

  --JSON Path putters
  procedure put(obj in out nocopy json, path varchar2, elem varchar2,   base number default 1);
  procedure put(obj in out nocopy json, path varchar2, elem number,     base number default 1);
  procedure put(obj in out nocopy json, path varchar2, elem json,       base number default 1);
  procedure put(obj in out nocopy json, path varchar2, elem json_list,  base number default 1);
  procedure put(obj in out nocopy json, path varchar2, elem boolean,    base number default 1);
  procedure put(obj in out nocopy json, path varchar2, elem json_value, base number default 1);

  procedure remove(obj in out nocopy json, path varchar2, base number default 1);
  
  --Pretty print with JSON Path - obsolete in 0.9.4 - obj.path(v_path).(to_char,print,htp)
  function pp(obj json, v_path varchar2) return varchar2; 
  procedure pp(obj json, v_path varchar2); --using dbms_output.put_line
  procedure pp_htp(obj json, v_path varchar2); --using htp.print

  --extra function checks if number has no fraction
  function is_integer(v json_value) return boolean;
  
  format_string varchar2(30 char) := 'yyyy-mm-dd hh24:mi:ss';
  --extension enables json to store dates without comprimising the implementation
  function to_json_value(d date) return json_value;
  --notice that a date type in json is also a varchar2
  function is_date(v json_value) return boolean;
  --convertion is needed to extract dates 
  --(json_ext.to_date will not work along with the normal to_date function - any fix will be appreciated)
  function to_date2(v json_value) return date;
  --JSON Path with date
  function get_date(obj json, path varchar2, base number default 1) return date;
  procedure put(obj in out nocopy json, path varchar2, elem date, base number default 1);
  
  --experimental support of binary data with base64
  function base64(binarydata blob) return json_list;
  function base64(l json_list) return blob;

  function encode(binarydata blob) return json_value;
  function decode(v json_value) return blob;
  
end json_ext;
/
create or replace package body json_ext as
  scanner_exception exception;
  pragma exception_init(scanner_exception, -20100);
  parser_exception exception;
  pragma exception_init(parser_exception, -20101);
  jext_exception exception;
  pragma exception_init(jext_exception, -20110);
  
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
  
  --Json Path parser
  function parsePath(json_path varchar2, base number default 1) return json_list as
    build_path varchar2(32767) := '[';
    buf varchar2(4);
    endstring varchar2(1);
    indx number := 1;
    ret json_list;
    
    procedure next_char as
    begin
      if(indx <= length(json_path)) then
        buf := substr(json_path, indx, 1);
        indx := indx + 1;
      else 
        buf := null;
      end if;
    end;  
    --skip ws
    procedure skipws as begin while(buf in (chr(9),chr(10),chr(13),' ')) loop next_char; end loop; end;
  
  begin
    next_char();
    while(buf is not null) loop
      if(buf = '.') then
        next_char();
        if(buf is null) then raise_application_error(-20110, 'JSON Path parse error: . is not a valid json_path end'); end if;
        if(not regexp_like(buf, '^[[:alnum:]\_ ]+', 'c') ) then
          raise_application_error(-20110, 'JSON Path parse error: alpha-numeric character or space expected at position '||indx);
        end if;
        
        if(build_path != '[') then build_path := build_path || ','; end if;
        build_path := build_path || '"';
        while(regexp_like(buf, '^[[:alnum:]\_ ]+', 'c') ) loop
          build_path := build_path || buf;
          next_char();
        end loop;
        build_path := build_path || '"';
      elsif(buf = '[') then
        next_char();
        skipws();
        if(buf is null) then raise_application_error(-20110, 'JSON Path parse error: [ is not a valid json_path end'); end if;
        if(buf in ('1','2','3','4','5','6','7','8','9') or (buf = '0' and base = 0)) then
          if(build_path != '[') then build_path := build_path || ','; end if;
          while(buf in ('0','1','2','3','4','5','6','7','8','9')) loop
            build_path := build_path || buf;
            next_char();
          end loop;      
        elsif (regexp_like(buf, '^(\"|\'')', 'c')) then
          endstring := buf;
          if(build_path != '[') then build_path := build_path || ','; end if;
          build_path := build_path || '"';
          next_char();
          if(buf is null) then raise_application_error(-20110, 'JSON Path parse error: premature json_path end'); end if;
          while(buf != endstring) loop
            build_path := build_path || buf;
            next_char();
            if(buf is null) then raise_application_error(-20110, 'JSON Path parse error: premature json_path end'); end if;
            if(buf = '\') then 
              next_char(); 
              build_path := build_path || '\' || buf; 
              next_char(); 
            end if;
          end loop;
          build_path := build_path || '"';
          next_char(); 
        else
          raise_application_error(-20110, 'JSON Path parse error: expected a string or an positive integer at '||indx);
        end if;
        skipws();
        if(buf is null) then raise_application_error(-20110, 'JSON Path parse error: premature json_path end'); end if;
        if(buf != ']') then raise_application_error(-20110, 'JSON Path parse error: no array ending found. found: '|| buf); end if;
        next_char();
        skipws();
      elsif(build_path = '[') then
        if(not regexp_like(buf, '^[[:alnum:]\_ ]+', 'c') ) then
          raise_application_error(-20110, 'JSON Path parse error: alpha-numeric character or space expected at position '||indx);
        end if;
        build_path := build_path || '"';
        while(regexp_like(buf, '^[[:alnum:]\_ ]+', 'c') ) loop
          build_path := build_path || buf;
          next_char();
        end loop;
        build_path := build_path || '"';
      else 
        raise_application_error(-20110, 'JSON Path parse error: expected . or [ found '|| buf || ' at position '|| indx);
      end if;
        
    end loop;
  
    build_path := build_path || ']';
    build_path := replace(replace(replace(replace(replace(build_path, chr(9), '\t'), chr(10), '\n'), chr(13), '\f'), chr(8), '\b'), chr(14), '\r');
    
    ret := json_list(build_path);
    if(base != 1) then
      --fix base 0 to base 1
      declare
        elem json_value;
      begin
        for i in 1 .. ret.count loop
          elem := ret.get(i);
          if(elem.is_number) then
            ret.replace(i,elem.get_number()+1);
          end if;
        end loop;
      end;
    end if;
    
    return ret;
  end parsePath;
    
  --JSON Path getters
  function get_json_value(obj json, v_path varchar2, base number default 1) return json_value as 
    path json_list;
    ret json_value; 
    o json; l json_list;
  begin
    path := parsePath(v_path, base);
    ret := obj.to_json_value;
    if(path.count = 0) then return ret; end if;
    
    for i in 1 .. path.count loop
      if(path.get(i).is_string()) then
        --string fetch only on json
        o := json(ret);
        ret := o.get(path.get(i).get_string());
      else
        --number fetch on json and json_list
        if(ret.is_array()) then
          l := json_list(ret);
          ret := l.get(path.get(i).get_number());
        else 
          o := json(ret);
          l := o.get_values();
          ret := l.get(path.get(i).get_number());
        end if;
      end if;
    end loop;
    
    return ret;
  exception
    when scanner_exception then raise;
    when parser_exception then raise;
    when jext_exception then raise;
    when others then return null;
  end get_json_value;
  
  --JSON Path getters
  function get_string(obj json, path varchar2, base number default 1) return varchar2 as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path, base);
    if(temp is null or not temp.is_string) then 
      return null; 
    else 
      return temp.get_string;
    end if;
  end;
  
  function get_number(obj json, path varchar2, base number default 1) return number as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path, base);
    if(temp is null or not temp.is_number) then 
      return null; 
    else 
      return temp.get_number;
    end if;
  end;
  
  function get_json(obj json, path varchar2, base number default 1) return json as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path, base);
    if(temp is null or not temp.is_object) then 
      return null; 
    else 
      return json(temp);
    end if;
  end;
  
  function get_json_list(obj json, path varchar2, base number default 1) return json_list as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path, base);
    if(temp is null or not temp.is_array) then 
      return null; 
    else 
      return json_list(temp);
    end if;
  end;
  
  function get_bool(obj json, path varchar2, base number default 1) return boolean as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path, base);
    if(temp is null or not temp.is_bool) then 
      return null; 
    else 
      return temp.get_bool;
    end if;
  end;
  
  function get_date(obj json, path varchar2, base number default 1) return date as 
    temp json_value;
  begin 
    temp := get_json_value(obj, path, base);
    if(temp is null or not is_date(temp)) then 
      return null; 
    else 
      return json_ext.to_date2(temp);
    end if;
  end;
  
  /* JSON Path putter internal function */
  procedure put_internal(obj in out nocopy json, v_path varchar2, elem json_value, base number) as
    val json_value := elem;
    path json_list;
    backreference json_list := json_list();
    
    keyval json_value; keynum number; keystring varchar2(4000);
    temp json_value := obj.to_json_value;
    obj_temp  json;
    list_temp json_list;
    inserter json_value;
  begin
    path := json_ext.parsePath(v_path, base);
    if(path.count = 0) then raise_application_error(-20110, 'JSON_EXT put error: cannot put with empty string.'); end if;
  
    --build backreference
    for i in 1 .. path.count loop
      --backreference.print(false);
      keyval := path.get(i);
      if (keyval.is_number()) then
        --nummer index
        keynum := keyval.get_number();
        if((not temp.is_object()) and (not temp.is_array())) then
          if(val is null) then return; end if;
          backreference.remove_last;
          temp := json_list().to_json_value();
          backreference.append(temp);
        end if;
  
        if(temp.is_object()) then 
          obj_temp := json(temp);
          if(obj_temp.count < keynum) then 
            if(val is null) then return; end if;
            raise_application_error(-20110, 'JSON_EXT put error: access object with to few members.'); 
          end if;
          temp := obj_temp.get(keynum);
        else 
          list_temp := json_list(temp);
          if(list_temp.count < keynum) then 
            if(val is null) then return; end if;
            --raise error or quit if val is null
            for i in list_temp.count+1 .. keynum loop
              list_temp.append(json_value.makenull);
            end loop;
            backreference.remove_last;
            backreference.append(list_temp);
          end if;
  
          temp := list_temp.get(keynum);
        end if;
      else 
        --streng index
        keystring := keyval.get_string();
        if(not temp.is_object()) then 
          --backreference.print;
          if(val is null) then return; end if;
          backreference.remove_last;
          temp := json().to_json_value();
          backreference.append(temp);
          --raise_application_error(-20110, 'JSON_ext put error: trying to access a non object with a string.'); 
        end if;
        obj_temp := json(temp);
        temp := obj_temp.get(keystring);
      end if;
  
      if(temp is null) then 
        if(val is null) then return; end if;
        --what to expect?
        keyval := path.get(i+1);
        if(keyval is not null and keyval.is_number()) then
          temp := json_list().to_json_value; 
        else 
          temp := json().to_json_value; 
        end if;
      end if;
      backreference.append(temp);
    end loop;
      
  --  backreference.print(false);
  --  path.print(false);
      
    --use backreference and path together
    inserter := val;  
    for i in reverse 1 .. backreference.count loop
  --    inserter.print(false);
      if( i = 1 ) then
        keyval := path.get(1);
        if(keyval.is_string()) then
          keystring := keyval.get_string();
        else 
          keynum := keyval.get_number();
          declare
            t1 json_value := obj.get(keynum);
          begin
            keystring := t1.mapname;
          end;
        end if;
        if(inserter is null) then obj.remove(keystring); else obj.put(keystring, inserter); end if;
      else
        temp := backreference.get(i-1);
        if(temp.is_object()) then
          keyval := path.get(i);
          obj_temp := json(temp);
          if(keyval.is_string()) then
            keystring := keyval.get_string();
          else 
            keynum := keyval.get_number();
            declare
              t1 json_value := obj_temp.get(keynum);
            begin
              keystring := t1.mapname;
            end;
          end if;
          if(inserter is null) then 
            obj_temp.remove(keystring); 
            if(obj_temp.count > 0) then inserter := obj_temp.to_json_value; end if;
          else 
            obj_temp.put(keystring, inserter);
            inserter := obj_temp.to_json_value; 
          end if;
        else 
          --array only number
          keynum := path.get(i).get_number();
          list_temp := json_list(temp);
          list_temp.remove(keynum);
          if(not inserter is null) then 
            list_temp.append(inserter, keynum);
            inserter := list_temp.to_json_value; 
          else 
            if(list_temp.count > 0) then inserter := list_temp.to_json_value; end if;
          end if; 
        end if;    
      end if;
      
    end loop;

  end put_internal;

  /* JSON Path putters */  
  procedure put(obj in out nocopy json, path varchar2, elem varchar2, base number default 1) as
  begin 
    put_internal(obj, path, json_value(elem), base);
  end;
  
  procedure put(obj in out nocopy json, path varchar2, elem number, base number default 1) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, json_value(elem), base);
  end;

  procedure put(obj in out nocopy json, path varchar2, elem json, base number default 1) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, elem.to_json_value, base);
  end;

  procedure put(obj in out nocopy json, path varchar2, elem json_list, base number default 1) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, elem.to_json_value, base);
  end;

  procedure put(obj in out nocopy json, path varchar2, elem boolean, base number default 1) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, json_value(elem), base);
  end;

  procedure put(obj in out nocopy json, path varchar2, elem json_value, base number default 1) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, elem, base);
  end;

  procedure put(obj in out nocopy json, path varchar2, elem date, base number default 1) as
  begin 
    if(elem is null) then raise_application_error(-20110, 'Cannot put null-value'); end if;
    put_internal(obj, path, json_ext.to_json_value(elem), base);
  end;

  procedure remove(obj in out nocopy json, path varchar2, base number default 1) as
  begin
    json_ext.put_internal(obj,path,null,base);
--    if(json_ext.get_json_value(obj,path) is not null) then
--    end if;
  end remove;

    --Pretty print with JSON Path
  function pp(obj json, v_path varchar2) return varchar2 as
    json_part json_value;
  begin
    json_part := json_ext.get_json_value(obj, v_path);
    if(json_part is null) then 
      return ''; 
    else 
      return json_printer.pretty_print_any(json_part); --escapes a possible internal string
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
--      dbms_output.put_line('Start base64 encoding.');
      vBlobInLen := dbms_lob.getlength(pBlobIn);
--      dbms_output.put_line('<BlobInLength>' || vBlobInLen);
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
--      dbms_output.put_line('<BlobEncLength>' || vBlobEncLen);
--      dbms_output.put_line('Finshed base64 encoding.');
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
      obj.append(dbms_lob.SUBSTR(c, 4000,v_clob_offset));
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
    v_lang_context NUMBER := 0; --DBMS_LOB.DEFAULT_LANG_CTX;
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
--      dbms_output.put_line('Start base64 decoding.');
      vBlobInLen := dbms_lob.getlength(pBlobIn);
--      dbms_output.put_line('<BlobInLength>' || vBlobInLen);
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
--      dbms_output.put_line('<BlobDecLength>' || vBlobDecLen);
--      dbms_output.put_line('Finshed base64 decoding.');
      RETURN vBlobDec;
    END decodeBase642Blob;
  begin
    dbms_lob.createtemporary(c, TRUE);
    for i in 1 .. l.count loop
      dbms_lob.append(c, l.get(i).get_string());
    end loop;
    v_amount := DBMS_LOB.GETLENGTH(c);
--    dbms_output.put_line('L C'||v_amount);
    
    dbms_lob.createtemporary(b, TRUE);
    DBMS_LOB.CONVERTTOBLOB(b, c, dbms_lob.lobmaxsize, v_clob_offset, v_blob_offset, 1, v_lang_context, v_warning);
    dbms_lob.freetemporary(c);
    v_amount := DBMS_LOB.GETLENGTH(b);
--    dbms_output.put_line('L B'||v_amount);
    
    bret := decodeBase642Blob(b); 
    dbms_lob.freetemporary(b);
    return bret;
  
  end base64;

  function encode(binarydata blob) return json_value as
    obj json_value;
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
--      dbms_output.put_line('Start base64 encoding.');
      vBlobInLen := dbms_lob.getlength(pBlobIn);
--      dbms_output.put_line('<BlobInLength>' || vBlobInLen);
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
--      dbms_output.put_line('<BlobEncLength>' || vBlobEncLen);
--      dbms_output.put_line('Finshed base64 encoding.');
      RETURN vBlobEnc;
    END encodeBlob2Base64;
  begin
    benc := encodeBlob2Base64(binarydata);
    dbms_lob.createtemporary(c, TRUE);
    v_amount := DBMS_LOB.GETLENGTH(benc);
    DBMS_LOB.CONVERTTOCLOB(c, benc, v_amount, v_clob_offset, v_blob_offset, 1, v_lang_context, v_warning);
    
    obj := json_value(c);  

    dbms_lob.freetemporary(benc);
    dbms_lob.freetemporary(c);
  --dbms_output.put_line(obj.count);
  --dbms_output.put_line(obj.get_last().to_char);
    return obj;
  
  end encode;
  
  function decode(v json_value) return blob as
    c clob := empty_clob();
    b blob := empty_blob();
    bret blob;
  
    v_blob_offset NUMBER := 1;
    v_clob_offset NUMBER := 1;
    v_lang_context NUMBER := 0; --DBMS_LOB.DEFAULT_LANG_CTX;
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
--      dbms_output.put_line('Start base64 decoding.');
      vBlobInLen := dbms_lob.getlength(pBlobIn);
--      dbms_output.put_line('<BlobInLength>' || vBlobInLen);
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
--      dbms_output.put_line('<BlobDecLength>' || vBlobDecLen);
--      dbms_output.put_line('Finshed base64 decoding.');
      RETURN vBlobDec;
    END decodeBase642Blob;
  begin
    dbms_lob.createtemporary(c, TRUE);
    v.get_string(c);
    v_amount := DBMS_LOB.GETLENGTH(c);
--    dbms_output.put_line('L C'||v_amount);
    
    dbms_lob.createtemporary(b, TRUE);
    DBMS_LOB.CONVERTTOBLOB(b, c, dbms_lob.lobmaxsize, v_clob_offset, v_blob_offset, 1, v_lang_context, v_warning);
    dbms_lob.freetemporary(c);
    v_amount := DBMS_LOB.GETLENGTH(b);
--    dbms_output.put_line('L B'||v_amount);
    
    bret := decodeBase642Blob(b); 
    dbms_lob.freetemporary(b);
    return bret;
  
  end decode;


end json_ext;
/
