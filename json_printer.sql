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
  indent_string varchar2(10) := '  '; --chr(9); for tab
  newline_char varchar2(2) := chr(13)||chr(10); -- Windows style
  --newline_char varchar2(2) := chr(10); -- Mac style
  --newline_char varchar2(2) := chr(13); -- Linux style

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

  function getMemName(mem json_member, spaces boolean) return varchar2 as
  begin
    if(spaces) then
      return '"' || mem.member_name || '" : ';
    else 
      return '"' || mem.member_name || '":';
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
    elem json_element; 
    arr json_element_array := input.list_data;
  begin
    for y in 1 .. arr.count loop
      elem := arr(y);
      if(elem is not null) then
      case elem.element_data.get_type
        when 'number' then 
          add_to_clob(buf, buf_str, to_char(elem.element_data.get_number, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,'''));
        when 'string' then 
          add_to_clob(buf, buf_str, '"' || elem.element_data.get_string || '"');
        when 'bool' then
          if(elem.element_data.get_bool) then 
            add_to_clob(buf, buf_str, 'true');
          else
            add_to_clob(buf, buf_str, 'false');
          end if;
        when 'null' then
          add_to_clob(buf, buf_str, 'null');
        when 'array' then
          add_to_clob(buf, buf_str, '[');
          ppEA(json_list(elem.element_data), indent, buf, spaces, buf_str);
          add_to_clob(buf, buf_str, ']');
        when 'object' then
          ppObj(json(elem.element_data), indent, buf, spaces, buf_str);
        else add_to_clob(buf, buf_str, elem.element_data.get_type);
      end case;
      end if;
      if(y != arr.count) then add_to_clob(buf, buf_str, getCommaSep(spaces)); end if;
    end loop;
  end ppEA;

  procedure ppMem(mem json_member, indent number, buf in out nocopy clob, spaces boolean, buf_str in out nocopy varchar2) as
  begin
    add_to_clob(buf, buf_str, tab(indent, spaces) || getMemName(mem, spaces));
    case mem.member_data.get_type
      when 'number' then 
        add_to_clob(buf, buf_str, to_char(mem.member_data.get_number, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,'''));
      when 'string' then 
        add_to_clob(buf, buf_str, '"' || mem.member_data.get_string || '"');
      when 'bool' then
        if(mem.member_data.get_bool) then 
          add_to_clob(buf, buf_str, 'true');
        else
          add_to_clob(buf, buf_str, 'false');
        end if;
      when 'null' then
        add_to_clob(buf, buf_str, 'null');
      when 'array' then
        add_to_clob(buf, buf_str, '[');
        ppEA(json_list(mem.member_data), indent, buf, spaces, buf_str);
        add_to_clob(buf, buf_str, ']');
      when 'object' then
        ppObj(json(mem.member_data), indent, buf, spaces, buf_str);
      else add_to_clob(buf, buf_str, mem.member_data.get_type);
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
        add_to_clob(buf, buf_str, json_part.get_string);
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
    elem json_element; 
    arr json_element_array := input.list_data;
  begin
    for y in 1 .. arr.count loop
      elem := arr(y);
      if(elem is not null) then
      case elem.element_data.get_type
        when 'number' then 
          buf := buf || to_char(elem.element_data.get_number, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,''');
        when 'string' then 
          buf := buf || '"' || elem.element_data.get_string || '"';
        when 'bool' then
          if(elem.element_data.get_bool) then           
            buf := buf || 'true';
          else
            buf := buf || 'false';
          end if;
        when 'null' then
          buf := buf || 'null';
        when 'array' then
          buf := buf || '[';
          ppEA(json_list(elem.element_data), indent, buf, spaces);
          buf := buf || ']';
        when 'object' then
          ppObj(json(elem.element_data), indent, buf, spaces);
        else buf := buf || elem.element_data.get_type; /* should never happen */
      end case;
      end if;
      if(y != arr.count) then buf := buf || getCommaSep(spaces); end if;
    end loop;
  end ppEA;

  procedure ppMem(mem json_member, indent number, buf in out nocopy varchar2, spaces boolean) as
  begin
    buf := buf || tab(indent, spaces) || getMemName(mem, spaces);
    case mem.member_data.get_type
      when 'number' then 
        buf := buf || to_char(mem.member_data.get_number, 'TM', 'NLS_NUMERIC_CHARACTERS=''.,''');
      when 'string' then 
        buf := buf || '"' || mem.member_data.get_string || '"';
      when 'bool' then
        if(mem.member_data.get_bool) then 
	  buf := buf || 'true';
        else 
	  buf := buf || 'false';
        end if;
      when 'null' then
        buf := buf || 'null';
      when 'array' then
        buf := buf || '[';
        ppEA(json_list(mem.member_data), indent, buf, spaces);
        buf := buf || ']';
      when 'object' then
        ppObj(json(mem.member_data), indent, buf, spaces);
      else buf := buf || mem.member_data.get_type; /* should never happen */
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
        buf := json_part.get_string();
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

