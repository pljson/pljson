create or replace package json_parser as
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
  /* scanner tokens:
    '{', '}', ',', ':', '[', ']', STRING, NUMBER, TRUE, FALSE, NULL 
  */
  type rToken IS RECORD (
    type_name VARCHAR2(7),
    line PLS_INTEGER,
    col PLS_INTEGER,
    data VARCHAR2(32767),
    data_overflow clob); -- max_string_size

  type lTokens is table of rToken index by pls_integer;
  type json_src is record (len number, offset number, src varchar2(32767), s_clob clob); 

  json_strict boolean not null := false;

  function next_char(indx number, s in out nocopy json_src) return varchar2;
  function next_char2(indx number, s in out nocopy json_src, amount number default 1) return varchar2;
  
  function prepareClob(buf in clob) return json_parser.json_src;
  function prepareVarchar2(buf in varchar2) return json_parser.json_src;
  function lexer(jsrc in out nocopy json_src) return lTokens;
  procedure print_token(t rToken);

  function parser(str varchar2) return json;
  function parse_list(str varchar2) return json_list;
  function parse_any(str varchar2) return json_value;
  function parser(str clob) return json;
  function parse_list(str clob) return json_list;
  function parse_any(str clob) return json_value;
  procedure remove_duplicates(obj in out nocopy json);
  function get_version return varchar2;
  
end json_parser;
/

CREATE OR REPLACE PACKAGE BODY "JSON_PARSER" as
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
  
  decimalpoint varchar2(1 char) := '.';
  
  procedure updateDecimalPoint as
  begin
    SELECT substr(VALUE,1,1) into decimalpoint FROM NLS_SESSION_PARAMETERS WHERE PARAMETER = 'NLS_NUMERIC_CHARACTERS';
  end updateDecimalPoint;

  /*type json_src is record (len number, offset number, src varchar2(10), s_clob clob); */
  function next_char(indx number, s in out nocopy json_src) return varchar2 as
  begin
    if(indx > s.len) then return null; end if;
    --right offset?
    if(indx > 4000 + s.offset or indx < s.offset) then
    --load right offset
      s.offset := indx - (indx mod 4000);
      s.src := dbms_lob.substr(s.s_clob, 4000, s.offset+1);
    end if;
    --read from s.src
    return substr(s.src, indx-s.offset, 1);         
  end;
  
  function next_char2(indx number, s in out nocopy json_src, amount number default 1) return varchar2 as
    buf varchar2(32767) := '';
  begin
    for i in 1..amount loop
      buf := buf || next_char(indx-1+i,s);
    end loop;
    return buf;
  end;
  
  function prepareClob(buf clob) return json_parser.json_src as
    temp json_parser.json_src;
  begin
    temp.s_clob := buf;
    temp.offset := 0;
    temp.src := dbms_lob.substr(buf, 4000, temp.offset+1);
    temp.len := dbms_lob.getlength(buf);
    return temp;
  end;
  
  function prepareVarchar2(buf varchar2) return json_parser.json_src as
    temp json_parser.json_src;
  begin
    temp.s_clob := buf;
    temp.offset := 0;
    temp.src := substr(buf, 1, 4000);
    temp.len := length(buf);
    return temp;
  end;

  procedure debug(text varchar2) as
  begin
    dbms_output.put_line(text);
  end;
  
  procedure print_token(t rToken) as
  begin
    dbms_output.put_line('Line: '||t.line||' - Column: '||t.col||' - Type: '||t.type_name||' - Content: '||t.data);
  end print_token;
  
  /* SCANNER FUNCTIONS START */
  procedure s_error(text varchar2, line number, col number) as
  begin
    raise_application_error(-20100, 'JSON Scanner exception @ line: '||line||' column: '||col||' - '||text);
  end;

  procedure s_error(text varchar2, tok rToken) as
  begin
    raise_application_error(-20100, 'JSON Scanner exception @ line: '||tok.line||' column: '||tok.col||' - '||text);
  end;
  
  function mt(t varchar2, l pls_integer, c pls_integer, d varchar2) return rToken as
    token rToken;
  begin
    token.type_name := t;
    token.line := l;
    token.col := c;
    token.data := d;
    return token;
  end;

  function lexNumber(jsrc in out nocopy json_src, tok in out nocopy rToken, indx in out nocopy pls_integer) return pls_integer as
    numbuf varchar2(4000) := '';
    buf varchar2(4);
    checkLoop boolean;
  begin
    buf := next_char(indx, jsrc); 
    if(buf = '-') then numbuf := '-'; indx := indx + 1; end if;
    buf := next_char(indx, jsrc); 
    --0 or [1-9]([0-9])* 
    if(buf = '0') then 
      numbuf := numbuf || '0'; indx := indx + 1; 
      buf := next_char(indx, jsrc);  
    elsif(buf >= '1' and buf <= '9') then 
      numbuf := numbuf || buf; indx := indx + 1; 
      --read digits
      buf := next_char(indx, jsrc); 
      while(buf >= '0' and buf <= '9') loop
        numbuf := numbuf || buf; indx := indx + 1; 
        buf := next_char(indx, jsrc);  
      end loop;      
    end if;
    --fraction
    if(buf = '.') then
      numbuf := numbuf || buf; indx := indx + 1; 
      buf := next_char(indx, jsrc); 
      checkLoop := FALSE;
      while(buf >= '0' and buf <= '9') loop
        checkLoop := TRUE;
        numbuf := numbuf || buf; indx := indx + 1; 
        buf := next_char(indx, jsrc);  
      end loop; 
      if(not checkLoop) then
        s_error('Expected: digits in fraction', tok);
      end if;
    end if;
    --exp part
    if(buf in ('e', 'E')) then
      numbuf := numbuf || buf; indx := indx + 1; 
      buf := next_char(indx, jsrc); 
      if(buf = '+' or buf = '-') then 
        numbuf := numbuf || buf; indx := indx + 1; 
        buf := next_char(indx, jsrc);  
      end if;
      checkLoop := FALSE;
      while(buf >= '0' and buf <= '9') loop
        checkLoop := TRUE;
        numbuf := numbuf || buf; indx := indx + 1; 
        buf := next_char(indx, jsrc); 
      end loop;      
      if(not checkLoop) then
        s_error('Expected: digits in exp', tok);
      end if;
    end if;
    
    tok.data := numbuf;
    return indx;
  end lexNumber;
  
  -- [a-zA-Z]([a-zA-Z0-9])*
  function lexName(jsrc in out nocopy json_src, tok in out nocopy rToken, indx in out nocopy pls_integer) return pls_integer as
    varbuf varchar2(32767) := '';
    buf varchar(4);
    num number;
  begin
    buf := next_char(indx, jsrc); 
    while(REGEXP_LIKE(buf, '^[[:alnum:]\_]$', 'i')) loop
      varbuf := varbuf || buf;
      indx := indx + 1;
      buf := next_char(indx, jsrc); 
      if (buf is null) then 
        goto retname;
        --debug('Premature string ending');
      end if;
    end loop;
    <<retname>>
    
    --could check for reserved keywords here

    --debug(varbuf);
    tok.data := varbuf;
    return indx-1;
  end lexName;
  
  procedure updateClob(v_extended in out nocopy clob, v_str varchar2) as
  begin
    dbms_lob.writeappend(v_extended, length(v_str), v_str);
  end updateClob;

  function lexString(jsrc in out nocopy json_src, tok in out nocopy rToken, indx in out nocopy pls_integer, endChar char) return pls_integer as
    v_extended clob := null; v_count number := 0;
    varbuf varchar2(32767) := '';
    buf varchar(4);
    wrong boolean;
  begin
    indx := indx +1;
    buf := next_char(indx, jsrc); 
    while(buf != endChar) loop
      --clob control
      if(v_count > 8191) then --crazy oracle error (16383 is the highest working length with unistr - 8192 choosen to be safe)
        if(v_extended is null) then 
          v_extended := empty_clob();
          dbms_lob.createtemporary(v_extended, true); 
        end if;
        updateClob(v_extended, unistr(varbuf));
        varbuf := ''; v_count := 0;
      end if;
      if(buf = Chr(13) or buf = CHR(9) or buf = CHR(10)) then
        s_error('Control characters not allowed (CHR(9),CHR(10)CHR(13))', tok);
      end if;
      if(buf = '\') then
        --varbuf := varbuf || buf;
        indx := indx + 1;
        buf := next_char(indx, jsrc);  
        case
          when buf in ('\') then
            varbuf := varbuf || buf || buf; v_count := v_count + 2;
            indx := indx + 1;
            buf := next_char(indx, jsrc);  
          when buf in ('"', '/') then
            varbuf := varbuf || buf; v_count := v_count + 1;
            indx := indx + 1;
            buf := next_char(indx, jsrc);  
          when buf = '''' then
            if(json_strict = false) then 
              varbuf := varbuf || buf; v_count := v_count + 1;
              indx := indx + 1;
              buf := next_char(indx, jsrc);  
            else 
              s_error('strictmode - expected: " \ / b f n r t u ', tok);
            end if;
          when buf in ('b', 'f', 'n', 'r', 't') then
            --backspace b = U+0008
            --formfeed  f = U+000C
            --newline   n = U+000A
            --carret    r = U+000D
            --tabulator t = U+0009
            case buf
            when 'b' then varbuf := varbuf || chr(8);
            when 'f' then varbuf := varbuf || chr(13);
            when 'n' then varbuf := varbuf || chr(10);
            when 'r' then varbuf := varbuf || chr(14);
            when 't' then varbuf := varbuf || chr(9);
            end case;            
            --varbuf := varbuf || buf;
            v_count := v_count + 1;
            indx := indx + 1;
            buf := next_char(indx, jsrc);  
          when buf = 'u' then
            --four hexidecimal chars
            declare
              four varchar2(4);
            begin
              four := next_char2(indx+1, jsrc, 4);
              wrong := FALSE;              
              if(upper(substr(four, 1,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','a','b','c','d','e','f')) then wrong := TRUE; end if;
              if(upper(substr(four, 2,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','a','b','c','d','e','f')) then wrong := TRUE; end if;
              if(upper(substr(four, 3,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','a','b','c','d','e','f')) then wrong := TRUE; end if;
              if(upper(substr(four, 4,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','a','b','c','d','e','f')) then wrong := TRUE; end if;
              if(wrong) then
                s_error('expected: " \u([0-9][A-F]){4}', tok);
              end if;
--              varbuf := varbuf || buf || four;
              varbuf := varbuf || '\'||four;--chr(to_number(four,'XXXX'));
               v_count := v_count + 5;
              indx := indx + 5;
              buf := next_char(indx, jsrc); 
              end;
          else 
            s_error('expected: " \ / b f n r t u ', tok);
        end case;
      else
        varbuf := varbuf || buf; v_count := v_count + 1;
        indx := indx + 1;
        buf := next_char(indx, jsrc); 
      end if;
    end loop;
    
    if (buf is null) then 
      s_error('string ending not found', tok);
      --debug('Premature string ending');
    end if;

    --debug(varbuf);
    --dbms_output.put_line(varbuf);
    if(v_extended is not null) then 
      updateClob(v_extended, unistr(varbuf));
      tok.data_overflow := v_extended;
      tok.data := dbms_lob.substr(v_extended, 1, 32767);
    else 
      tok.data := unistr(varbuf);
    end if;
    return indx;
  end lexString;
  
  /* scanner tokens:
    '{', '}', ',', ':', '[', ']', STRING, NUMBER, TRUE, FALSE, NULL
  */
  function lexer(jsrc in out nocopy json_src) return lTokens as
    tokens lTokens;
    indx pls_integer := 1;
    tok_indx pls_integer := 1;
    buf varchar2(4);
    lin_no number := 1;
    col_no number := 0;
  begin
    while (indx <= jsrc.len) loop
      --read into buf
      buf := next_char(indx, jsrc); 
      col_no := col_no + 1;
      --convert to switch case
      case
        when buf = '{' then tokens(tok_indx) := mt('{', lin_no, col_no, null); tok_indx := tok_indx + 1;
        when buf = '}' then tokens(tok_indx) := mt('}', lin_no, col_no, null); tok_indx := tok_indx + 1;
        when buf = ',' then tokens(tok_indx) := mt(',', lin_no, col_no, null); tok_indx := tok_indx + 1;
        when buf = ':' then tokens(tok_indx) := mt(':', lin_no, col_no, null); tok_indx := tok_indx + 1;
        when buf = '[' then tokens(tok_indx) := mt('[', lin_no, col_no, null); tok_indx := tok_indx + 1;
        when buf = ']' then tokens(tok_indx) := mt(']', lin_no, col_no, null); tok_indx := tok_indx + 1;
        when buf = 't' then
          if(next_char2(indx, jsrc, 4) != 'true') then
            if(json_strict = false and REGEXP_LIKE(buf, '^[[:alpha:]]$', 'i')) then
              tokens(tok_indx) := mt('STRING', lin_no, col_no, null); 
              indx := lexName(jsrc, tokens(tok_indx), indx);
              col_no := col_no + length(tokens(tok_indx).data) + 1;
              tok_indx := tok_indx + 1; 
            else 
              s_error('Expected: ''true''', lin_no, col_no);
            end if;
          else
            tokens(tok_indx) := mt('TRUE', lin_no, col_no, null); tok_indx := tok_indx + 1; 
            indx := indx + 3;
            col_no := col_no + 3;
          end if;
        when buf = 'n' then
          if(next_char2(indx, jsrc, 4) != 'null') then
            if(json_strict = false and REGEXP_LIKE(buf, '^[[:alpha:]]$', 'i')) then
              tokens(tok_indx) := mt('STRING', lin_no, col_no, null); 
              indx := lexName(jsrc, tokens(tok_indx), indx);
              col_no := col_no + length(tokens(tok_indx).data) + 1;
              tok_indx := tok_indx + 1; 
            else 
              s_error('Expected: ''null''', lin_no, col_no);
            end if;
          else
            tokens(tok_indx) := mt('NULL', lin_no, col_no, null); tok_indx := tok_indx + 1; 
            indx := indx + 3;
            col_no := col_no + 3;
          end if;
        when buf = 'f' then
          if(next_char2(indx, jsrc, 5) != 'false') then
            if(json_strict = false and REGEXP_LIKE(buf, '^[[:alpha:]]$', 'i')) then
              tokens(tok_indx) := mt('STRING', lin_no, col_no, null); 
              indx := lexName(jsrc, tokens(tok_indx), indx);
              col_no := col_no + length(tokens(tok_indx).data) + 1;
              tok_indx := tok_indx + 1; 
            else 
              s_error('Expected: ''false''', lin_no, col_no);
            end if;
          else
            tokens(tok_indx) := mt('FALSE', lin_no, col_no, null); tok_indx := tok_indx + 1; 
            indx := indx + 4;
            col_no := col_no + 4;
          end if;
        /*   -- 9 = TAB, 10 = \n, 13 = \r (Linux = \n, Windows = \r\n, Mac = \r */        
        when (buf = Chr(10)) then --linux newlines
          lin_no := lin_no + 1;
          col_no := 0;
            
        when (buf = Chr(13)) then --Windows or Mac way
          lin_no := lin_no + 1;
          col_no := 0;
          if(jsrc.len >= indx +1) then -- better safe than sorry
            buf := next_char(indx+1, jsrc);
            if(buf = Chr(10)) then --\r\n
              indx := indx + 1;
            end if;
          end if;
      
        when (buf = CHR(9)) then null; --tabbing
        when (buf in ('-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9')) then --number
          tokens(tok_indx) := mt('NUMBER', lin_no, col_no, null); 
          indx := lexNumber(jsrc, tokens(tok_indx), indx)-1;
          col_no := col_no + length(tokens(tok_indx).data);
          tok_indx := tok_indx + 1; 
        when buf = '"' then --number
          tokens(tok_indx) := mt('STRING', lin_no, col_no, null); 
          indx := lexString(jsrc, tokens(tok_indx), indx, '"');
          col_no := col_no + length(tokens(tok_indx).data) + 1;
          tok_indx := tok_indx + 1; 
        when buf = '''' and json_strict = false then --number
          tokens(tok_indx) := mt('STRING', lin_no, col_no, null); 
          indx := lexString(jsrc, tokens(tok_indx), indx, '''');
          col_no := col_no + length(tokens(tok_indx).data) + 1; --hovsa her
          tok_indx := tok_indx + 1; 
        when json_strict = false and REGEXP_LIKE(buf, '^[[:alpha:]]$', 'i') then
          tokens(tok_indx) := mt('STRING', lin_no, col_no, null); 
          indx := lexName(jsrc, tokens(tok_indx), indx);
          if(tokens(tok_indx).data_overflow is not null) then
            col_no := col_no + dbms_lob.getlength(tokens(tok_indx).data_overflow) + 1;
          else 
            col_no := col_no + length(tokens(tok_indx).data) + 1;
          end if;
          tok_indx := tok_indx + 1; 
        when json_strict = false and buf||next_char(indx+1, jsrc) = '/*' then --strip comments
          declare
            saveindx number := indx;
            un_esc clob;
          begin
            indx := indx + 1;
            loop
              indx := indx + 1;
              buf := next_char(indx, jsrc)||next_char(indx+1, jsrc);
              exit when buf = '*/';
              exit when buf is null;
            end loop;
            
            if(indx = saveindx+2) then 
              --enter unescaped mode
              --dbms_output.put_line('Entering unescaped mode');
              un_esc := empty_clob();
              dbms_lob.createtemporary(un_esc, true); 
              indx := indx + 1;
              loop
                indx := indx + 1;
                buf := next_char(indx, jsrc)||next_char(indx+1, jsrc)||next_char(indx+2, jsrc)||next_char(indx+3, jsrc);
                exit when buf = '/**/';
                if buf is null then
                  s_error('Unexpected sequence /**/ to end unescaped data: '||buf, lin_no, col_no);
                end if;
                buf := next_char(indx, jsrc);
                dbms_lob.writeappend(un_esc, length(buf), buf);
              end loop;
              tokens(tok_indx) := mt('ESTRING', lin_no, col_no, null);     
              tokens(tok_indx).data_overflow := un_esc;
              col_no := col_no + dbms_lob.getlength(un_esc) + 1; --note: line count won't work properly
              tok_indx := tok_indx + 1; 
              indx := indx + 2;
            end if;
            
            indx := indx + 1;
          end;
        when buf = ' ' then null; --space
        else 
          s_error('Unexpected char: '||buf, lin_no, col_no);
      end case;
    
      indx := indx + 1;
    end loop;
  
    return tokens;
  end lexer;

  /* SCANNER END */
  
  /* PARSER FUNCTIONS START*/
  procedure p_error(text varchar2, tok rToken) as
  begin
    raise_application_error(-20101, 'JSON Parser exception @ line: '||tok.line||' column: '||tok.col||' - '||text);
  end;
  
  function parseObj(tokens lTokens, indx in out nocopy pls_integer) return json;

  function parseArr(tokens lTokens, indx in out nocopy pls_integer) return json_list as
    e_arr json_value_array := json_value_array();
    ret_list json_list := json_list();
    v_count number := 0;
    tok rToken;
  begin
    --value, value, value ]
    if(indx > tokens.count) then p_error('more elements in array was excepted', tok); end if;
    tok := tokens(indx);
    while(tok.type_name != ']') loop
      e_arr.extend;
      v_count := v_count + 1;
      case tok.type_name
        when 'TRUE' then e_arr(v_count) := json_value(true);
        when 'FALSE' then e_arr(v_count) := json_value(false);
        when 'NULL' then e_arr(v_count) := json_value;
        when 'STRING' then e_arr(v_count) := case when tok.data_overflow is not null then json_value(tok.data_overflow) else json_value(tok.data) end;
        when 'ESTRING' then e_arr(v_count) := json_value(tok.data_overflow, false);
        when 'NUMBER' then e_arr(v_count) := json_value(to_number(replace(tok.data, '.', decimalpoint))); 
        when '[' then 
          declare e_list json_list; begin
            indx := indx + 1;
            e_list := parseArr(tokens, indx);
            e_arr(v_count) := e_list.to_json_value;
          end;
        when '{' then 
          indx := indx + 1;
          e_arr(v_count) := parseObj(tokens, indx).to_json_value;
        else
          p_error('Expected a value', tok);
      end case;
      indx := indx + 1;
      if(indx > tokens.count) then p_error('] not found', tok); end if;
      tok := tokens(indx);
      if(tok.type_name = ',') then --advance
        indx := indx + 1;
        if(indx > tokens.count) then p_error('more elements in array was excepted', tok); end if;
        tok := tokens(indx);
        if(tok.type_name = ']') then --premature exit
          p_error('Premature exit in array', tok);
        end if;
      elsif(tok.type_name != ']') then --error
        p_error('Expected , or ]', tok);
      end if;

    end loop;
    ret_list.list_data := e_arr;
    return ret_list;
  end parseArr;
  
  function parseMem(tokens lTokens, indx in out pls_integer, mem_name varchar2, mem_indx number) return json_value as
    mem json_value;
    tok rToken;
  begin
    tok := tokens(indx);
    case tok.type_name
      when 'TRUE' then mem := json_value(true);
      when 'FALSE' then mem := json_value(false);
      when 'NULL' then mem := json_value;
      when 'STRING' then mem := case when tok.data_overflow is not null then json_value(tok.data_overflow) else json_value(tok.data) end;
      when 'ESTRING' then mem := json_value(tok.data_overflow, false);
      when 'NUMBER' then mem := json_value(to_number(replace(tok.data, '.', decimalpoint)));
      when '[' then 
        declare
          e_list json_list;
        begin
          indx := indx + 1;
          e_list := parseArr(tokens, indx);
          mem := e_list.to_json_value;
        end;
      when '{' then 
        indx := indx + 1;
        mem := parseObj(tokens, indx).to_json_value;
      else 
        p_error('Found '||tok.type_name, tok);
    end case;
    mem.mapname := mem_name;
    mem.mapindx := mem_indx;

    indx := indx + 1;
    return mem;
  end parseMem;
  
  /*procedure test_duplicate_members(arr in json_member_array, mem_name in varchar2, wheretok rToken) as
  begin
    for i in 1 .. arr.count loop
      if(arr(i).member_name = mem_name) then
        p_error('Duplicate member name', wheretok);
      end if;
    end loop;
  end test_duplicate_members;*/
  
  function parseObj(tokens lTokens, indx in out nocopy pls_integer) return json as
    type memmap is table of number index by varchar2(4000); -- i've read somewhere that this is not possible - but it is!
    mymap memmap;
    nullelemfound boolean := false;
    
    obj json;
    tok rToken;
    mem_name varchar(4000);
    arr json_value_array := json_value_array();
  begin
    --what to expect?
    while(indx <= tokens.count) loop
      tok := tokens(indx);
      --debug('E: '||tok.type_name);
      case tok.type_name 
      when 'STRING' then
        --member 
        mem_name := substr(tok.data, 1, 4000);
        begin
          if(mem_name is null) then
            if(nullelemfound) then          
              p_error('Duplicate empty member: ', tok);
            else 
              nullelemfound := true;        
            end if;
          elsif(mymap(mem_name) is not null) then
            p_error('Duplicate member name: '||mem_name, tok);
          end if;
        exception 
          when no_data_found then mymap(mem_name) := 1;
        end;
        
        indx := indx + 1;
        if(indx > tokens.count) then p_error('Unexpected end of input', tok); end if;
        tok := tokens(indx);
        indx := indx + 1;
        if(indx > tokens.count) then p_error('Unexpected end of input', tok); end if;
        if(tok.type_name = ':') then
          --parse 
          declare 
            jmb json_value;
            x number;
          begin
            x := arr.count + 1;
            jmb := parseMem(tokens, indx, mem_name, x);
            arr.extend;
            arr(x) := jmb;
          end;
        else
          p_error('Expected '':''', tok);
        end if;
        --move indx forward if ',' is found
        if(indx > tokens.count) then p_error('Unexpected end of input', tok); end if;
        
        tok := tokens(indx);
        if(tok.type_name = ',') then
          --debug('found ,');
          indx := indx + 1;
          tok := tokens(indx);
          if(tok.type_name = '}') then --premature exit
            p_error('Premature exit in json object', tok);
          end if;
        elsif(tok.type_name != '}') then
           p_error('A comma seperator is probably missing', tok);
        end if;
      when '}' then
        obj := json();
        obj.json_data := arr;
        return obj;
      else 
        p_error('Expected string or }', tok);
      end case;
    end loop;
    
    p_error('} not found', tokens(indx-1));
    
    return obj;
  
  end;

  function parser(str varchar2) return json as
    tokens lTokens;
    obj json;
    indx pls_integer := 1;
    jsrc json_src;
  begin
    updateDecimalPoint();
    jsrc := prepareVarchar2(str);
    tokens := lexer(jsrc); 
    if(tokens(indx).type_name = '{') then
      indx := indx + 1;
      obj := parseObj(tokens, indx);
    else
      raise_application_error(-20101, 'JSON Parser exception - no { start found');
    end if;
    if(tokens.count != indx) then
      p_error('} should end the JSON object', tokens(indx));
    end if;
    
    return obj;
  end parser;

  function parse_list(str varchar2) return json_list as
    tokens lTokens;
    obj json_list;
    indx pls_integer := 1;
    jsrc json_src;
  begin
    updateDecimalPoint();
    jsrc := prepareVarchar2(str);
    tokens := lexer(jsrc); 
    if(tokens(indx).type_name = '[') then
      indx := indx + 1;
      obj := parseArr(tokens, indx);
    else
      raise_application_error(-20101, 'JSON List Parser exception - no [ start found');
    end if;
    if(tokens.count != indx) then
      p_error('] should end the JSON List object', tokens(indx));
    end if;
    
    return obj;
  end parse_list;

  function parse_list(str clob) return json_list as
    tokens lTokens;
    obj json_list;
    indx pls_integer := 1;
    jsrc json_src;
  begin
    updateDecimalPoint();
    jsrc := prepareClob(str);
    tokens := lexer(jsrc); 
    if(tokens(indx).type_name = '[') then
      indx := indx + 1;
      obj := parseArr(tokens, indx);
    else
      raise_application_error(-20101, 'JSON List Parser exception - no [ start found');
    end if;
    if(tokens.count != indx) then
      p_error('] should end the JSON List object', tokens(indx));
    end if;
    
    return obj;
  end parse_list;

  function parser(str clob) return json as
    tokens lTokens;
    obj json;
    indx pls_integer := 1;
    jsrc json_src;
  begin
    updateDecimalPoint();
    --dbms_output.put_line('Using clob');
    jsrc := prepareClob(str);
    tokens := lexer(jsrc); 
    if(tokens(indx).type_name = '{') then
      indx := indx + 1;
      obj := parseObj(tokens, indx);
    else
      raise_application_error(-20101, 'JSON Parser exception - no { start found');
    end if;
    if(tokens.count != indx) then
      p_error('} should end the JSON object', tokens(indx));
    end if;
    
    return obj;
  end parser;
  
  function parse_any(str varchar2) return json_value as
    tokens lTokens;
    obj json_list;
    ret json_value;
    indx pls_integer := 1;
    jsrc json_src;
  begin
    updateDecimalPoint();
    jsrc := prepareVarchar2(str);
    tokens := lexer(jsrc); 
    tokens(tokens.count+1).type_name := ']';
    obj := parseArr(tokens, indx);
    if(tokens.count != indx) then
      p_error('] should end the JSON List object', tokens(indx));
    end if;
    
    return obj.head();
  end parse_any;

  function parse_any(str clob) return json_value as
    tokens lTokens;
    obj json_list;
    indx pls_integer := 1;
    jsrc json_src;
  begin
    jsrc := prepareClob(str);
    tokens := lexer(jsrc); 
    tokens(tokens.count+1).type_name := ']';
    obj := parseArr(tokens, indx);
    if(tokens.count != indx) then
      p_error('] should end the JSON List object', tokens(indx));
    end if;
    
    return obj.head();
  end parse_any;

  /* last entry is the one to keep */
  procedure remove_duplicates(obj in out nocopy json) as
    type memberlist is table of json_value index by varchar2(4000);
    members memberlist;
    nulljsonvalue json_value := null;
    validated json := json();
    indx varchar2(4000);
  begin
    for i in 1 .. obj.count loop
      if(obj.get(i).mapname is null) then 
        nulljsonvalue := obj.get(i);
      else 
        members(obj.get(i).mapname) := obj.get(i);
      end if;            
    end loop;
    
    validated.check_duplicate(false);
    indx := members.first;
    loop
      exit when indx is null;
      validated.put(indx, members(indx));
      indx := members.next(indx);
    end loop;
    if(nulljsonvalue is not null) then
      validated.put('', nulljsonvalue);
    end if;
    
    validated.check_for_duplicate := obj.check_for_duplicate;
    
    obj := validated;  
  end;
  
  function get_version return varchar2 as
  begin
    return 'PL/JSON v1.0.4';
  end get_version;

end json_parser;
/
 
