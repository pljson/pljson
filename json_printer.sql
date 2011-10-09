create or replace package json_printer as
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
  escape_solidus boolean  not null := false;

  function pretty_print(obj json, spaces boolean default true, line_length number default 0) return varchar2;
  function pretty_print_list(obj json_list, spaces boolean default true, line_length number default 0) return varchar2;
  function pretty_print_any(json_part json_value, spaces boolean default true, line_length number default 0) return varchar2;
  procedure pretty_print(obj json, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true);
  procedure pretty_print_list(obj json_list, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true);
  procedure pretty_print_any(json_part json_value, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true);
  
  procedure dbms_output_clob(my_clob clob, delim varchar2, jsonp varchar2 default null);
  procedure htp_output_clob(my_clob clob, jsonp varchar2 default null);
end json_printer;
/

create or replace
package body "JSON_PRINTER" as
  max_line_len number := 0;
  cur_line_len number := 0;
  
  function llcheck(str in varchar2) return varchar2 as
  begin
    --dbms_output.put_line(cur_line_len || ' : '|| str);
    if(max_line_len > 0 and length(str)+cur_line_len > max_line_len) then
      cur_line_len := length(str);
      return newline_char || str;
    else 
      cur_line_len := cur_line_len + length(str);
      return str;
    end if;
  end llcheck;  

  function escapeString(str varchar2) return varchar2 as
    sb varchar2(32767) := '';
    buf varchar2(40);
    num number;
  begin
    if(str is null) then return ''; end if;
    for i in 1 .. length(str) loop
      buf := substr(str, i, 1);
      --backspace b = U+0008
      --formfeed  f = U+000C
      --newline   n = U+000A
      --carret    r = U+000D
      --tabulator t = U+0009
      case buf
      when chr( 8) then buf := '\b';
      when chr( 9) then buf := '\t';
      when chr(10) then buf := '\n';
      when chr(13) then buf := '\f';
      when chr(14) then buf := '\r';
      when chr(34) then buf := '\"';
      when chr(47) then if(escape_solidus) then buf := '\/'; end if;
      when chr(92) then buf := '\\';
      else 
        if(ascii(buf) < 32) then
          buf := '\u'||replace(substr(to_char(ascii(buf), 'XXXX'),2,4), ' ', '0');
        elsif (ascii_output) then 
          buf := replace(asciistr(buf), '\', '\u');
        end if;
      end case;      
      
      sb := sb || buf;
    end loop;
  
    return sb;
  end escapeString;

  function newline(spaces boolean) return varchar2 as
  begin
    cur_line_len := 0;
    if(spaces) then return newline_char; else return ''; end if;
  end;

/*  function get_schema return varchar2 as
  begin
    return sys_context('userenv', 'current_schema');
  end;  
*/  
  function tab(indent number, spaces boolean) return varchar2 as
    i varchar(200) := '';
  begin
    if(not spaces) then return ''; end if;
    for x in 1 .. indent loop i := i || indent_string; end loop;
    return i;
  end;
  
  function getCommaSep(spaces boolean) return varchar2 as
  begin
    if(spaces) then return ', '; else return ','; end if;
  end;

  function getMemName(mem json_value, spaces boolean) return varchar2 as
  begin
    if(spaces) then
      return llcheck('"'||escapeString(mem.mapname)||'"') || llcheck(' : ');
    else 
      return llcheck('"'||escapeString(mem.mapname)||'"') || llcheck(':');
    end if;
  end;

/* Clob method start here */
  procedure add_to_clob(buf_lob in out nocopy clob, buf_str in out nocopy varchar2, str varchar2) as
  begin
    if(lengthb(str) > 32767 - lengthb(buf_str)) then
--      dbms_lob.append(buf_lob, buf_str);
      dbms_lob.writeappend(buf_lob, length(buf_str), buf_str);
      buf_str := str;
    else
      buf_str := buf_str || str;
    end if;  
  end add_to_clob;

  procedure flush_clob(buf_lob in out nocopy clob, buf_str in out nocopy varchar2) as
  begin
--    dbms_lob.append(buf_lob, buf_str);
    dbms_lob.writeappend(buf_lob, length(buf_str), buf_str);
  end flush_clob;

  procedure ppObj(obj json, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2);

  procedure ppEA(input json_list, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2) as
    elem json_value; 
    arr json_value_array := input.list_data;
    numbuf varchar2(4000);
  begin
    for y in 1 .. arr.count loop
      elem := arr(y);
      if(elem is not null) then
      case elem.get_type
        when 'number' then 
          numbuf := '';
          if (elem.get_number < 1 and elem.get_number > 0) then numbuf := '0'; end if;
          if (elem.get_number < 0 and elem.get_number > -1) then 
            numbuf := '-0'; 
            numbuf := numbuf || substr(to_char(elem.get_number, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,'''),2);
          else
            numbuf := numbuf || to_char(elem.get_number, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
          end if;
          add_to_clob(buf, buf_str, llcheck(numbuf));
        when 'string' then 
          if(elem.extended_str is not null) then --clob implementation
            add_to_clob(buf, buf_str, case when elem.num = 1 then '"' else '/**/' end);
            declare
              offset number := 1;
              v_str varchar(32767);
              amount number := 32767;
            begin
              while(offset <= dbms_lob.getlength(elem.extended_str)) loop
                dbms_lob.read(elem.extended_str, amount, offset, v_str);
                if(elem.num = 1) then 
                  add_to_clob(buf, buf_str, escapeString(v_str));
                else 
                  add_to_clob(buf, buf_str, v_str);
                end if;
                offset := offset + amount;
              end loop;
            end;
            add_to_clob(buf, buf_str, case when elem.num = 1 then '"' else '/**/' end || newline_char);
          else
            if(elem.num = 1) then 
              add_to_clob(buf, buf_str, llcheck('"'||escapeString(elem.get_string)||'"'));
            else 
              add_to_clob(buf, buf_str, llcheck('/**/'||elem.get_string||'/**/'));
            end if;
          end if;
        when 'bool' then
          if(elem.get_bool) then 
            add_to_clob(buf, buf_str, llcheck('true'));
          else
            add_to_clob(buf, buf_str, llcheck('false'));
          end if;
        when 'null' then
          add_to_clob(buf, buf_str, llcheck('null'));
        when 'array' then
          add_to_clob(buf, buf_str, llcheck('['));
          ppEA(json_list(elem), indent, buf, spaces, buf_str);
          add_to_clob(buf, buf_str, llcheck(']'));
        when 'object' then
          ppObj(json(elem), indent, buf, spaces, buf_str);
        else add_to_clob(buf, buf_str, llcheck(elem.get_type));
      end case;
      end if;
      if(y != arr.count) then add_to_clob(buf, buf_str, llcheck(getCommaSep(spaces))); end if;
    end loop;
  end ppEA;

  procedure ppMem(mem json_value, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2) as
    numbuf varchar2(4000);
  begin
    add_to_clob(buf, buf_str, llcheck(tab(indent, spaces)) || llcheck(getMemName(mem, spaces)));
    case mem.get_type
      when 'number' then 
        if (mem.get_number < 1 and mem.get_number > 0) then numbuf := '0'; end if;
        if (mem.get_number < 0 and mem.get_number > -1) then 
          numbuf := '-0'; 
          numbuf := numbuf || substr(to_char(mem.get_number, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,'''),2);
        else
          numbuf := numbuf || to_char(mem.get_number, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
        end if;
        add_to_clob(buf, buf_str, llcheck(numbuf));
      when 'string' then 
        if(mem.extended_str is not null) then --clob implementation
          add_to_clob(buf, buf_str, case when mem.num = 1 then '"' else '/**/' end);
          declare
            offset number := 1;
            v_str varchar(32767);
            amount number := 32767;
          begin
--            dbms_output.put_line('SIZE:'||dbms_lob.getlength(mem.extended_str));
            while(offset <= dbms_lob.getlength(mem.extended_str)) loop
--            dbms_output.put_line('OFFSET:'||offset);
 --             v_str := dbms_lob.substr(mem.extended_str, 8192, offset);
              dbms_lob.read(mem.extended_str, amount, offset, v_str);
--            dbms_output.put_line('VSTR_SIZE:'||length(v_str));
              if(mem.num = 1) then 
                add_to_clob(buf, buf_str, escapeString(v_str));
              else 
                add_to_clob(buf, buf_str, v_str);
              end if;
              offset := offset + amount;
            end loop;
          end;
          add_to_clob(buf, buf_str, case when mem.num = 1 then '"' else '/**/' end || newline_char);
        else 
          if(mem.num = 1) then 
            add_to_clob(buf, buf_str, llcheck('"'||escapeString(mem.get_string)||'"'));
          else 
            add_to_clob(buf, buf_str, llcheck('/**/'||mem.get_string||'/**/'));
          end if;
        end if;
      when 'bool' then
        if(mem.get_bool) then 
          add_to_clob(buf, buf_str, llcheck('true'));
        else
          add_to_clob(buf, buf_str, llcheck('false'));
        end if;
      when 'null' then
        add_to_clob(buf, buf_str, llcheck('null'));
      when 'array' then
        add_to_clob(buf, buf_str, llcheck('['));
        ppEA(json_list(mem), indent, buf, spaces, buf_str);
        add_to_clob(buf, buf_str, llcheck(']'));
      when 'object' then
        ppObj(json(mem), indent, buf, spaces, buf_str);
      else add_to_clob(buf, buf_str, llcheck(mem.get_type));
    end case;
  end ppMem;

  procedure ppObj(obj json, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2) as
  begin
    add_to_clob(buf, buf_str, llcheck('{') || newline(spaces));
    for m in 1 .. obj.json_data.count loop
      ppMem(obj.json_data(m), indent+1, buf, spaces, buf_str);
      if(m != obj.json_data.count) then 
        add_to_clob(buf, buf_str, llcheck(',') || newline(spaces));
      else 
        add_to_clob(buf, buf_str, newline(spaces)); 
      end if;
    end loop;
    add_to_clob(buf, buf_str, llcheck(tab(indent, spaces)) || llcheck('}')); -- || chr(13);
  end ppObj;
  
  procedure pretty_print(obj json, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true) as 
    buf_str varchar2(32767);
    amount number := dbms_lob.getlength(buf);
  begin
    if(erase_clob and amount > 0) then dbms_lob.trim(buf, 0); dbms_lob.erase(buf, amount); end if;
    
    max_line_len := line_length;
    cur_line_len := 0;
    ppObj(obj, 0, buf, spaces, buf_str);  
    flush_clob(buf, buf_str);
  end;

  procedure pretty_print_list(obj json_list, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true) as 
    buf_str varchar2(32767);
    amount number := dbms_lob.getlength(buf);
  begin
    if(erase_clob and amount > 0) then dbms_lob.trim(buf, 0); dbms_lob.erase(buf, amount); end if;
    
    max_line_len := line_length;
    cur_line_len := 0;
    add_to_clob(buf, buf_str, llcheck('['));
    ppEA(obj, 0, buf, spaces, buf_str);  
    add_to_clob(buf, buf_str, llcheck(']'));
    flush_clob(buf, buf_str);
  end;

  procedure pretty_print_any(json_part json_value, spaces boolean default true, buf in out nocopy clob, line_length number default 0, erase_clob boolean default true) as
    buf_str varchar2(32767) := '';
    numbuf varchar2(4000);
    amount number := dbms_lob.getlength(buf);
  begin
    if(erase_clob and amount > 0) then dbms_lob.trim(buf, 0); dbms_lob.erase(buf, amount); end if;
    
    case json_part.get_type
      when 'number' then 
        if (json_part.get_number < 1 and json_part.get_number > 0) then numbuf := '0'; end if;
        if (json_part.get_number < 0 and json_part.get_number > -1) then 
          numbuf := '-0'; 
          numbuf := numbuf || substr(to_char(json_part.get_number, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,'''),2);
        else
          numbuf := numbuf || to_char(json_part.get_number, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
        end if;
        add_to_clob(buf, buf_str, numbuf);
      when 'string' then 
        if(json_part.extended_str is not null) then --clob implementation
          add_to_clob(buf, buf_str, case when json_part.num = 1 then '"' else '/**/' end);
          declare
            offset number := 1;
            v_str varchar(32767);
            amount number := 32767;
          begin
            while(offset <= dbms_lob.getlength(json_part.extended_str)) loop
              dbms_lob.read(json_part.extended_str, amount, offset, v_str);
              if(json_part.num = 1) then 
                add_to_clob(buf, buf_str, escapeString(v_str));
              else 
                add_to_clob(buf, buf_str, v_str);
              end if;
              offset := offset + amount;
            end loop;
          end;
          add_to_clob(buf, buf_str, case when json_part.num = 1 then '"' else '/**/' end);
        else 
          if(json_part.num = 1) then 
            add_to_clob(buf, buf_str, llcheck('"'||escapeString(json_part.get_string)||'"'));
          else 
            add_to_clob(buf, buf_str, llcheck('/**/'||json_part.get_string||'/**/'));
          end if;
        end if;
      when 'bool' then
	      if(json_part.get_bool) then
          add_to_clob(buf, buf_str, 'true');
        else
          add_to_clob(buf, buf_str, 'false');
        end if;
      when 'null' then
        add_to_clob(buf, buf_str, 'null');
      when 'array' then
        pretty_print_list(json_list(json_part), spaces, buf, line_length);
        return;
      when 'object' then
        pretty_print(json(json_part), spaces, buf, line_length);
        return;
      else add_to_clob(buf, buf_str, 'unknown type:'|| json_part.get_type);
    end case;
    flush_clob(buf, buf_str);
  end;

/* Clob method end here */

/* Varchar2 method start here */

  procedure ppObj(obj json, indent number, buf in out nocopy varchar2, spaces boolean);

  procedure ppEA(input json_list, indent number, buf in out varchar2, spaces boolean) as
    elem json_value; 
    arr json_value_array := input.list_data;
    str varchar2(400);
  begin
    for y in 1 .. arr.count loop
      elem := arr(y);
      if(elem is not null) then
      case elem.get_type
        when 'number' then 
          str := '';
          if (elem.get_number < 1 and elem.get_number > 0) then str := '0'; end if;
          if (elem.get_number < 0 and elem.get_number > -1) then 
            str := '-0' || substr(to_char(elem.get_number, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,'''),2);
          else
            str := str || to_char(elem.get_number, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
          end if;
          buf := buf || llcheck(str);
        when 'string' then 
          if(elem.num = 1) then 
            buf := buf || llcheck('"'||escapeString(elem.get_string)||'"');
          else 
            buf := buf || llcheck('/**/'||elem.get_string||'/**/');
          end if;
        when 'bool' then
          if(elem.get_bool) then           
            buf := buf || llcheck('true');
          else
            buf := buf || llcheck('false');
          end if;
        when 'null' then
          buf := buf || llcheck('null');
        when 'array' then
          buf := buf || llcheck('[');
          ppEA(json_list(elem), indent, buf, spaces);
          buf := buf || llcheck(']');
        when 'object' then
          ppObj(json(elem), indent, buf, spaces);
        else buf := buf || llcheck(elem.get_type); /* should never happen */
      end case;
      end if;
      if(y != arr.count) then buf := buf || llcheck(getCommaSep(spaces)); end if;
    end loop;
  end ppEA;

  procedure ppMem(mem json_value, indent number, buf in out nocopy varchar2, spaces boolean) as
    str varchar2(400) := '';
  begin
    buf := buf || llcheck(tab(indent, spaces)) || getMemName(mem, spaces);
    case mem.get_type
      when 'number' then 
        if (mem.get_number < 1 and mem.get_number > 0) then str := '0'; end if;
        if (mem.get_number < 0 and mem.get_number > -1) then 
          str := '-0' || substr(to_char(mem.get_number, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,'''),2);
        else
          str := str || to_char(mem.get_number, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
        end if;
        buf := buf || llcheck(str);
      when 'string' then 
        if(mem.num = 1) then 
          buf := buf || llcheck('"'||escapeString(mem.get_string)||'"');
        else 
          buf := buf || llcheck('/**/'||mem.get_string||'/**/');
        end if;
      when 'bool' then
        if(mem.get_bool) then 
          buf := buf || llcheck('true');
        else 
          buf := buf || llcheck('false');
        end if;
      when 'null' then
        buf := buf || llcheck('null');
      when 'array' then
        buf := buf || llcheck('[');
        ppEA(json_list(mem), indent, buf, spaces);
        buf := buf || llcheck(']');
      when 'object' then
        ppObj(json(mem), indent, buf, spaces);
      else buf := buf || llcheck(mem.get_type); /* should never happen */
    end case;
  end ppMem;
  
  procedure ppObj(obj json, indent number, buf in out nocopy varchar2, spaces boolean) as
  begin
    buf := buf || llcheck('{') || newline(spaces);
    for m in 1 .. obj.json_data.count loop
      ppMem(obj.json_data(m), indent+1, buf, spaces);
      if(m != obj.json_data.count) then buf := buf || llcheck(',') || newline(spaces);
      else buf := buf || newline(spaces); end if;
    end loop;
    buf := buf || llcheck(tab(indent, spaces)) || llcheck('}'); -- || chr(13);
  end ppObj;
  
  function pretty_print(obj json, spaces boolean default true, line_length number default 0) return varchar2 as
    buf varchar2(32767) := '';
  begin
    max_line_len := line_length;
    cur_line_len := 0;
    ppObj(obj, 0, buf, spaces);
    return buf;
  end pretty_print;

  function pretty_print_list(obj json_list, spaces boolean default true, line_length number default 0) return varchar2 as
    buf varchar2(32767);
  begin
    max_line_len := line_length;
    cur_line_len := 0;
    buf := llcheck('[');
    ppEA(obj, 0, buf, spaces);
    buf := buf || llcheck(']');
    return buf;
  end;

  function pretty_print_any(json_part json_value, spaces boolean default true, line_length number default 0) return varchar2 as
    buf varchar2(32767) := '';    
  begin
    case json_part.get_type
      when 'number' then 
        if (json_part.get_number() < 1 and json_part.get_number() > 0) then buf := buf || '0'; end if;
        if (json_part.get_number() < 0 and json_part.get_number() > -1) then 
          buf := buf || '-0'; 
          buf := buf || substr(to_char(json_part.get_number(), 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,'''),2);
        else
          buf := buf || to_char(json_part.get_number(), 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
        end if;
      when 'string' then 
        if(json_part.num = 1) then 
          buf := buf || '"'||escapeString(json_part.get_string)||'"';
        else 
          buf := buf || '/**/'||json_part.get_string||'/**/';
        end if;
      when 'bool' then
      	if(json_part.get_bool) then buf := 'true'; else buf := 'false'; end if;
      when 'null' then
        buf := 'null';
      when 'array' then
        buf := pretty_print_list(json_list(json_part), spaces, line_length);
      when 'object' then
        buf := pretty_print(json(json_part), spaces, line_length);
      else buf := 'weird error: '|| json_part.get_type;
    end case;
    return buf;
  end;
  
  procedure dbms_output_clob(my_clob clob, delim varchar2, jsonp varchar2 default null) as 
    prev number := 1;
    indx number := 1;
    size_of_nl number := lengthb(delim);
    v_str varchar2(32767);
    amount number := 32767;
  begin
    if(jsonp is not null) then dbms_output.put_line(jsonp||'('); end if;
    while(indx != 0) loop
      --read every line
      indx := dbms_lob.instr(my_clob, delim, prev+1);
 --     dbms_output.put_line(prev || ' to ' || indx);
      
      if(indx = 0) then
        --emit from prev to end;
        amount := 32767;
 --       dbms_output.put_line(' mycloblen ' || dbms_lob.getlength(my_clob));
        loop
          dbms_lob.read(my_clob, amount, prev, v_str);
          dbms_output.put_line(v_str);
          prev := prev+amount-1;
          exit when prev >= dbms_lob.getlength(my_clob);
        end loop;
      else 
        amount := indx - prev;
        if(amount > 32767) then 
          amount := 32767;
--          dbms_output.put_line(' mycloblen ' || dbms_lob.getlength(my_clob));
          loop
            dbms_lob.read(my_clob, amount, prev, v_str);
            dbms_output.put_line(v_str);
            prev := prev+amount-1;
            amount := indx - prev;
            exit when prev >= indx - 1;
            if(amount > 32767) then amount := 32767; end if;
          end loop;
          prev := indx + size_of_nl;
        else 
          dbms_lob.read(my_clob, amount, prev, v_str);
          dbms_output.put_line(v_str);     
          prev := indx + size_of_nl;
        end if;
      end if;
    
    end loop;
    if(jsonp is not null) then dbms_output.put_line(')'); end if;

/*    while (amount != 0) loop
      indx := dbms_lob.instr(my_clob, delim, prev+1);
      
--      dbms_output.put_line(prev || ' to ' || indx);
      if(indx = 0) then 
        indx := dbms_lob.getlength(my_clob)+1;
      end if;

      if(indx-prev > 32767) then
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
      if(amount = 32767) then prev := prev-size_of_nl-1; end if;
    end loop;
    if(jsonp is not null) then dbms_output.put_line(')'); end if;*/
  end;


/*  procedure dbms_output_clob(my_clob clob, delim varchar2, jsonp varchar2 default null) as 
    prev number := 1;
    indx number := 1;
    size_of_nl number := lengthb(delim);
    v_str varchar2(32767);
    amount number;
  begin
    if(jsonp is not null) then dbms_output.put_line(jsonp||'('); end if;
    while (indx != 0) loop
      indx := dbms_lob.instr(my_clob, delim, prev+1);
      
--      dbms_output.put_line(prev || ' to ' || indx);
      if(indx-prev > 32767) then
        indx := prev+32767;
      end if;
--      dbms_output.put_line(prev || ' to ' || indx);
      --substr doesnt work properly on all platforms! (come on oracle - error on Oracle VM for virtualbox)
      if(indx = 0) then 
--        dbms_output.put_line(dbms_lob.substr(my_clob, dbms_lob.getlength(my_clob)-prev+size_of_nl, prev));
        amount := dbms_lob.getlength(my_clob)-prev+size_of_nl;
        dbms_lob.read(my_clob, amount, prev, v_str);
      else 
--        dbms_output.put_line(dbms_lob.substr(my_clob, indx-prev, prev));
        amount := indx-prev;
--        dbms_output.put_line('amount'||amount);
        dbms_lob.read(my_clob, amount, prev, v_str);
      end if;
      dbms_output.put_line(v_str);
      prev := indx+size_of_nl;
      if(amount = 32767) then prev := prev-size_of_nl-1; end if;
    end loop;
    if(jsonp is not null) then dbms_output.put_line(')'); end if;
  end;
*/  
  procedure htp_output_clob(my_clob clob, jsonp varchar2 default null) as 
    /*amount number := 4096;
    pos number := 1;
    len number;
    */
    l_amt    number default 30;
    l_off   number default 1;
    l_str   varchar2(4096);
    
  begin
    if(jsonp is not null) then htp.prn(jsonp||'('); end if;
    
    begin
      loop
        dbms_lob.read( my_clob, l_amt, l_off, l_str );

        -- it is vital to use htp.PRN to avoid 
        -- spurious line feeds getting added to your
        -- document
        htp.prn( l_str  );
        l_off := l_off+l_amt;
        l_amt := 4096;
      end loop;
    exception
      when no_data_found then NULL;
    end;
        
    /*
    len := dbms_lob.getlength(my_clob);
    
    while(pos < len) loop
      htp.prn(dbms_lob.substr(my_clob, amount, pos)); -- should I replace substr with dbms_lob.read?
      --dbms_output.put_line(dbms_lob.substr(my_clob, amount, pos)); 
      pos := pos + amount;
    end loop;
    */
    if(jsonp is not null) then htp.prn(')'); end if;
  end;

end json_printer;
/
