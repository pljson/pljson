create or replace package json_printer as
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
  indent_string varchar2(10 char) := '  '; --chr(9); for tab
  newline_char varchar2(2 char) := chr(13)||chr(10); -- Windows style
  --newline_char varchar2(2) := chr(10); -- Mac style
  --newline_char varchar2(2) := chr(13); -- Linux style
  ascii_output boolean := true;

  function pretty_print(obj json, spaces boolean default true) return varchar2;
  function pretty_print_list(obj json_list, spaces boolean default true) return varchar2;
  function pretty_print_any(json_part json_value, spaces boolean default true) return varchar2;
  procedure pretty_print(obj json, spaces boolean default true, buf in out nocopy clob);
  procedure pretty_print_list(obj json_list, spaces boolean default true, buf in out nocopy clob);
  procedure pretty_print_any(json_part json_value, spaces boolean default true, buf in out nocopy clob);
end json_printer;
/

create or replace
package body "JSON_PRINTER" as

  function escapeString(str varchar2) return varchar2 as
    sb varchar2(32767) := '';
    buf varchar2(40);
    num number;
  begin
    if(str is null) then return '""'; end if;
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
      when chr(47) then buf := '\/';
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
  
    return '"'||sb||'"';
  end escapeString;

  function newline(spaces boolean) return varchar2 as
  begin
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
      return escapeString(mem.mapname) || ' : ';
    else 
      return escapeString(mem.mapname) || ':';
    end if;
  end;

/* Clob method start here */
  procedure add_to_clob(buf_lob in out nocopy clob, buf_str in out nocopy varchar2, str varchar2) as
  begin
    if(length(str) > 32767 - length(buf_str)) then
      dbms_lob.append(buf_lob, buf_str);
      buf_str := str;
    else
      buf_str := buf_str || str;
    end if;  
  end add_to_clob;

  procedure flush_clob(buf_lob in out nocopy clob, buf_str in out nocopy varchar2) as
  begin
    dbms_lob.append(buf_lob, buf_str);
  end flush_clob;

  procedure ppObj(obj json, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2);

  procedure ppEA(input json_list, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2) as
    elem json_value; 
    arr json_value_array := input.list_data;
  begin
    for y in 1 .. arr.count loop
      elem := arr(y);
      if(elem is not null) then
      case elem.get_type
        when 'number' then 
          add_to_clob(buf, buf_str, to_char(elem.get_number, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,'''));
        when 'string' then 
          if(elem.num = 1) then 
            add_to_clob(buf, buf_str, escapeString(elem.get_string));
          else 
            add_to_clob(buf, buf_str, elem.get_string);
          end if;
        when 'bool' then
          if(elem.get_bool) then 
            add_to_clob(buf, buf_str, 'true');
          else
            add_to_clob(buf, buf_str, 'false');
          end if;
        when 'null' then
          add_to_clob(buf, buf_str, 'null');
        when 'array' then
          add_to_clob(buf, buf_str, '[');
          ppEA(json_list(elem), indent, buf, spaces, buf_str);
          add_to_clob(buf, buf_str, ']');
        when 'object' then
          ppObj(json(elem), indent, buf, spaces, buf_str);
        else add_to_clob(buf, buf_str, elem.get_type);
      end case;
      end if;
      if(y != arr.count) then add_to_clob(buf, buf_str, getCommaSep(spaces)); end if;
    end loop;
  end ppEA;

  procedure ppMem(mem json_value, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2) as
  begin
    add_to_clob(buf, buf_str, tab(indent, spaces) || getMemName(mem, spaces));
    case mem.get_type
      when 'number' then 
        add_to_clob(buf, buf_str, to_char(mem.get_number, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,'''));
      when 'string' then 
        if(mem.num = 1) then 
          add_to_clob(buf, buf_str, escapeString(mem.get_string));
        else 
          add_to_clob(buf, buf_str, mem.get_string);
        end if;
      when 'bool' then
        if(mem.get_bool) then 
          add_to_clob(buf, buf_str, 'true');
        else
          add_to_clob(buf, buf_str, 'false');
        end if;
      when 'null' then
        add_to_clob(buf, buf_str, 'null');
      when 'array' then
        add_to_clob(buf, buf_str, '[');
        ppEA(json_list(mem), indent, buf, spaces, buf_str);
        add_to_clob(buf, buf_str, ']');
      when 'object' then
        ppObj(json(mem), indent, buf, spaces, buf_str);
      else add_to_clob(buf, buf_str, mem.get_type);
    end case;
  end ppMem;

  procedure ppObj(obj json, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2) as
  begin
    add_to_clob(buf, buf_str, '{' || newline(spaces));
    for m in 1 .. obj.json_data.count loop
      ppMem(obj.json_data(m), indent+1, buf, spaces, buf_str);
      if(m != obj.json_data.count) then 
        add_to_clob(buf, buf_str, ',' || newline(spaces));
      else 
        add_to_clob(buf, buf_str, newline(spaces)); 
      end if;
    end loop;
    add_to_clob(buf, buf_str, tab(indent, spaces) || '}'); -- || chr(13);
  end ppObj;
  
  procedure pretty_print(obj json, spaces boolean default true, buf in out nocopy clob) as 
    buf_str varchar2(32767);
  begin
    ppObj(obj, 0, buf, spaces, buf_str);  
    flush_clob(buf, buf_str);
  end;

  procedure pretty_print_list(obj json_list, spaces boolean default true, buf in out nocopy clob) as 
    buf_str varchar2(32767);
  begin
    add_to_clob(buf, buf_str, '[');
    ppEA(obj, 0, buf, spaces, buf_str);  
    add_to_clob(buf, buf_str, ']');
    flush_clob(buf, buf_str);
  end;

  procedure pretty_print_any(json_part json_value, spaces boolean default true, buf in out nocopy clob) as
    buf_str varchar2(32767) := '';
  begin
    case json_part.get_type
      when 'number' then 
        add_to_clob(buf, buf_str, to_char(json_part.get_number, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,'''));
      when 'string' then 
        if(json_part.num = 1) then 
          add_to_clob(buf, buf_str, escapeString(json_part.get_string));
        else 
          add_to_clob(buf, buf_str, json_part.get_string);
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
        pretty_print_list(json_list(json_part), spaces, buf);
        return;
      when 'object' then
        pretty_print(json(json_part), spaces, buf);
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
  begin
    for y in 1 .. arr.count loop
      elem := arr(y);
      if(elem is not null) then
      case elem.get_type
        when 'number' then 
          buf := buf || to_char(elem.get_number, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,''');
        when 'string' then 
          if(elem.num = 1) then 
            buf := buf || escapeString(elem.get_string);
          else 
            buf := buf || elem.get_string;
          end if;
        when 'bool' then
          if(elem.get_bool) then           
            buf := buf || 'true';
          else
            buf := buf || 'false';
          end if;
        when 'null' then
          buf := buf || 'null';
        when 'array' then
          buf := buf || '[';
          ppEA(json_list(elem), indent, buf, spaces);
          buf := buf || ']';
        when 'object' then
          ppObj(json(elem), indent, buf, spaces);
        else buf := buf || elem.get_type; /* should never happen */
      end case;
      end if;
      if(y != arr.count) then buf := buf || getCommaSep(spaces); end if;
    end loop;
  end ppEA;

  procedure ppMem(mem json_value, indent number, buf in out nocopy varchar2, spaces boolean) as
  begin
    buf := buf || tab(indent, spaces) || getMemName(mem, spaces);
    case mem.get_type
      when 'number' then 
        buf := buf || to_char(mem.get_number, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,''');
      when 'string' then 
        if(mem.num = 1) then 
          buf := buf || escapeString(mem.get_string);
        else 
          buf := buf || mem.get_string;
        end if;
      when 'bool' then
        if(mem.get_bool) then 
          buf := buf || 'true';
        else 
          buf := buf || 'false';
        end if;
      when 'null' then
        buf := buf || 'null';
      when 'array' then
        buf := buf || '[';
        ppEA(json_list(mem), indent, buf, spaces);
        buf := buf || ']';
      when 'object' then
        ppObj(json(mem), indent, buf, spaces);
      else buf := buf || mem.get_type; /* should never happen */
    end case;
  end ppMem;
  
  procedure ppObj(obj json, indent number, buf in out nocopy varchar2, spaces boolean) as
  begin
    buf := buf || '{' || newline(spaces);
    for m in 1 .. obj.json_data.count loop
      ppMem(obj.json_data(m), indent+1, buf, spaces);
      if(m != obj.json_data.count) then buf := buf || ',' || newline(spaces);
      else buf := buf || newline(spaces); end if;
    end loop;
    buf := buf || tab(indent, spaces) || '}'; -- || chr(13);
  end ppObj;
  
  function pretty_print(obj json, spaces boolean default true) return varchar2 as
    buf varchar2(32767) := '';
  begin
    ppObj(obj, 0, buf, spaces);
    return buf;
  end pretty_print;

  function pretty_print_list(obj json_list, spaces boolean default true) return varchar2 as
    buf varchar2(32767) := '[';
  begin
    ppEA(obj, 0, buf, spaces);
    buf := buf || ']';
    return buf;
  end;

  function pretty_print_any(json_part json_value, spaces boolean default true) return varchar2 as
    buf varchar2(32767) := '';
  begin
    case json_part.get_type
      when 'number' then 
        buf := to_char(json_part.get_number(), 'TM', 'NLS_NUMERIC_CHARACTERS=''.,''');
      when 'string' then 
        if(json_part.num = 1) then 
          buf := buf || escapeString(json_part.get_string);
        else 
          buf := buf || json_part.get_string;
        end if;
      when 'bool' then
      	if(json_part.get_bool) then buf := 'true'; else buf := 'false'; end if;
      when 'null' then
        buf := 'null';
      when 'array' then
        buf := pretty_print_list(json_list(json_part), spaces);
      when 'object' then
        buf := pretty_print(json(json_part), spaces);
      else buf := 'weird error: '|| json_part.get_type;
    end case;
    return buf;
  end;

end json_printer;
/

