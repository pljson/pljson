create or replace package body pljson_ext as
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

  scanner_exception exception;
  pragma exception_init(scanner_exception, -20100);
  parser_exception exception;
  pragma exception_init(parser_exception, -20101);
  jext_exception exception;
  pragma exception_init(jext_exception, -20110);

  --extra function checks if number has no fraction
  function is_integer(v pljson_element) return boolean as
    num number;
    num_double binary_double;
    int_number number(38); --the oracle way to specify an integer
    int_double binary_double; --the oracle way to specify an integer
  begin
    /*
    if (v.is_number()) then
      myint := v.get_number();
      return (myint = v.get_number()); --no rounding errors?
    else
      return false;
    end if;
    */
    if (not v.is_number()) then
      raise_application_error(-20109, 'not a number-value');
    end if;
    /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
    if (v.is_number_repr_number()) then
      num := v.get_number();
      int_number := trunc(num);
      --dbms_output.put_line('number: ' || num || ' -> ' || int_number);
      return (int_number = num); --no rounding errors?
    elsif (v.is_number_repr_double()) then
      num_double := v.get_double();
      int_double := trunc(num_double);
      --dbms_output.put_line('double: ' || num_double || ' -> ' || int_double);
      return (int_double = num_double); --no rounding errors?
    else
      return false;
    end if;
  end;

  --extension enables json to store dates without compromising the implementation
  function to_json_string(d date) return pljson_string as
  begin
    return pljson_string(to_char(d, format_string));
  end;

  --notice that a date type in json is also a varchar2
  function is_date(v pljson_element) return boolean as
    temp date;
  begin
    temp := pljson_ext.to_date(v);
    return true;
  exception
    when others then
      return false;
  end;

  --conversion is needed to extract dates
  function to_date(v pljson_element) return date as
  begin
    if (v.is_string()) then
      return standard.to_date(v.get_string(), format_string);
    else
      raise_application_error(-20110, 'not a date-value');
    end if;
  exception
    when others then
      raise_application_error(-20110, 'Anydata did not contain a date on the format: '||format_string);
  end;

  -- alias so that old code doesn't break
  function to_date2(v pljson_element) return date as
  begin
    return to_date(v);
  end;

  /*
    assumes single base64 string or broken into equal length lines of max 64 or 76 chars
    (as specified by RFC-1421 or RFC-2045)
    line ending can be CR+NL or NL
  */
  function decodeBase64Clob2Blob(p_clob clob) return blob
  is
    r_blob blob;
    clob_size number;
    pos number;
    c_buf varchar2(32767);
    r_buf raw(32767);
    v_read_size number;
    v_line_size number;
  begin
    dbms_lob.createtemporary(r_blob, false, dbms_lob.call);
    /*
      E.I.Sarmas (github.com/dsnz)   2017-12-07   fix for alignment issues
      assumes single base64 string or broken into equal length lines of max 64 or 76 followed by CR+NL
      as specified by RFC-1421 or RFC-2045 which seem to be the supported ones by Oracle utl_encode
      also support single NL instead of CR+NL !
    */
    clob_size := dbms_lob.getlength(p_clob);
    v_line_size := 64;
    if clob_size >= 65 and dbms_lob.substr(p_clob, 1, 65) = chr(10) then
      v_line_size := 65;
    elsif clob_size >= 66 and dbms_lob.substr(p_clob, 1, 65) = chr(13) then
      v_line_size := 66;
    elsif clob_size >= 77 and dbms_lob.substr(p_clob, 1, 77) = chr(10) then
      v_line_size := 77;
    elsif clob_size >= 78 and dbms_lob.substr(p_clob, 1, 77) = chr(13) then
      v_line_size := 78;
    end if;
    --dbms_output.put_line('decoding in multiples of ' || v_line_size);
    v_read_size := floor(32767/v_line_size)*v_line_size;

    pos := 1;
    while (pos < clob_size) loop
      dbms_lob.read(p_clob, v_read_size, pos, c_buf);
      r_buf := utl_encode.base64_decode(utl_raw.cast_to_raw(c_buf));
      dbms_lob.writeappend(r_blob, utl_raw.length(r_buf), r_buf);
      pos := pos + v_read_size;
    end loop;
    return r_blob;
  end decodeBase64Clob2Blob;

  /*
    encoding in lines of 64 chars ending with CR+NL
  */
  function encodeBase64Blob2Clob(p_blob in  blob) return clob
  is
    r_clob clob;
    /* E.I.Sarmas (github.com/dsnz)   2017-12-07   NOTE: must be multiple of 48 !!! */
    c_step number := 12000;
    c_buf varchar2(32767);
  begin
    if p_blob is not null then
      dbms_lob.createtemporary(r_clob, false, dbms_lob.call);
      for i in 0 .. trunc((dbms_lob.getlength(p_blob) - 1)/c_step) loop
        c_buf := utl_raw.cast_to_varchar2(utl_encode.base64_encode(dbms_lob.substr(p_blob, c_step, i * c_step + 1)));
        /*
          E.I.Sarmas (github.com/dsnz)   2017-12-07   fix for alignment issues
          must output CR+NL at end always, so will align with the following block and can be decoded correctly
          assumes ending in CR+NL
        */
        if substr(c_buf, length(c_buf)) != chr(10) then
          c_buf := c_buf || CHR(13) || CHR(10);
        end if;
        /*
        dbms_output.put_line(
          'l=' || length(c_buf) ||
          ' e=' || ascii(substr(c_buf, length(c_buf) - 1)) || ' ' || ascii(substr(c_buf, length(c_buf)))
        );
        */
        dbms_lob.writeappend(lob_loc => r_clob, amount => length(c_buf), buffer => c_buf);
      end loop;
    end if;
    return r_clob;
  end encodeBase64Blob2Clob;

  --Json Path parser
  /* E.I.Sarmas (github.com/dsnz)   2021-12-01   minor path enhancement and more correct enforcement of paths accepted */
  /*

    updated definition of json path expression syntax accepted by PLJSON

    - a path may optionally begin with $ indicating the JSON object to be matched (root)
      then it's followed by 0 or more path steps
      each step can be an object step or an array step, depending on whether the context item represents a JSON object or a JSON array

    - an object step is a period (.), sometimes read as "dot", followed by an object field name (object property name)
    a field name must start with an uppercase or lowercase letter A to Z and contain only such letters or decimal digits (0-9),
    or else it must be enclosed in double quotation marks (")
    OR
    a left bracket ([) followed by a a field name enclosed in single (') or double (") quotes, followed by a right bracket (])

    - an array step is a left bracket ([) followed by a single numeric index, followed by a right bracket (])
    array indexing is one-based (1, 2, 3,...)

    examples:
      $.store.book[0].title
      $['store']['book'][0]['title']

    in latest update
    - an object step, beginning with dot (.), now accepts name within double quotes (")
    - no longer accepts name beginning with, ending with and including spaces eg. 'd.  a name  .data'

    - in past, after a dot (.) the field name could start with space or number
      and include or end with any number of spaces
      now this is not allowed, unquoted field names must begin with an alpha character or _
      and contain only alphanumeric characters

    - path expressions are now compatible with Oracle Basic SQL/JSON Path Expression Syntax
      but excluding the optional filter expression and the optional function step at end

  */
  function parsePath(json_path varchar2, base number default 1) return pljson_list as
    build_path varchar2(32767) := '[';
    buf varchar2(4);
    endstring varchar2(1);
    indx number := 1;
    ret pljson_list;

    procedure next_char as
    begin
      if (indx <= length(json_path)) then
        buf := substr(json_path, indx, 1);
        indx := indx + 1;
      else
        buf := null;
      end if;
    end;
    --skip ws
    procedure skipws as begin while (buf in (chr(9), chr(10), chr(13), ' ')) loop next_char; end loop; end;

  begin
    -- dbms_output.put_line('parse: ' || json_path);

    -- handle null path and optional '$' at beginning
    if json_path is null or substr(json_path, 1, 1) = '$' then
      indx := 2;
      next_char();
    else
      if substr(json_path, 1, 1) = '[' then
        next_char();
      else
        buf := '.';
      end if;
    end if;

    while (buf is not null) loop
      -- dbms_output.put_line(build_path || ' + ' || buf);

      if (buf = '.') then
        next_char();
        if (buf is null) then raise_application_error(-20110, 'JSON Path parse error: . is not a valid json_path end'); end if;
        /* E.I.Sarmas (github.com/dsnz)   2021-10-31   removed space or number as acceptable character */
        if (not regexp_like(buf, '^["[:alpha:]\_]+', 'c') ) then
          -- dbms_output.put_line(build_path || ' + ' || buf);
          raise_application_error(-20110, 'JSON Path parse error: alpha or _ character expected at position '||indx);
        end if;

        if (build_path != '[') then build_path := build_path || ','; end if;
        build_path := build_path || '"';
        /* E.I.Sarmas (github.com/dsnz)   2021-10-31   accept name with any characters quoted within "" after . */
        if buf = '"' then
          next_char();
          while buf is not null and buf != '"' loop
            build_path := build_path || buf;
            next_char();
          end loop;
          if buf is null then
            raise_application_error(-20110, 'JSON Path parse error: premature json_path end, missing ending "');
          end if;
          next_char();
        else
          /* E.I.Sarmas (github.com/dsnz)   2021-10-31   removed space as acceptable character */
          while (regexp_like(buf, '^[[:alnum:]\_]+', 'c') ) loop
            build_path := build_path || buf;
            next_char();
          end loop;
        end if;
        build_path := build_path || '"';

      elsif (buf = '[') then
        next_char();
        skipws();
        if (buf is null) then raise_application_error(-20110, 'JSON Path parse error: [ is not a valid json_path end'); end if;
        -- array step
        if (buf in ('1','2','3','4','5','6','7','8','9') or (buf = '0' and base = 0)) then
          if (build_path != '[') then build_path := build_path || ','; end if;
          while (buf in ('0','1','2','3','4','5','6','7','8','9')) loop
            build_path := build_path || buf;
            next_char();
          end loop;
        -- object step using [] syntax
        elsif (regexp_like(buf, '^(\"|\'')', 'c')) then
          endstring := buf;
          if (build_path != '[') then build_path := build_path || ','; end if;
          build_path := build_path || '"';
          next_char();
          if (buf is null) then raise_application_error(-20110, 'JSON Path parse error: premature json_path end'); end if;
          while (buf != endstring) loop
            build_path := build_path || buf;
            next_char();
            if (buf is null) then raise_application_error(-20110, 'JSON Path parse error: premature json_path end'); end if;
            if (buf = '\') then
              next_char();
              build_path := build_path || '\' || buf;
              next_char();
            end if;
          end loop;
          build_path := build_path || '"';
          next_char();
        else
          raise_application_error(-20110, 'JSON Path parse error: expected a string or a positive integer at '||indx);
        end if;
        skipws();
        if (buf is null) then raise_application_error(-20110, 'JSON Path parse error: premature json_path end'); end if;
        if (buf != ']') then raise_application_error(-20110, 'JSON Path parse error: no array ending found. found: '|| buf); end if;
        next_char();
        skipws();

      /* E.I.Sarmas (github.com/dsnz)   2021-10-31   obsolete, repeats code after ".", handled by assuming a dummy "." at start
      elsif (build_path = '[') then
        if (not regexp_like(buf, '^[[:alnum:]\_ ]+', 'c') ) then
          raise_application_error(-20110, 'JSON Path parse error: alpha-numeric character or space expected at position '||indx);
        end if;
        build_path := build_path || '"';
        while (regexp_like(buf, '^[[:alnum:]\_ ]+', 'c') ) loop
          build_path := build_path || buf;
          next_char();
        end loop;
        build_path := build_path || '"';
      */
      else
        raise_application_error(-20110, 'JSON Path parse error: expected . or [ found '|| buf || ' at position '|| indx);
      end if;

    end loop;

    build_path := build_path || ']';
    build_path := replace(replace(replace(replace(replace(build_path, chr(9), '\t'), chr(10), '\n'), chr(13), '\f'), chr(8), '\b'), chr(14), '\r');
    -- dbms_output.put_line('parse= ' || build_path);

    ret := pljson_list(build_path);
    if (base != 1) then
      --fix base 0 to base 1
      declare
        elem pljson_element;
      begin
        for i in 1 .. ret.count loop
          elem := ret.get(i);
          if (elem.is_number()) then
            ret.replace(i, elem.get_number()+1);
          end if;
        end loop;
      end;
    end if;

    return ret;
  end parsePath;

  --JSON pre-parsed path getters
  /* contributed by @asfernandes */
  function get_json_element(obj pljson, path pljson_list) return pljson_element as
    path_segments pljson_path := pljson_path();
    ret pljson_element;
  begin
    if (path.count = 0) then
      return obj;
    end if;

    for i in 1 .. path.count loop
      path_segments.extend;
      if (path.get(i).is_number()) then
        path_segments(path_segments.count) := pljson_path_segment(path.get(i).get_number(), null);
      else
        path_segments(path_segments.count) := pljson_path_segment(null, path.get(i).get_string());
      end if;
    end loop;

    obj.get_internal_path(path_segments, 1, ret);
    return ret;
  exception
    when scanner_exception then raise;
    when parser_exception then raise;
    when jext_exception then raise;
    when others then return null;
  end get_json_element;

  function get_string(obj pljson, path pljson_list) return varchar2 as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path);
    if (temp is null or not temp.is_string()) then
      return null;
    else
      return temp.get_string();
    end if;
  end;

  function get_number(obj pljson, path pljson_list) return number as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path);
    if (temp is null or not temp.is_number()) then
      return null;
    else
      return temp.get_number();
    end if;
  end;

  function get_double(obj pljson, path pljson_list) return binary_double as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path);
    if (temp is null or not temp.is_number()) then
      return null;
    else
      return temp.get_double();
    end if;
  end;

  function get_json(obj pljson, path pljson_list) return pljson as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path);
    if (temp is null or not temp.is_object()) then
      return null;
    else
      return treat(temp as pljson);
    end if;
  end;

  function get_json_list(obj pljson, path pljson_list) return pljson_list as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path);
    if (temp is null or not temp.is_array()) then
      return null;
    else
      return treat(temp as pljson_list);
    end if;
  end;

  function get_bool(obj pljson, path pljson_list) return boolean as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path);
    if (temp is null or not temp.is_bool()) then
      return null;
    else
      return temp.get_bool();
    end if;
  end;

  function get_date(obj pljson, path pljson_list) return date as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path);
    if (temp is null or not is_date(temp)) then
      return null;
    else
      return pljson_ext.to_date(temp);
    end if;
  end;

  --JSON Path getters
  --saved original code, in case of future bug troubleshooting
  function get_json_element_original(obj pljson, v_path varchar2, base number default 1) return pljson_element as
    path pljson_list;
    ret pljson_element;
    o pljson; l pljson_list;
  begin
    path := parsePath(v_path, base);
    ret := obj;
    if (path.count = 0) then return ret; end if;

    for i in 1 .. path.count loop
      if (path.get(i).is_string()) then
        --string fetch only on json
        ------o := pljson(ret);
        ------ret := o.get(path.get(i).get_string());
        /* E.I.Sarmas (github.com/dsnz)   2020-04-18   use inheritance and avoid treat() */
        ret := ret.get(path.get(i).get_string());
        --experimental, ignore
        --ret := get_piece(o, path.get(i).get_string());
      else
        --number fetch on json and json_list
        if (ret.is_array()) then
          ------l := pljson_list(ret);
          ------ret := l.get(path.get(i).get_number());
          /* E.I.Sarmas (github.com/dsnz)   2020-04-18   use inheritance and avoid treat() */
          ret := ret.get(path.get(i).get_number());
          --experimental, ignore
          --ret := get_piece(l, path.get(i).get_number());
        else
          ------o := pljson(ret);
          ------l := o.get_values();
          ------ret := l.get(path.get(i).get_number());
          /* E.I.Sarmas (github.com/dsnz)   2020-04-18   use inheritance and avoid treat() */
          ret := ret.get(path.get(i).get_number());
          --experimental, ignore
          --ret := get_piece(l, path.get(i).get_number());
        end if;
      end if;
    end loop;

    return ret;
  exception
    when scanner_exception then raise;
    when parser_exception then raise;
    when jext_exception then raise;
    when others then return null;
  end get_json_element_original;

  function get_json_element(obj pljson, v_path varchar2, base number default 1) return pljson_element as
    path pljson_list;
  begin
    path := parsePath(v_path, base);
    return get_json_element(obj, path);
  end get_json_element;

  function get_string(obj pljson, path varchar2, base number default 1) return varchar2 as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path, base);
    if (temp is null or not temp.is_string()) then
      return null;
    else
      return temp.get_string();
    end if;
  end;

  function get_number(obj pljson, path varchar2, base number default 1) return number as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path, base);
    if (temp is null or not temp.is_number()) then
      return null;
    else
      return temp.get_number();
    end if;
  end;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  function get_double(obj pljson, path varchar2, base number default 1) return binary_double as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path, base);
    if (temp is null or not temp.is_number()) then
      return null;
    else
      return temp.get_double();
    end if;
  end;

  function get_json(obj pljson, path varchar2, base number default 1) return pljson as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path, base);
    if (temp is null or not temp.is_object()) then
      return null;
    else
      return treat(temp as pljson);
    end if;
  end;

  function get_json_list(obj pljson, path varchar2, base number default 1) return pljson_list as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path, base);
    if (temp is null or not temp.is_array()) then
      return null;
    else
      return treat(temp as pljson_list);
    end if;
  end;

  function get_bool(obj pljson, path varchar2, base number default 1) return boolean as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path, base);
    if (temp is null or not temp.is_bool()) then
      return null;
    else
      return temp.get_bool();
    end if;
  end;

  function get_date(obj pljson, path varchar2, base number default 1) return date as
    temp pljson_element;
  begin
    temp := get_json_element(obj, path, base);
    if (temp is null or not is_date(temp)) then
      return null;
    else
      return pljson_ext.to_date(temp);
    end if;
  end;

  /* JSON pre-parsed path putter internal function */
  procedure put_internal_preparsed(obj in out nocopy pljson, path pljson_list, elem pljson_element) as
    path_segments pljson_path := pljson_path();
    dummy boolean;
  begin
    if (path.count = 0) then raise_application_error(-20110, 'PLJSON_EXT put error: cannot put with empty string.'); end if;

    for i in 1 .. path.count loop
      path_segments.extend;

      if (path.get(i).is_number()) then
        path_segments(path_segments.count) := pljson_path_segment(path.get(i).get_number(), null);
      else
        path_segments(path_segments.count) := pljson_path_segment(null, path.get(i).get_string());
      end if;
    end loop;

    dummy := obj.put_internal_path(path_segments, elem, 1);
  end;

  /* JSON Path putter internal function */
  --saved original code, in case of future bug troubleshooting
  procedure put_internal_original(obj in out nocopy pljson, v_path varchar2, elem pljson_element, base number) as
    val pljson_element := elem;
    path pljson_list;
    backreference pljson_list := pljson_list();

    keyval pljson_element; keynum number; keystring varchar2(4000);
    temp pljson_element := obj;
    obj_temp  pljson;
    list_temp pljson_list;
    inserter pljson_element;
  begin
    path := pljson_ext.parsePath(v_path, base);
    if (path.count = 0) then raise_application_error(-20110, 'PLJSON_EXT put error: cannot put with empty string.'); end if;

    --build backreference
    for i in 1 .. path.count loop
      --backreference.print(false);
      keyval := path.get(i);
      if (keyval.is_number()) then
        --number index
        keynum := keyval.get_number();
        if ((not temp.is_object()) and (not temp.is_array())) then
          if (val is null) then return; end if;
          backreference.remove_last;
          temp := pljson_list();
          backreference.append(temp);
        end if;

        if (temp.is_object()) then
          obj_temp := pljson(temp);
          if (obj_temp.count < keynum) then
            if (val is null) then return; end if;
            raise_application_error(-20110, 'PLJSON_EXT put error: access object with too few members.');
          end if;
          temp := obj_temp.get(keynum);
        else
          list_temp := pljson_list(temp);
          if (list_temp.count < keynum) then
            if (val is null) then return; end if;
            --raise error or quit if val is null
            for i in list_temp.count+1 .. keynum loop
              list_temp.append(pljson_null());
            end loop;
            backreference.remove_last;
            backreference.append(list_temp);
          end if;

          temp := list_temp.get(keynum);
        end if;
      else
        --string index
        keystring := keyval.get_string();
        if (not temp.is_object()) then
          --backreference.print;
          if (val is null) then return; end if;
          backreference.remove_last;
          temp := pljson();
          backreference.append(temp);
          --raise_application_error(-20110, 'PLJSON_EXT put error: trying to access a non object with a string.');
        end if;
        obj_temp := pljson(temp);
        temp := obj_temp.get(keystring);
      end if;

      if (temp is null) then
        if (val is null) then return; end if;
        --what to expect?
        keyval := path.get(i+1);
        if (keyval is not null and keyval.is_number()) then
          temp := pljson_list();
        else
          temp := pljson();
        end if;
      end if;
      backreference.append(temp);
    end loop;

    --  backreference.print(false);
    --  path.print(false);

    --use backreference and path together
    inserter := val;
    for i in reverse 1 .. backreference.count loop
      -- inserter.print(false);
      if ( i = 1 ) then
        keyval := path.get(1);
        if (keyval.is_string()) then
          keystring := keyval.get_string();
        else
          keynum := keyval.get_number();
          declare
            t1 pljson_element := obj.get(keynum);
          begin
            keystring := t1.mapname;
          end;
        end if;
        if (inserter is null) then obj.remove(keystring); else obj.put(keystring, inserter); end if;
      else
        temp := backreference.get(i-1);
        if (temp.is_object()) then
          keyval := path.get(i);
          obj_temp := pljson(temp);
          if (keyval.is_string()) then
            keystring := keyval.get_string();
          else
            keynum := keyval.get_number();
            declare
              t1 pljson_element := obj_temp.get(keynum);
            begin
              keystring := t1.mapname;
            end;
          end if;
          if (inserter is null) then
            obj_temp.remove(keystring);
            if (obj_temp.count > 0) then inserter := obj_temp; end if;
          else
            obj_temp.put(keystring, inserter);
            inserter := obj_temp;
          end if;
        else
          --array only number
          keynum := path.get(i).get_number();
          list_temp := pljson_list(temp);
          list_temp.remove(keynum);
          if (not inserter is null) then
            list_temp.append(inserter, keynum);
            inserter := list_temp;
          else
            if (list_temp.count > 0) then inserter := list_temp; end if;
          end if;
        end if;
      end if;

    end loop;

  end put_internal_original;

  procedure put_internal(obj in out nocopy pljson, v_path varchar2, elem pljson_element, base number) as
    path pljson_list;
  begin
    path := pljson_ext.parsePath(v_path, base);
    put_internal_preparsed(obj, path, elem);
  end put_internal;

  /* JSON pre-parsed path putters */
  procedure put(obj in out nocopy pljson, path pljson_list, elem varchar2) as
  begin
    if elem is null then
      put_internal_preparsed(obj, path, pljson_null());
    else
      put_internal_preparsed(obj, path, pljson_string(elem));
    end if;
  end;

  procedure put(obj in out nocopy pljson, path pljson_list, elem number) as
  begin
    if elem is null then
      put_internal_preparsed(obj, path, pljson_null());
    else
      put_internal_preparsed(obj, path, pljson_number(elem));
    end if;
  end;

  procedure put(obj in out nocopy pljson, path pljson_list, elem binary_double) as
  begin
    if elem is null then
      put_internal_preparsed(obj, path, pljson_null());
    else
      put_internal_preparsed(obj, path, pljson_number(elem));
    end if;
  end;

  procedure put(obj in out nocopy pljson, path pljson_list, elem pljson) as
  begin
    if elem is null then
      put_internal_preparsed(obj, path, pljson_null());
    else
      put_internal_preparsed(obj, path, elem);
    end if;
  end;

  procedure put(obj in out nocopy pljson, path pljson_list, elem pljson_list) as
  begin
    if elem is null then
      put_internal_preparsed(obj, path, pljson_null());
    else
      put_internal_preparsed(obj, path, elem);
    end if;
  end;

  procedure put(obj in out nocopy pljson, path pljson_list, elem boolean) as
  begin
    if elem is null then
      put_internal_preparsed(obj, path, pljson_null());
    else
      put_internal_preparsed(obj, path, pljson_bool(elem));
    end if;
  end;

  procedure put(obj in out nocopy pljson, path pljson_list, elem pljson_element) as
  begin
    if elem is null then
      put_internal_preparsed(obj, path, pljson_null());
    else
      put_internal_preparsed(obj, path, elem);
    end if;
  end;

  procedure put(obj in out nocopy pljson, path pljson_list, elem date) as
  begin
    if elem is null then
      put_internal_preparsed(obj, path, pljson_null());
    else
      put_internal_preparsed(obj, path, pljson_ext.to_json_string(elem));
    end if;
  end;

  /* JSON Path putters */
  procedure put(obj in out nocopy pljson, path varchar2, elem varchar2, base number default 1) as
  begin
    if elem is null then
      put_internal(obj, path, pljson_null(), base);
    else
      put_internal(obj, path, pljson_string(elem), base);
    end if;
  end;

  procedure put(obj in out nocopy pljson, path varchar2, elem number, base number default 1) as
  begin
    if elem is null then
      put_internal(obj, path, pljson_null(), base);
    else
      put_internal(obj, path, pljson_number(elem), base);
    end if;
  end;

  /* E.I.Sarmas (github.com/dsnz)   2016-12-01   support for binary_double numbers */
  procedure put(obj in out nocopy pljson, path varchar2, elem binary_double, base number default 1) as
  begin
    if elem is null then
      put_internal(obj, path, pljson_null(), base);
    else
      put_internal(obj, path, pljson_number(elem), base);
    end if;
  end;

  procedure put(obj in out nocopy pljson, path varchar2, elem pljson, base number default 1) as
  begin
    if elem is null then
      put_internal(obj, path, pljson_null(), base);
    else
      put_internal(obj, path, elem, base);
    end if;
  end;

  procedure put(obj in out nocopy pljson, path varchar2, elem pljson_list, base number default 1) as
  begin
    if elem is null then
      put_internal(obj, path, pljson_null(), base);
    else
      put_internal(obj, path, elem, base);
    end if;
  end;

  procedure put(obj in out nocopy pljson, path varchar2, elem boolean, base number default 1) as
  begin
    if elem is null then
      put_internal(obj, path, pljson_null(), base);
    else
      put_internal(obj, path, pljson_bool(elem), base);
    end if;
  end;

  procedure put(obj in out nocopy pljson, path varchar2, elem pljson_element, base number default 1) as
  begin
    if elem is null then
      put_internal(obj, path, pljson_null(), base);
    else
      put_internal(obj, path, elem, base);
    end if;
  end;

  procedure put(obj in out nocopy pljson, path varchar2, elem date, base number default 1) as
  begin
    if elem is null then
      put_internal(obj, path, pljson_null(), base);
    else
      put_internal(obj, path, pljson_ext.to_json_string(elem), base);
    end if;
  end;

  procedure remove(obj in out nocopy pljson, path pljson_list) as
  begin
    pljson_ext.put_internal_preparsed(obj, path, null);
  end remove;

  procedure remove(obj in out nocopy pljson, path varchar2, base number default 1) as
  begin
    pljson_ext.put_internal(obj, path, null, base);
    --if (json_ext.get_json_element(obj, path) is not null) then
    --end if;
  end remove;

  --Pretty print with JSON Path
  function pp(obj pljson, v_path varchar2) return varchar2 as
    json_part pljson_element;
  begin
    json_part := pljson_ext.get_json_element(obj, v_path);
    if (json_part is null) then
      return '';
    else
      return pljson_printer.pretty_print_any(json_part); --escapes a possible internal string
    end if;
  end pp;

  procedure pp(obj pljson, v_path varchar2) as --using dbms_output.put_line
  begin
    dbms_output.put_line(pp(obj, v_path));
  end pp;

  -- spaces = false!
  procedure pp_htp(obj pljson, v_path varchar2) as --using htp.print
    json_part pljson_element;
  begin
    json_part := pljson_ext.get_json_element(obj, v_path);
    if (json_part is null) then
      htp.print;
    else
      htp.print(pljson_printer.pretty_print_any(json_part, false));
    end if;
  end pp_htp;

  function base64(binarydata blob) return pljson_list as
    obj pljson_list := pljson_list();
    c clob;

    v_clob_offset number := 1;
    v_lang_context number := dbms_lob.DEFAULT_LANG_CTX;
    v_amount number;
  begin
    --dbms_lob.createtemporary(c, false, dbms_lob.call);
    c := encodeBase64Blob2Clob(binarydata);
    v_amount := dbms_lob.getlength(c);
    v_clob_offset := 1;
    --dbms_output.put_line('v_amount: '||v_amount);
    while (v_clob_offset < v_amount) loop
      --dbms_output.put_line(v_offset);
      --temp := ;
      --dbms_output.put_line('size: '||length(temp));
      obj.append(dbms_lob.substr(c, 4000, v_clob_offset));
      v_clob_offset := v_clob_offset + 4000;
    end loop;
    dbms_lob.freetemporary(c);
    --dbms_output.put_line(obj.count);
    --dbms_output.put_line(obj.get_last().to_char);
    return obj;

  end base64;

  function base64(l pljson_list) return blob as
    c clob;
    b_ret blob;

    v_lang_context number := dbms_lob.DEFAULT_LANG_CTX;
    -- v_amount number;
  begin
    dbms_lob.createtemporary(c, false, dbms_lob.call);
    for i in 1 .. l.count loop
      dbms_lob.append(c, l.get(i).get_string());
    end loop;
    -- v_amount := dbms_lob.getlength(c);
    -- dbms_output.put_line('L C'||v_amount);
    b_ret := decodeBase64Clob2Blob(c);
    dbms_lob.freetemporary(c);
    return b_ret;
  end base64;

  function encode(binarydata blob) return pljson_string as
    obj pljson_string;
    c clob;
    v_lang_context number := dbms_lob.DEFAULT_LANG_CTX;
  begin
    dbms_lob.createtemporary(c, false, dbms_lob.call);
    c := encodeBase64Blob2Clob(binarydata);
    obj := pljson_string(c);

    --dbms_output.put_line(obj.count);
    --dbms_output.put_line(obj.get_last().to_char);
    /* dbms_lob.freetemporary(c); */
    return obj;
  end encode;

  function decode(v pljson_string) return blob as
    c clob;
    b_ret blob;

    v_lang_context number := dbms_lob.DEFAULT_LANG_CTX;
    -- v_amount number;
  begin
    /*
    dbms_lob.createtemporary(c, false, dbms_lob.call);
    v.get_string(c);
    */
    c := v.get_clob();
    -- v_amount := dbms_lob.getlength(c);
    -- dbms_output.put_line('L C'||v_amount);
    b_ret := decodeBase64Clob2Blob(c);
    /* dbms_lob.freetemporary(c); */
    return b_ret;

  end decode;

  procedure blob2clob(b blob, c out clob, charset varchar2 default 'UTF8') as
    v_dest_offset number := 1;
    v_src_offset number := 1;
    v_lang_context number := dbms_lob.DEFAULT_LANG_CTX;
    v_warning number := dbms_lob.NO_WARNING;
  begin
    dbms_lob.createtemporary(c, false, dbms_lob.call);
    dbms_lob.converttoclob(
      dest_lob => c,
      src_blob => b,
      amount => dbms_lob.LOBMAXSIZE,
      dest_offset => v_dest_offset,
      src_offset => v_src_offset,
      blob_csid => nls_charset_id(charset),
      lang_context => v_lang_context,
      warning => v_warning);
  end;
end pljson_ext;
/
show err