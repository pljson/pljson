create or replace package pljson_printer as
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
  indent_string varchar2(10 char) := '  '; --chr(9); for tab
  newline_char varchar2(2 char)   := chr(13)||chr(10); -- Windows style
  --newline_char varchar2(2) := chr(10); -- Mac style
  --newline_char varchar2(2) := chr(13); -- Linux style
  ascii_output boolean    not null := true;
  empty_string_as_null boolean not null := false;
  escape_solidus boolean  not null := false;
  
  function pretty_print(obj pljson, spaces boolean default true, line_length number default 0) return varchar2;
  function pretty_print_list(obj pljson_list, spaces boolean default true, line_length number default 0) return varchar2;
  function pretty_print_any(json_part pljson_value, spaces boolean default true, line_length number default 0) return varchar2;
  procedure pretty_print(obj pljson, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true);
  procedure pretty_print_list(obj pljson_list, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true);
  procedure pretty_print_any(json_part pljson_value, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true);
  
  procedure dbms_output_clob(my_clob clob, delim varchar2, jsonp varchar2 default null);
  procedure htp_output_clob(my_clob clob, jsonp varchar2 default null);
  -- made public just for testing/profiling...
  function escapeString(str varchar2) return varchar2;

end pljson_printer;
/
show err

create or replace package body pljson_printer as
  max_line_len number := 0;
  cur_line_len number := 0;
  
  -- associative array used inside escapeString to cache the escaped version of every character
  -- escaped so far  (example: char_map('"') contains the  '\"' string)
  -- (if the character does not need to be escaped, the character is stored unchanged in the array itself)
  -- type Rmap_char is record(buf varchar2(40), len integer);
  type Tmap_char_string is table of varchar2(40) index by varchar2(1 char); /* index by unicode char */
  char_map Tmap_char_string;
  -- since char_map the associative array is a global variable reused across multiple calls to escapeString,
  -- i need to be able to detect that the escape_solidus or ascii_output global parameters have been changed,
  -- in order to clear it and avoid using escape sequences that have been cached using the previous values
  char_map_escape_solidus boolean := escape_solidus;
  char_map_ascii_output boolean := ascii_output;
  
  function llcheck(str in varchar2) return varchar2 as
  begin
    --dbms_output.put_line(cur_line_len || ' : ' || str);
    if (max_line_len > 0 and length(str)+cur_line_len > max_line_len) then
      cur_line_len := length(str);
      return newline_char || str;
    else
      cur_line_len := cur_line_len + length(str);
      return str;
    end if;
  end llcheck;
  
  -- escapes a single character.
  function escapeChar(ch char) return varchar2 deterministic is
     result varchar2(20);
  begin
      --backspace b = U+0008
      --formfeed  f = U+000C
      --newline   n = U+000A
      --carret    r = U+000D
      --tabulator t = U+0009
      result := ch;
      
      case ch
      when chr( 8) then result := '\b';
      when chr( 9) then result := '\t';
      when chr(10) then result := '\n';
      when chr(12) then result := '\f';
      when chr(13) then result := '\r';
      when chr(34) then result := '\"';
      when chr(47) then if (escape_solidus) then result := '\/'; end if;
      when chr(92) then result := '\\';
      else if (ascii(ch) < 32) then
             result :=  '\u' || replace(substr(to_char(ascii(ch), 'XXXX'), 2, 4), ' ', '0');
        elsif (ascii_output) then
             result := replace(asciistr(ch), '\', '\u');
        end if;
      end case;
      return result;
  end;
  
  function escapeString(str varchar2) return varchar2 as
    sb varchar2(32767 byte) := '';
    buf varchar2(40);
    ch varchar2(1 char); /* unicode char */
  begin
    if (str is null) then return ''; end if;
    
    -- clear the cache if global parameters have been changed
    if char_map_escape_solidus <> escape_solidus or
       char_map_ascii_output   <> ascii_output
    then
       char_map.delete;
       char_map_escape_solidus := escape_solidus;
       char_map_ascii_output := ascii_output;
    end if;
    
    for i in 1 .. length(str) loop
      ch := substr(str, i, 1 ) ;
      
      begin
         -- it this char has already been processed, I have cached its escaped value
         buf:=char_map(ch);
      exception when no_Data_found then
         -- otherwise, i convert the value and add it to the cache
         buf := escapeChar(ch);
         char_map(ch) := buf;
      end;
      
      sb := sb || buf;
    end loop;
    return sb;
  end escapeString;
  
  function newline(spaces boolean) return varchar2 as
  begin
    cur_line_len := 0;
    if (spaces) then return newline_char; else return ''; end if;
  end;
  
/*  function get_schema return varchar2 as
  begin
    return sys_context('userenv', 'current_schema');
  end;
*/
  function tab(indent number, spaces boolean) return varchar2 as
    i varchar(200) := '';
  begin
    if (not spaces) then return ''; end if;
    for x in 1 .. indent loop i := i || indent_string; end loop;
    return i;
  end;
  
  function getCommaSep(spaces boolean) return varchar2 as
  begin
    if (spaces) then return ', '; else return ','; end if;
  end;
  
  function getMemName(mem pljson_value, spaces boolean) return varchar2 as
  begin
    if (spaces) then
      return llcheck('"'||escapeString(mem.mapname)||'"') || llcheck(' : ');
    else
      return llcheck('"'||escapeString(mem.mapname)||'"') || llcheck(':');
    end if;
  end;
  
  /* Clob method start here */
  procedure add_to_clob(buf_lob in out nocopy clob, buf_str in out nocopy varchar2, str varchar2) as
  begin
    if (lengthb(str) > 32767 - lengthb(buf_str)) then
--      dbms_lob.append(buf_lob, buf_str);
      dbms_lob.writeappend(buf_lob, length(buf_str), buf_str);
      buf_str := str;
    else
      buf_str := buf_str || str;
    end if;
  end add_to_clob;
  
  procedure flush_clob(buf_lob in out nocopy clob, buf_str in out nocopy varchar2) as
  begin
    --dbms_lob.append(buf_lob, buf_str);
    dbms_lob.writeappend(buf_lob, length(buf_str), buf_str);
  end flush_clob;
  
  procedure ppObj(obj pljson, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2);
  
  procedure ppString(elem pljson_value, buf in out nocopy clob, buf_str in out nocopy varchar2) is
    offset number := 1;
    /* E.I.Sarmas (github.com/dsnz)   2016-01-21   limit to 5000 chars */
    v_str varchar(5000 char);
    amount number := 5000; /* chunk size for use in escapeString; maximum escaped unicode string size for chunk may be 6 one-byte chars * 5000 chunk size in multi-byte chars = 30000 1-byte chars (maximum value is 32767 1-byte chars) */
  begin
    if empty_string_as_null and elem.extended_str is null and elem.str is null then
      add_to_clob(buf, buf_str, 'null');
    else
      add_to_clob(buf, buf_str, case when elem.num = 1 then '"' else '/**/' end);
      if (elem.extended_str is not null) then --clob implementation
        while (offset <= dbms_lob.getlength(elem.extended_str)) loop
          dbms_lob.read(elem.extended_str, amount, offset, v_str);
          if (elem.num = 1) then
            add_to_clob(buf, buf_str, escapeString(v_str));
          else
            add_to_clob(buf, buf_str, v_str);
          end if;
          offset := offset + amount;
        end loop;
      else
        if (elem.num = 1) then
          while (offset <= length(elem.str)) loop
            v_str:=substr(elem.str, offset, amount);
            add_to_clob(buf, buf_str, escapeString(v_str));
            offset := offset + amount;
          end loop;
        else
          add_to_clob(buf, buf_str, elem.str);
        end if;
      end if;
      add_to_clob(buf, buf_str, case when elem.num = 1 then '"' else '/**/' end);
    end if;
  end;
  
  procedure ppEA(input pljson_list, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2) as
    elem pljson_value;
    arr pljson_value_array := input.list_data;
    numbuf varchar2(4000);
  begin
    for y in 1 .. arr.count loop
      elem := arr(y);
      if (elem is not null) then
      case elem.typeval
        /* number */
        when 4 then
          numbuf := elem.number_toString();
          add_to_clob(buf, buf_str, llcheck(numbuf));
        /* string */
        when 3 then
          ppString(elem, buf, buf_str);
        /* bool */
        when 5 then
          if (elem.get_bool()) then
            add_to_clob(buf, buf_str, llcheck('true'));
          else
            add_to_clob(buf, buf_str, llcheck('false'));
          end if;
        /* null */
        when 6 then
          add_to_clob(buf, buf_str, llcheck('null'));
        /* array */
        when 2 then
          add_to_clob(buf, buf_str, llcheck('['));
          ppEA(pljson_list(elem), indent, buf, spaces, buf_str);
          add_to_clob(buf, buf_str, llcheck(']'));
        /* object */
        when 1 then
          ppObj(pljson(elem), indent, buf, spaces, buf_str);
        else
          add_to_clob(buf, buf_str, llcheck(elem.get_type));
      end case;
      end if;
      if (y != arr.count) then add_to_clob(buf, buf_str, llcheck(getCommaSep(spaces))); end if;
    end loop;
  end ppEA;
  
  procedure ppMem(mem pljson_value, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2) as
    numbuf varchar2(4000);
  begin
    add_to_clob(buf, buf_str, llcheck(tab(indent, spaces)) || llcheck(getMemName(mem, spaces)));
    case mem.typeval
      /* number */
      when 4 then
        numbuf := mem.number_toString();
        add_to_clob(buf, buf_str, llcheck(numbuf));
      /* string */
      when 3 then
        ppString(mem, buf, buf_str);
      /* bool */
      when 5 then
        if (mem.get_bool()) then
          add_to_clob(buf, buf_str, llcheck('true'));
        else
          add_to_clob(buf, buf_str, llcheck('false'));
        end if;
      /* null */
      when 6 then
        add_to_clob(buf, buf_str, llcheck('null'));
      /* array */
      when 2 then
        add_to_clob(buf, buf_str, llcheck('['));
        ppEA(pljson_list(mem), indent, buf, spaces, buf_str);
        add_to_clob(buf, buf_str, llcheck(']'));
      /* object */
      when 1 then
        ppObj(pljson(mem), indent, buf, spaces, buf_str);
      else
        add_to_clob(buf, buf_str, llcheck(mem.get_type));
    end case;
  end ppMem;
  
  procedure ppObj(obj pljson, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2) as
  begin
    add_to_clob(buf, buf_str, llcheck('{') || newline(spaces));
    for m in 1 .. obj.json_data.count loop
      ppMem(obj.json_data(m), indent+1, buf, spaces, buf_str);
      if (m != obj.json_data.count) then
        add_to_clob(buf, buf_str, llcheck(',') || newline(spaces));
      else
        add_to_clob(buf, buf_str, newline(spaces));
      end if;
    end loop;
    add_to_clob(buf, buf_str, llcheck(tab(indent, spaces)) || llcheck('}')); -- || chr(13);
  end ppObj;
  
  procedure pretty_print(obj pljson, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true) as
    buf_str varchar2(32767);
    amount number := dbms_lob.getlength(buf);
  begin
    if (erase_clob and amount > 0) then dbms_lob.trim(buf, 0); dbms_lob.erase(buf, amount); end if;
    
    max_line_len := line_length;
    cur_line_len := 0;
    ppObj(obj, 0, buf, spaces, buf_str);
    flush_clob(buf, buf_str);
  end;
  
  procedure pretty_print_list(obj pljson_list, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true) as
    buf_str varchar2(32767);
    amount number := dbms_lob.getlength(buf);
  begin
    if (erase_clob and amount > 0) then dbms_lob.trim(buf, 0); dbms_lob.erase(buf, amount); end if;
    
    max_line_len := line_length;
    cur_line_len := 0;
    add_to_clob(buf, buf_str, llcheck('['));
    ppEA(obj, 0, buf, spaces, buf_str);
    add_to_clob(buf, buf_str, llcheck(']'));
    flush_clob(buf, buf_str);
  end;
  
  procedure pretty_print_any(json_part pljson_value, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true) as
    buf_str varchar2(32767) := '';
    numbuf varchar2(4000);
    amount number := dbms_lob.getlength(buf);
  begin
    if (erase_clob and amount > 0) then dbms_lob.trim(buf, 0); dbms_lob.erase(buf, amount); end if;
    
    case json_part.typeval
      /* number */
      when 4 then
        numbuf := json_part.number_toString();
        add_to_clob(buf, buf_str, numbuf);
      /* string */
      when 3 then
        ppString(json_part, buf, buf_str);
      /* bool */
      when 5 then
        if (json_part.get_bool()) then
          add_to_clob(buf, buf_str, 'true');
        else
          add_to_clob(buf, buf_str, 'false');
        end if;
      /* null */
      when 6 then
        add_to_clob(buf, buf_str, 'null');
      /* array */
      when 2 then
        pretty_print_list(pljson_list(json_part), spaces, buf, line_length);
        return;
      /* object */
      when 1 then
        pretty_print(pljson(json_part), spaces, buf, line_length);
        return;
      else
        add_to_clob(buf, buf_str, 'unknown type:' || json_part.get_type);
    end case;
    flush_clob(buf, buf_str);
  end;
  
  /* Clob method end here */
  
  /* Varchar2 method start here */
  procedure add_buf (buf in out nocopy varchar2, str in varchar2) as
  begin
    if (lengthb(str)>32767-lengthb(buf)) then
      raise_application_error(-20001,'Length of result JSON more than 32767 bytes. Use to_clob() procedures');
    end if;
    buf := buf || str;
  end;
  
  procedure ppString(elem pljson_value, buf in out nocopy varchar2) is
    offset number := 1;
    /* E.I.Sarmas (github.com/dsnz)   2016-01-21   limit to 5000 chars */
    v_str varchar(5000 char);
    amount number := 5000; /* chunk size for use in escapeString; maximum escaped unicode string size for chunk may be 6 one-byte chars * 5000 chunk size in multi-byte chars = 30000 1-byte chars (maximum value is 32767 1-byte chars) */
  begin
    if empty_string_as_null and elem.extended_str is null and elem.str is null then
      add_buf(buf, 'null');
    else
      add_buf(buf, case when elem.num = 1 then '"' else '/**/' end);
      if (elem.extended_str is not null) then --clob implementation
        while (offset <= dbms_lob.getlength(elem.extended_str)) loop
          dbms_lob.read(elem.extended_str, amount, offset, v_str);
          if (elem.num = 1) then
            add_buf(buf, escapeString(v_str));
          else
            add_buf(buf, v_str);
          end if;
          offset := offset + amount;
        end loop;
      else
        if (elem.num = 1) then
          while (offset <= length(elem.str)) loop
            v_str:=substr(elem.str, offset, amount);
            add_buf(buf, escapeString(v_str));
            offset := offset + amount;
          end loop;
        else
          add_buf(buf, elem.str);
        end if;
      end if;
      add_buf(buf, case when elem.num = 1 then '"' else '/**/' end);
    end if;
  end;
  
  procedure ppObj(obj pljson, indent number, buf in out nocopy varchar2, spaces boolean);
  
  procedure ppEA(input pljson_list, indent number, buf in out varchar2, spaces boolean) as
    elem pljson_value;
    arr pljson_value_array := input.list_data;
    str varchar2(400);
  begin
    for y in 1 .. arr.count loop
      elem := arr(y);
      if (elem is not null) then
      case elem.typeval
        /* number */
        when 4 then
          str := elem.number_toString();
          add_buf(buf, llcheck(str));
        /* string */
        when 3 then
          ppString(elem, buf);
        /* bool */
        when 5 then
          if (elem.get_bool()) then
            add_buf (buf, llcheck('true'));
          else
            add_buf (buf, llcheck('false'));
          end if;
        /* null */
        when 6 then
          add_buf (buf, llcheck('null'));
        /* array */
        when 2 then
          add_buf( buf, llcheck('['));
          ppEA(pljson_list(elem), indent, buf, spaces);
          add_buf( buf, llcheck(']'));
        /* object */
        when 1 then
          ppObj(pljson(elem), indent, buf, spaces);
        else
          add_buf (buf, llcheck(elem.get_type)); /* should never happen */
      end case;
      end if;
      if (y != arr.count) then add_buf(buf, llcheck(getCommaSep(spaces))); end if;
    end loop;
  end ppEA;
  
  procedure ppMem(mem pljson_value, indent number, buf in out nocopy varchar2, spaces boolean) as
    str varchar2(400) := '';
  begin
    add_buf(buf, llcheck(tab(indent, spaces)) || getMemName(mem, spaces));
    case mem.typeval
      /* number */
      when 4 then
        str := mem.number_toString();
        add_buf(buf, llcheck(str));
      /* string */
      when 3 then
        ppString(mem, buf);
      /* bool */
      when 5 then
        if (mem.get_bool()) then
          add_buf(buf, llcheck('true'));
        else
          add_buf(buf, llcheck('false'));
        end if;
      /* null */
      when 6 then
        add_buf(buf, llcheck('null'));
      /* array */
      when 2 then
        add_buf(buf, llcheck('['));
        ppEA(pljson_list(mem), indent, buf, spaces);
        add_buf(buf, llcheck(']'));
      /* object */
      when 1 then
        ppObj(pljson(mem), indent, buf, spaces);
      else
        add_buf(buf, llcheck(mem.get_type)); /* should never happen */
    end case;
  end ppMem;
  
  procedure ppObj(obj pljson, indent number, buf in out nocopy varchar2, spaces boolean) as
  begin
    add_buf (buf, llcheck('{') || newline(spaces));
    for m in 1 .. obj.json_data.count loop
      ppMem(obj.json_data(m), indent+1, buf, spaces);
      if (m != obj.json_data.count) then
        add_buf(buf, llcheck(',') || newline(spaces));
      else
        add_buf(buf, newline(spaces));
      end if;
    end loop;
    add_buf(buf, llcheck(tab(indent, spaces)) || llcheck('}')); -- || chr(13);
  end ppObj;
  
  function pretty_print(obj pljson, spaces boolean default true, line_length number default 0) return varchar2 as
    buf varchar2(32767 byte) := '';
  begin
    max_line_len := line_length;
    cur_line_len := 0;
    ppObj(obj, 0, buf, spaces);
    return buf;
  end pretty_print;
  
  function pretty_print_list(obj pljson_list, spaces boolean default true, line_length number default 0) return varchar2 as
    buf varchar2(32767 byte) :='';
  begin
    max_line_len := line_length;
    cur_line_len := 0;
    add_buf(buf, llcheck('['));
    ppEA(obj, 0, buf, spaces);
    add_buf(buf, llcheck(']'));
    return buf;
  end;
  
  function pretty_print_any(json_part pljson_value, spaces boolean default true, line_length number default 0) return varchar2 as
    buf varchar2(32767) := '';
  begin
    case json_part.typeval
      /* number */
      when 4 then
        buf := json_part.number_toString();
      /* string */
      when 3 then
        ppString(json_part, buf);
      /* bool */
      when 5 then
        if (json_part.get_bool()) then buf := 'true'; else buf := 'false'; end if;
      /* null */
      when 6 then
        buf := 'null';
      /* array */
      when 2 then
        buf := pretty_print_list(pljson_list(json_part), spaces, line_length);
      /* object */
      when 1 then
        buf := pretty_print(pljson(json_part), spaces, line_length);
      else
        buf := 'weird error: ' || json_part.get_type;
    end case;
    return buf;
  end;
  
  procedure dbms_output_clob(my_clob clob, delim varchar2, jsonp varchar2 default null) as
    prev number := 1;
    indx number := 1;
    size_of_nl number := lengthb(delim);
    v_str varchar2(32767);
    amount number := 8191; /* max unicode chars */
  begin
    if (jsonp is not null) then dbms_output.put_line(jsonp||'('); end if;
    while (indx != 0) loop
      --read every line
      indx := dbms_lob.instr(my_clob, delim, prev+1);
      --dbms_output.put_line(prev || ' to ' || indx);
      
      if (indx = 0) then
        --emit from prev to end;
        amount := 8191; /* max unicode chars */
        --dbms_output.put_line(' mycloblen ' || dbms_lob.getlength(my_clob));
        loop
          dbms_lob.read(my_clob, amount, prev, v_str);
          dbms_output.put_line(v_str);
          prev := prev+amount-1;
          exit when prev >= dbms_lob.getlength(my_clob);
        end loop;
      else
        amount := indx - prev;
        if (amount > 8191) then /* max unicode chars */
          amount := 8191; /* max unicode chars */
          --dbms_output.put_line(' mycloblen ' || dbms_lob.getlength(my_clob));
          loop
            dbms_lob.read(my_clob, amount, prev, v_str);
            dbms_output.put_line(v_str);
            prev := prev+amount-1;
            amount := indx - prev;
            exit when prev >= indx - 1;
            if (amount > 8191) then amount := 8191; end if; /* max unicode chars */
          end loop;
          prev := indx + size_of_nl;
        else
          dbms_lob.read(my_clob, amount, prev, v_str);
          dbms_output.put_line(v_str);
          prev := indx + size_of_nl;
        end if;
      end if;
    
    end loop;
    if (jsonp is not null) then dbms_output.put_line(')'); end if;
    
/*    while (amount != 0) loop
      indx := dbms_lob.instr(my_clob, delim, prev+1);

--      dbms_output.put_line(prev || ' to ' || indx);
      if (indx = 0) then
        indx := dbms_lob.getlength(my_clob)+1;
      end if;
      if (indx-prev > 32767) then
        indx := prev+32767;
      end if;
--      dbms_output.put_line(prev || ' to ' || indx);
      --substr doesnt work properly on all platforms! (come on oracle - error on Oracle VM for virtualbox)
--        dbms_output.put_line(dbms_lob.substr(my_clob, indx-prev, prev));
      amount := indx-prev;
--        dbms_output.put_line('amount'||amount);
      dbms_lob.read(my_clob, amount, prev, v_str);
      dbms_output.put_line(v_str);
      prev := indx+size_of_nl;
      if (amount = 32767) then prev := prev-size_of_nl-1; end if;
    end loop;
    if (jsonp is not null) then dbms_output.put_line(')'); end if;*/
  end;
  
/*  procedure dbms_output_clob(my_clob clob, delim varchar2, jsonp varchar2 default null) as
    prev number := 1;
    indx number := 1;
    size_of_nl number := lengthb(delim);
    v_str varchar2(32767);
    amount number;
  begin
    if (jsonp is not null) then dbms_output.put_line(jsonp||'('); end if;
    while (indx != 0) loop
      indx := dbms_lob.instr(my_clob, delim, prev+1);

      --dbms_output.put_line(prev || ' to ' || indx);
      if (indx-prev > 32767) then
        indx := prev+32767;
      end if;
      --dbms_output.put_line(prev || ' to ' || indx);
      --substr doesnt work properly on all platforms! (come on oracle - error on Oracle VM for virtualbox)
      if (indx = 0) then
        --dbms_output.put_line(dbms_lob.substr(my_clob, dbms_lob.getlength(my_clob)-prev+size_of_nl, prev));
        amount := dbms_lob.getlength(my_clob)-prev+size_of_nl;
        dbms_lob.read(my_clob, amount, prev, v_str);
      else
        --dbms_output.put_line(dbms_lob.substr(my_clob, indx-prev, prev));
        amount := indx-prev;
        --dbms_output.put_line('amount'||amount);
        dbms_lob.read(my_clob, amount, prev, v_str);
      end if;
      dbms_output.put_line(v_str);
      prev := indx+size_of_nl;
      if (amount = 32767) then prev := prev-size_of_nl-1; end if;
    end loop;
    if (jsonp is not null) then dbms_output.put_line(')'); end if;
  end;
*/
  
  procedure htp_output_clob(my_clob clob, jsonp varchar2 default null) as
    /*amount number := 4096;
    pos number := 1;
    len number;
    */
    l_amt    number default 4096;
    l_off   number default 1;
    l_str   varchar2(32000);
  begin
    if (jsonp is not null) then htp.prn(jsonp||'('); end if;
    
    begin
      loop
        dbms_lob.read( my_clob, l_amt, l_off, l_str );
        
        -- it is vital to use htp.PRN to avoid
        -- spurious line feeds getting added to your
        -- document
        htp.prn( l_str  );
        l_off := l_off+l_amt;
      end loop;
    exception
      when no_data_found then NULL;
    end;
    
    /*
    len := dbms_lob.getlength(my_clob);
    
    while (pos < len) loop
      htp.prn(dbms_lob.substr(my_clob, amount, pos)); -- should I replace substr with dbms_lob.read?
      --dbms_output.put_line(dbms_lob.substr(my_clob, amount, pos));
      pos := pos + amount;
    end loop;
    */
    if (jsonp is not null) then htp.prn(')'); end if;
  end;

end pljson_printer;
/
show err