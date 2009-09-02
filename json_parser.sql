create or replace package json_parser as
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

  /* scanner tokens:
    '{', '}', ',', ':', '[', ']', STRING, NUMBER, TRUE, FALSE, NULL 
  */
  type rToken IS RECORD (
    type_name VARCHAR2(6),
    line PLS_INTEGER,
    col PLS_INTEGER,
    data VARCHAR2(4000)); -- limit a string to 4000 characters

  type lTokens is table of rToken index by pls_integer;
  
  procedure print_token(t rToken);
  function lexer(str varchar2) return lTokens;

  function parser(str varchar2) return json;
  function parse_list(str varchar2) return json_list;
    

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

  function lexNumber(str varchar2, tok in out rToken, indx in out pls_integer) return pls_integer as
    numbuf varchar2(4000) := '';
    buf varchar2(4);
    checkLoop boolean;
  begin
    buf := substr(str, indx, 1); 
    if(buf = '-') then numbuf := '-'; indx := indx + 1; end if;
    buf := substr(str, indx, 1); 
    --0 or [1-9]([0-9])* 
    if(buf = '0') then 
      numbuf := numbuf || '0'; indx := indx + 1; 
      buf := substr(str, indx, 1); 
    elsif(buf >= '1' and buf <= '9') then 
      numbuf := numbuf || buf; indx := indx + 1; 
      --read digits
      buf := substr(str, indx, 1); 
      while(buf >= '0' and buf <= '9') loop
        numbuf := numbuf || buf; indx := indx + 1; 
        buf := substr(str, indx, 1); 
      end loop;      
    end if;
    --fraction
    if(buf = '.') then
      numbuf := numbuf || buf; indx := indx + 1; 
      buf := substr(str, indx, 1); 
      checkLoop := FALSE;
      while(buf >= '0' and buf <= '9') loop
        checkLoop := TRUE;
        numbuf := numbuf || buf; indx := indx + 1; 
        buf := substr(str, indx, 1); 
      end loop; 
      if(not checkLoop) then
        s_error('Expected: digits in fraction', tok);
      end if;
    end if;
    --exp part
    if(buf in ('e', 'E')) then
      numbuf := numbuf || buf; indx := indx + 1; 
      buf := substr(str, indx, 1); 
      if(buf = '+' or buf = '-') then 
        numbuf := numbuf || buf; indx := indx + 1; 
        buf := substr(str, indx, 1); 
      end if;
      checkLoop := FALSE;
      while(buf >= '0' and buf <= '9') loop
        checkLoop := TRUE;
        numbuf := numbuf || buf; indx := indx + 1; 
        buf := substr(str, indx, 1); 
      end loop;      
      if(not checkLoop) then
        s_error('Expected: digits in exp', tok);
      end if;
    end if;
    
    tok.data := numbuf;
    return indx;
  end lexNumber;

  function lexString(str varchar2, tok in out rToken, indx in out pls_integer) return pls_integer as
    varbuf varchar2(4000) := '';
    buf varchar(4);
    wrong boolean;
  begin
    indx := indx +1;
    buf := substr(str, indx, 1); 
    while(buf != '"') loop
      if(buf = Chr(13) or buf = CHR(9) or buf = CHR(10)) then
        s_error('Control characters not allowed (CHR(9),CHR(10)CHR(13))', tok);
      end if;
      if(buf = '\') then
        varbuf := varbuf || buf;
        indx := indx + 1;
        buf := substr(str, indx, 1); 
        case
          when buf in ('"', '\', '/', 'b', 'f', 'n', 'r', 't') then
            varbuf := varbuf || buf;
            indx := indx + 1;
            buf := substr(str, indx, 1); 
          when buf = 'u' then
            --four hexidecimal chars
            declare
              four varchar2(4);
            begin
              four := substr(str, indx+1, 4); 
              wrong := FALSE;              
              if(upper(substr(four, 1,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F')) then wrong := TRUE; end if;
              if(upper(substr(four, 2,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F')) then wrong := TRUE; end if;
              if(upper(substr(four, 3,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F')) then wrong := TRUE; end if;
              if(upper(substr(four, 4,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F')) then wrong := TRUE; end if;
              if(wrong) then
                s_error('expected: " \u([0-9][A-F]){4}', tok);
              end if;
              varbuf := varbuf || buf || four;
              indx := indx + 5;
              buf := substr(str, indx, 1); 
              end;
          else 
            s_error('expected: " \ / b f n r t u ', tok);
        end case;
      else
        varbuf := varbuf || buf;
        indx := indx + 1;
        buf := substr(str, indx, 1); 
      end if;
    end loop;
    
    if (buf is null) then 
      s_error('string ending not found', tok);
      --debug('Premature string ending');
    end if;

    --debug(varbuf);
    tok.data := varbuf;
    return indx;
  end lexString;
  
  /* scanner tokens:
    '{', '}', ',', ':', '[', ']', STRING, NUMBER, TRUE, FALSE, NULL
  */
  function lexer(str varchar2) return lTokens as
    tokens lTokens;
    indx pls_integer := 1;
    tok_indx pls_integer := 1;
    buf varchar2(4);
    lin_no number := 1;
    col_no number := 0;
  begin
    while (indx <= length(str)) loop
      --read into buf
      buf := substr(str, indx, 1); 
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
          if(substr(str, indx, 4) != 'true') then
            s_error('Expected: ''true''', lin_no, col_no);
          end if;
          tokens(tok_indx) := mt('TRUE', lin_no, col_no, null); tok_indx := tok_indx + 1; 
          indx := indx + 3;
          col_no := col_no + 3;
        when buf = 'n' then
          if(substr(str, indx, 4) != 'null') then
            s_error('Expected: ''null''', lin_no, col_no);
          end if;
          tokens(tok_indx) := mt('NULL', lin_no, col_no, null); tok_indx := tok_indx + 1; 
          indx := indx + 3;
          col_no := col_no + 3;
        when buf = 'f' then
          if(substr(str, indx, 5) != 'false') then
            s_error('Expected: ''false''', lin_no, col_no);
          end if;
          tokens(tok_indx) := mt('FALSE', lin_no, col_no, null); tok_indx := tok_indx + 1; 
          indx := indx + 4;
          col_no := col_no + 4;
        /*   -- 9 = TAB, 10 = \n, 13 = \r (Linux = \n, Windows = \r\n, Mac = \r */        
        when (buf = Chr(10)) then --linux newlines
          lin_no := lin_no + 1;
          col_no := 0;
            
        when (buf = Chr(13)) then --Windows or Mac way
          lin_no := lin_no + 1;
          col_no := 0;
          if(length(str) >= indx +1) then -- better safe than sorry
            buf := substr(str, indx+1, 1);
            if(buf = Chr(10)) then --\r\n
              indx := indx + 1;
            end if;
          end if;
      
        when (buf = CHR(9)) then null; --tabbing
        when (buf in ('-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9')) then --number
          tokens(tok_indx) := mt('NUMBER', lin_no, col_no, null); 
          indx := lexNumber(str, tokens(tok_indx), indx)-1;
          col_no := col_no + length(tokens(tok_indx).data);
          tok_indx := tok_indx + 1; 
        when buf = '"' then --number
          tokens(tok_indx) := mt('STRING', lin_no, col_no, null); 
          indx := lexString(str, tokens(tok_indx), indx);
          col_no := col_no + length(tokens(tok_indx).data) + 1;
          tok_indx := tok_indx + 1; 
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
  
  function parseObj(tokens lTokens, indx in out pls_integer) return json;

  function parseArr(tokens lTokens, indx in out pls_integer) return json_list as
    e_arr json_element_array := json_element_array();
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
        when 'TRUE' then e_arr(v_count) := json_element(v_count, anydata.convertobject( json_bool(true) ));
        when 'FALSE' then e_arr(v_count) := json_element(v_count, anydata.convertobject( json_bool(false) ));
        when 'NULL' then e_arr(v_count) := json_element(v_count, anydata.convertobject( json_null ));
        when 'STRING' then e_arr(v_count) := json_element(v_count, anydata.convertvarchar2( tok.data ));
        when 'NUMBER' then 
          declare rev varchar2(10); begin
            --stupid countries with , as decimal point
            SELECT VALUE into rev FROM NLS_SESSION_PARAMETERS WHERE PARAMETER = 'NLS_NUMERIC_CHARACTERS';
            if(rev = ',.') then
              e_arr(v_count) := json_element(v_count, anydata.convertnumber( to_number(replace(tok.data, '.',','))));
            else
              e_arr(v_count) := json_element(v_count, anydata.convertnumber( to_number(tok.data )));
            end if;
          end;
        when '[' then 
          declare e_list json_list; begin
            indx := indx + 1;
            e_list := parseArr(tokens, indx);
            e_arr(v_count) := json_element(v_count, anydata.convertobject(e_list));
          end;
        when '{' then 
          indx := indx + 1;
          e_arr(v_count) := json_element(v_count, anydata.convertobject(parseObj(tokens, indx)));
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
    --HACK START
--    if(e_arr.count mod 2 = 0) then e_arr.extend; end if;
    --HACK END 
    ret_list.list_data := e_arr;
    return ret_list;
  end parseArr;
  
  function parseMem(tokens lTokens, indx in out pls_integer, mem_name varchar2, mem_indx number) return json_member as
    mem json_member;
    tok rToken;
  begin
    tok := tokens(indx);
    case tok.type_name
      when 'TRUE' then mem := json_member(mem_indx, mem_name, anydata.convertobject( json_bool(true) ));
      when 'FALSE' then mem := json_member(mem_indx, mem_name, anydata.convertobject( json_bool(false) ));
      when 'NULL' then mem := json_member(mem_indx, mem_name, anydata.convertobject(json_null));
      when 'STRING' then mem := json_member(mem_indx, mem_name, anydata.convertvarchar2( tok.data ));
      when 'NUMBER' then 
        declare rev varchar2(10); begin
          --stupid countries with , as decimal point
          SELECT VALUE into rev FROM NLS_SESSION_PARAMETERS WHERE PARAMETER = 'NLS_NUMERIC_CHARACTERS';
          if(rev = ',.') then
            mem := json_member(mem_indx, mem_name, anydata.convertnumber( to_number(replace(tok.data, '.',','))));
          else
            mem := json_member(mem_indx, mem_name, anydata.convertnumber( to_number(tok.data )));
          end if;
        end;
      when '[' then 
        declare
          e_list json_list;
        begin
          indx := indx + 1;
          e_list := parseArr(tokens, indx);
          mem := json_member(mem_indx, mem_name, anydata.convertobject(e_list));
        end;
      when '{' then 
        indx := indx + 1;
        mem := json_member(mem_indx, mem_name, anydata.convertobject(parseObj(tokens, indx)));
      else 
        p_error('Found '||tok.type_name, tok);
    end case;

    indx := indx + 1;
    return mem;
  end parseMem;
  
  procedure test_duplicate_members(arr in json_member_array, mem_name in varchar2, wheretok rToken) as
  begin
    for i in 1 .. arr.count loop
      if(arr(i).member_name = mem_name) then
        p_error('Duplicate member name', wheretok);
      end if;
    end loop;
  end test_duplicate_members;
  
  function parseObj(tokens lTokens, indx in out pls_integer) return json as
    obj json;
    tok rToken;
    mem_name varchar(4000);
    arr json_member_array := json_member_array();
  begin
    --what to expect?
    while(indx <= tokens.count) loop
      tok := tokens(indx);
      --debug('E: '||tok.type_name);
      case tok.type_name 
      when 'STRING' then
        --member 
        mem_name := tok.data;
        indx := indx + 1;
        if(indx > tokens.count) then p_error('Unexpected end of input', tok); end if;
        tok := tokens(indx);
        indx := indx + 1;
        if(indx > tokens.count) then p_error('Unexpected end of input', tok); end if;
        if(tok.type_name = ':') then
          --parse 
          declare 
            jmb json_member;
            x number;
          begin
            x := arr.count + 1;
            jmb := parseMem(tokens, indx, mem_name, x);
            arr.extend;
            test_duplicate_members(arr, mem_name, tok);
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
        end if;

      when '}' then
        return json(arr);
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
  begin
    tokens := lexer(str); 
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
  begin
    tokens := lexer(str); 
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


end json_parser;
/
 
