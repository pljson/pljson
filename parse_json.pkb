CREATE OR REPLACE PACKAGE BODY json_parser
AS

/*
This software has been released under the MIT license:

  Copyright (c) 2009 Lewis R Cunningham

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


  type rTypes IS RECORD (
    t_type_name VARCHAR2(10),
    t_match_char VARCHAR2(10),
    t_terminator VARCHAR2(10) DEFAULT NULL,
    t_whitespace BOOLEAN DEFAULT FALSE,
    t_linefeed BOOLEAN DEFAULT FALSE,
    t_comment VARCHAR2(10) DEFAULT NULL,
    t_terminal BOOLEAN DEFAULT FALSE,
    t_firstpass BOOLEAN DEFAULT FALSE,
    t_secondpass BOOLEAN DEFAULT FALSE );
    
  type rLookAhead IS RECORD (
    t_type_name VARCHAR2(10),
    t_look_for VARCHAR2(10),
    t_new_type VARCHAR2(10) DEFAULT NULL,
    t_how_far PLS_INTEGER,
    t_delete_match BOOLEAN DEFAULT FALSE,
    t_delete_current BOOLEAN DEFAULT FALSE,
    t_terminate_sl_comment BOOLEAN DEFAULT FALSE,
    t_terminate_ml_comment BOOLEAN DEFAULT FALSE );
        

  type rToken IS RECORD (
    t_type_name VARCHAR2(10),
    t_line PLS_INTEGER,
    t_column PLS_INTEGER,
    t_comment BOOLEAN DEFAULT FALSE,
    t_data VARCHAR2(32000));

  type aTokens IS TABLE 
   OF rToken
   INDEX BY binary_integer;
   

  TYPE aTypes IS TABLE OF rTypes
    INDEX BY VARCHAR2(30);

  TYPE aLookAhead IS TABLE OF rLookAhead;
  
  TYPE rTokenList IS RECORD (
    t_type_name VARCHAR2(10),
    t_value VARCHAR2(32000),
    t_end_index PLS_INTEGER );
  
  --TYPE aTokenList IS TABLE OF VARCHAR2(32000);
  TYPE aTokenList IS TABLE OF rTokenList;

  vTokenList aTokenList;
  v_tokens aTokens;
  vTypes aTypes;
  vLookAhead aLookAhead;

  v_current_token PLS_INTEGER := 0;
  l_word BOOLEAN := FALSE;  
  l_comment BOOLEAN := FALSE;  
  v_comment_type VARCHAR2(10);
  l_ml_comment BOOLEAN := FALSE;  

  PROCEDURE makeArray(  
     p_json IN OUT JSON,
     p_name IN VARCHAR2,
     p_strt_ndx IN PLS_INTEGER,
     p_end_ndx IN PLS_INTEGER );
     
  FUNCTION is_number(
    p_string IN VARCHAR2 )
  RETURN BOOLEAN
  AS
    x NUMBER;
  BEGIN
    x := to_number(p_string);
     
    RETURN TRUE;
  EXCEPTION
  WHEN value_error
  THEN
    RETURN FALSE;
  END;
  
  PROCEDURE PrintTokens
  AS
    v_buffer VARCHAR2(32000);
  BEGIN
    v_buffer := vTypes.FIRST;   
  LOOP
    EXIT WHEN NOT vTypes.EXISTS(v_buffer);
    
    dbms_output.put_line( 'Name: ' || vtypes(v_buffer).t_type_name ||
       ', Match: ' || vtypes(v_buffer).t_match_char ||
       ', Comment: ' || vtypes(v_buffer).t_comment );
       
      FOR i IN 1..vLookAhead.LAST
      LOOP
        IF vLookAhead(i).t_type_name = vtypes(v_buffer).t_type_name
        THEN
          dbms_output.put_line('......Look For: ' ||     vLookAhead(i).t_look_for ||
               ', New Type: ' || vLookAhead(i).t_new_type ||
               ', How Far: ' || vLookAhead(i).t_how_far);
        END IF;
      END LOOP;
      
    v_buffer := vTypes.NEXT(v_buffer);   
  END LOOP;     
    
  END;  
  FUNCTION is_boolean(
    p_string IN VARCHAR2 )
  RETURN BOOLEAN
  AS
  BEGIN

    IF upper(p_string) IN ('TRUE', 'FALSE')
    THEN 
      RETURN TRUE;
    ELSE   
      RETURN FALSE;
    END IF;
      
  END;
  
  FUNCTION is_null(
    p_string IN VARCHAR2 )
  RETURN BOOLEAN
  AS
  BEGIN

    IF upper(p_string) = 'NULL'
    THEN 
      RETURN TRUE;
    ELSE   
      RETURN FALSE;
    END IF;
      
  END;
  
  FUNCTION make_rtype( 
    p_type_name VARCHAR2,
    p_match_char VARCHAR2,
    p_terminator VARCHAR2 DEFAULT NULL,
    p_whitespace BOOLEAN DEFAULT FALSE,
    p_linefeed BOOLEAN DEFAULT FALSE,
    p_comment VARCHAR2 DEFAULT NULL,
    p_terminal BOOLEAN DEFAULT FALSE,
    p_firstpass BOOLEAN DEFAULT FALSE,
    p_secondpass BOOLEAN DEFAULT FALSE )
  RETURN rTypes
  AS 
    v_r_types rTypes;
  BEGIN
  
    v_r_types.t_type_name := p_type_name ;
    v_r_types.t_match_char := p_match_char ;
    v_r_types.t_terminator := p_terminator ;
    v_r_types.t_whitespace := p_whitespace ;
    v_r_types.t_linefeed := p_linefeed ;
    v_r_types.t_comment := p_comment ;
    v_r_types.t_terminal := p_terminal ;
    v_r_types.t_firstpass := p_firstpass ;
    v_r_types.t_secondpass := p_secondpass ;
     
    RETURN v_r_types;
  END;    
  
  FUNCTION make_lookahead(
    p_type_name VARCHAR2,
    p_look_for VARCHAR2,
    p_new_type VARCHAR2 DEFAULT NULL,
    p_how_far PLS_INTEGER,
    p_delete_match BOOLEAN DEFAULT FALSE,
    p_delete_current BOOLEAN DEFAULT FALSE,
    p_terminate_sl_comment BOOLEAN DEFAULT FALSE,
    p_terminate_ml_comment BOOLEAN DEFAULT FALSE )
  RETURN rLookAhead
  AS  
    v_r_LookAhead rLookAhead;
  BEGIN
    --v_r_LookAhead.extend;
    v_r_LookAhead.t_type_name := p_type_name ; 
    v_r_LookAhead.t_look_for := p_look_for ; 
    v_r_LookAhead.t_new_type := p_new_type ; 
    v_r_LookAhead.t_how_far := p_how_far ; 
    v_r_LookAhead.t_delete_match := p_delete_match ; 
    v_r_LookAhead.t_delete_current := p_delete_current ; 
    v_r_LookAhead.t_terminate_sl_comment := p_terminate_sl_comment ; 
    v_r_LookAhead.t_terminate_ml_comment := p_terminate_ml_comment ; 
    
    RETURN v_r_LookAhead;
  END;
    
  PROCEDURE init_chars
  AS
  BEGIN
    vTokenList := NULL;
    v_tokens.DELETE;
    vTypes.DELETE;
    vLookAhead := NULL;

    v_current_token := 0;
    l_word := FALSE;  
    l_comment := FALSE;  
    v_comment_type := null;
    l_ml_comment := FALSE;  

    vLookAhead := aLookAhead();
    
    vTypes('OP_CURLY') := make_rtype(p_type_name => 'OP_CURLY', p_match_char => '{', p_terminator => 'CL_CURLY');
    vTypes('OP_BRACK') := make_rtype(p_type_name => 'OP_BRACK', p_match_char => '[', p_terminator => 'CL_BRACK');
    --vTypes('CL_CURLY') := make_rtype(p_type_name => 'CL_CURLY', p_match_char => '}');
    
    vTypes('{') := make_rtype(p_type_name => 'OP_CURLY', p_match_char => '{', p_terminator => 'CL_CURLY');
    vTypes('}') := make_rtype(p_type_name => 'CL_CURLY', p_match_char => '}', p_terminal => true);
    vTypes('[') := make_rtype(p_type_name => 'OP_BRACK', p_match_char => '[', p_terminator => 'CL_BRACK');
    vTypes(']') := make_rtype(p_type_name => 'CL_BRACK', p_match_char => ']', p_terminal => true);
    vTypes(',') := make_rtype(p_type_name => 'COMMA', p_match_char => ',', p_terminal => true);
    vTypes('"') := make_rtype(p_type_name => 'QUOTE', p_match_char => '"', p_comment => 'SL', p_terminal => true);
    vTypes(':') := make_rtype(p_type_name => 'COLON', p_match_char => ':');
    vTypes(CHR(13)) := make_rtype(p_type_name => 'LF', p_match_char => CHR(13), p_linefeed => true, p_whitespace => true);
    vTypes(CHR(9)) := make_rtype(p_type_name => 'LF', p_match_char => CHR(9), p_linefeed => true, p_whitespace => true);
    vTypes(CHR(10)) := make_rtype(p_type_name => 'LF', p_match_char => CHR(10), p_linefeed => true, p_whitespace => true);
    vTypes(' ') := make_rtype(p_type_name => 'SPACE', p_match_char => ' ', p_whitespace => true );
    vLookAhead.extend;
    vLookAhead(vLookAhead.LAST) := make_lookahead( p_type_name =>  'LF', 
                                                   p_look_for => chr(10),
                                                   p_how_far => 0,
                                                   p_new_type => 'SPACE' );
    vLookAhead.extend;
    vLookAhead(vLookAhead.LAST) := make_lookahead( p_type_name =>  'LF', 
                                                   p_look_for => chr(13),
                                                   p_how_far => 0,
                                                   p_new_type => 'SPACE' );

    vTypes('\') := make_rtype(p_type_name => 'BCK_SLASH', p_match_char => '\');
    vLookAhead.extend;
    vLookAhead(vLookAhead.LAST) := make_lookahead( p_type_name =>  'BCK_SLASH', 
                                                   p_look_for => 'AST',
                                                   p_new_type => 'OP_ML_COMM',
                                                   p_how_far => 1,
                                                   p_delete_match => true );
    vLookAhead.extend;
    vLookAhead(vLookAhead.LAST) := make_lookahead( p_type_name =>  'QUOTE', 
                                                   p_look_for => 'BCK_SLASH',
                                                   p_new_type => 'WORD',
                                                   p_how_far => -1);
    vTypes('*') := make_rtype(p_type_name => 'AST', p_match_char => '*');
  END;
    
    
  PROCEDURE handle_char( 
    p_current_char IN VARCHAR2,
    p_line IN OUT PLS_INTEGER,
    p_column IN OUT PLS_INTEGER )
  AS
  BEGIN
    --DBMS_OUTPUT.PUT_LINE(v_current_char);
    BEGIN
      v_current_token := NVL(v_tokens.LAST + 1,1);
      v_tokens(v_current_token).t_type_name := vTypes(p_current_char).t_type_name;
      v_tokens(v_current_token).t_line := p_line;
      v_tokens(v_current_token).t_column := p_column;
      v_tokens(v_current_token).t_data := p_current_char;
      v_tokens(v_current_token).t_comment := false;

      IF vTypes(p_current_char).t_type_name IN ('LF')
      THEN
        v_tokens(v_current_token).t_data := ' ';
        --dbms_output.put_line('Found a line feed:: ' || ascii(p_current_char) );
        p_line := p_line + 1;
        p_column := 1;
      ELSE  
        p_column := p_column + 1;
      END IF;

      l_word := FALSE;

   EXCEPTION
     WHEN no_data_found
     THEN  
       IF NOT l_word
       THEN
         v_current_token := NVL(v_tokens.LAST + 1,1);
         v_tokens(v_current_token).t_type_name := 'WORD';
         v_tokens(v_current_token).t_line := p_line;
         v_tokens(v_current_token).t_column := p_column;
       ELSE
         v_current_token := v_tokens.COUNT;
       END IF;        
      
       l_word := TRUE;

       v_tokens(v_current_token).t_data := v_tokens(v_current_token).t_data || p_current_char; 
       v_tokens(v_current_token).t_comment := false;
      
       p_column := p_column + 1;
       
   END;  
    
  END;
       
  PROCEDURE do_secondpass(
    p_ind IN PLS_INTEGER,
    p_comment IN OUT BOOLEAN)
  AS
    
  BEGIN
  
    FOR i IN 1..vLookAhead.COUNT
    LOOP
       
      IF vLookAhead(i).t_type_name =  v_tokens(p_ind).t_type_name  
      THEN
        IF v_tokens(p_ind + vLookAhead(i).t_how_far).t_type_name = vLookAhead(i).t_look_for
        THEN
          IF vLookAhead(i).t_new_type IS NOT NULL
          THEN
            v_tokens(p_ind).t_type_name := vLookAhead(i).t_new_type;
          END IF;
          
          IF vLookAhead(i).t_delete_match
          THEN
            v_tokens(p_ind + vLookAhead(i).t_how_far).t_type_name := 'DELETED';
          END IF;
               
          IF vLookAhead(i).t_delete_current
          THEN
            v_tokens(p_ind).t_type_name := 'DELETED';
          END IF;
    
          IF vTypes(v_tokens(p_ind).t_type_name).t_comment IS NOT NULL
          THEN
          
            IF p_comment AND 
               NOT l_ml_comment AND 
               vTypes(v_tokens(p_ind).t_type_name).t_comment = 'SL'
            THEN
              p_comment :=  vTypes(v_tokens(p_ind).t_type_name).t_terminal;
            ELSIF p_comment AND 
               l_ml_comment AND 
               vTypes(v_tokens(p_ind).t_type_name).t_comment = 'ML'
            THEN
              l_ml_comment :=  vTypes(v_tokens(p_ind).t_type_name).t_terminal;
              p_comment := l_ml_comment;

            ELSIF NOT p_comment AND 
               vTypes(v_tokens(p_ind).t_type_name).t_comment = 'ML'
            THEN
              l_ml_comment :=  TRUE;
              p_comment := l_ml_comment;
            ELSE
               p_comment := FALSE;  
            END IF;     
          END IF;
        END IF;     
      END IF;
    END LOOP;

  EXCEPTION
    WHEN no_data_found
    THEN 
      null;
    WHEN others
    THEN
      IF sqlcode = -6533
      THEN
      
        NULL;
      ELSE
        dbms_output.put_line(sqlcode);
        RAISE;
      END IF;    
    
  END;  
  
  FUNCTION find_end_token(
    p_ndx IN PLS_INTEGER )
  RETURN PLS_INTEGER
  AS
    v_cnt PLS_INTEGER := 0;
    v_curly_rec PLS_INTEGER;
    l_tokenList aTokenList := aTokenList();
    local_cnt PLS_INTEGER := 0;
    p_type VARCHAR2(30) := vTokenList(p_ndx).t_type_name;
    p_Terminator VARCHAR2(30) := vTypes(vTokenList(p_ndx).t_value).t_terminator;
   BEGIN
    -- dbms_output.put_line('Starting at: ' || p_ndx || ', Finding end token: type: '|| p_type || ', term: ' || p_terminator);
    FOR j IN p_ndx..vTokenList.LAST
    LOOP

      IF vTokenList(j).t_type_name = p_type 
      THEN
        v_cnt := v_cnt + 1;
      ELSIF vTokenList(j).t_type_name = p_terminator
      THEN
        v_cnt := v_cnt - 1;
        IF v_cnt = 0
        THEN
          RETURN j;
         END IF;
      END IF;  
         
    END LOOP; 

    RETURN 0;
  END;
  
  FUNCTION makeJson( 
     p_json IN OUT json,
     p_strt_ndx IN PLS_INTEGER,
     p_end_ndx IN PLS_INTEGER )
  RETURN json
  AS
    v_element PLS_INTEGER; 
    --v_json json := json();
    v_member_name VARCHAR2(30);
    v_strt_ndx PLS_INTEGER := p_strt_ndx;
    v_end_ndx PLS_INTEGER := p_end_ndx;
    l_add_json BOOLEAN := false;
    v_json json := json();
  BEGIN

    LOOP

      v_strt_ndx := v_strt_ndx+1;

    EXIT WHEN v_strt_ndx IS NULL or v_strt_ndx > p_end_ndx;
      
    IF vTokenList(v_strt_ndx).t_type_name IN ('CL_BRACK', 'CL_CURLY')
    THEN
      NULL;
    ELSE  
    
    IF vTokenList(v_strt_ndx).t_type_name != 'QUOTE'
    THEN
      raise_application_error(-20010, 'Expecting string got ' || vTokenList(v_strt_ndx).t_type_name);
    ELSE
      v_member_name := vTokenList(v_strt_ndx).t_value;
    END IF;

    v_strt_ndx := v_strt_ndx+1;
    
    IF vTokenList(v_strt_ndx).t_type_name != 'COLON'
    THEN
      raise_application_error(-20011, 'Expecting : got ' || vTokenList(v_strt_ndx).t_type_name);
    END IF;

    v_strt_ndx := v_strt_ndx+1;
    
    CASE vTokenList(v_strt_ndx).t_type_name 
    WHEN 'QUOTE'
    THEN
      v_json.add_member(v_member_name, vTokenList(v_strt_ndx).t_value);
    WHEN 'NUMBER'
    THEN
      v_json.add_member(v_member_name, to_number(vTokenList(v_strt_ndx).t_value));
    WHEN 'NULL'
    THEN
      v_json.add_member(v_member_name, json_null('x'));
    WHEN 'BOOLEAN'
    THEN
      IF UPPER(vTokenList(v_strt_ndx).t_value) = 'TRUE'
      THEN
        v_json.add_member(v_member_name, TRUE, v_element);
      ELSE
        v_json.add_member(v_member_name, FALSE, v_element);
      END IF;  
    WHEN 'OP_BRACK'
    THEN
    --DBMS_OUTPUT.PUT_LINE(1 || ' v_strt_ndx: ' || v_strt_ndx || 
    --        ', vTokenList(v_strt_ndx).t_end_ndx: ' || vTokenList(v_strt_ndx).t_end_index );


        makeArray(v_json, v_member_name, v_strt_ndx, vTokenList(v_strt_ndx).t_end_index);
        v_strt_ndx := vTokenList(v_strt_ndx).t_end_index;

    WHEN 'OP_CURLY'
    THEN
        v_json.add_member( v_member_name, makeJson(v_json, v_strt_ndx, vTokenList(v_strt_ndx).t_end_index) );
        v_strt_ndx := vTokenList(v_strt_ndx).t_end_index;
    ELSE
      NULL;
    END CASE;  
    
      END IF;
      
   END LOOP;
    
    RETURN v_json;
  END;

  PROCEDURE makeArray(  
     p_json IN OUT JSON,
     p_name IN VARCHAR2,
     p_strt_ndx IN PLS_INTEGER,
     p_end_ndx IN PLS_INTEGER )
  AS
    v_array PLS_INTEGER;  
    v_element PLS_INTEGER; 
    p_ndx PLS_INTEGER := 0;
  BEGIN
    v_array := p_json.add_array( p_name );
    --dbms_output.put_line( 'array p_strt_ndx+1..p_end_ndx-1 IS ' || p_strt_ndx || '+1..' || p_end_ndx || '-1');
    FOR j IN p_strt_ndx+1..p_end_ndx-1
    LOOP
      IF p_ndx < j
      THEN
      CASE vTokenList(j).t_type_name
      WHEN 'NUMBER'
      THEN
        p_json.add_array_element(v_array, to_number(vTokenList(j).t_value), v_element);
      WHEN 'QUOTE'
      THEN
        p_json.add_array_element(v_array, vTokenList(j).t_value, v_element);
      WHEN 'NULL'
      THEN
        p_json.add_array_element(v_array, json_null('x'), v_element);
      WHEN 'BOOLEAN'
      THEN
        IF UPPER(vTokenList(j).t_value) = 'TRUE'
        THEN
          p_json.add_array_element(v_array, TRUE, v_element);
        ELSE
          p_json.add_array_element(v_array, FALSE, v_element);
        END IF;  
      WHEN 'OP_CURLY'
      THEN
        p_json.add_array_element(
            v_array,         
            makeJson(p_json, j, vTokenList(j).t_end_index),
            v_element);
        p_ndx := vTokenList(j).t_end_index;    
      ELSE
        NULL;
      END CASE;  
      END IF;
    END LOOP;
  END;  
 
  FUNCTION fifth_pass
  RETURN json
  AS
    v_json json := json();
    v_array json_element_array := json_element_array();
  BEGIN
      CASE vTokenList(1).t_type_name
      WHEN 'OP_CURLY'
      THEN
        v_json := makeJson(v_json, 1, vTokenList(1).t_end_index);
      WHEN 'OP_BRACK'
      THEN
        makeArray(v_json, 'DUMMY', 1, vTokenList(1).t_end_index);
      ELSE
        NULL;
      END CASE; 
      
    RETURN v_json;
    
  END;

  PROCEDURE fourth_pass
  AS
    v_json json := json();
    v_cnt PLS_INTEGER := 0;
    v_curly_rec PLS_INTEGER;
    l_tokenList aTokenList := aTokenList();
    local_cnt PLS_INTEGER := 0;
    ndx PLS_INTEGER := 0;
  BEGIN
   
   
     FOR j IN vTokenList.FIRST..vTokenList.LAST
    LOOP

      IF vTokenList(j).t_type_name IS NOT NULL
        AND vTokenList(j).t_type_name != 'DELETED'
      THEN

        BEGIN
          IF vTypes(vTokenList(j).t_value).t_terminator IS NOT NULL
          THEN
            
            vTokenList(j).t_end_index := find_end_token(j);
            
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
            NULL;
          WHEN OTHERS  -- Dealing with null match on vtokenlist 
          THEN
            NULL;
        END;
      END IF;  
/*
      DBMS_OUTPUT.PUT_LINE('Type(' || j || '): ' || vTokenList(j).t_type_name || ', Value: |' || vTokenList(j).t_value || '|' ||
           ', End Index: ' || vTokenList(j).t_end_index );
*/    
    END LOOP;
  END;

  FUNCTION parse_json( 
    p_string IN VARCHAR2 )
  RETURN json  
  AS
    v_current_char VARCHAR2(10);
  
    v_old_i PLS_INTEGER;
  
    v_sample VARCHAR2(32000) := p_string;
    v_line PLS_INTEGER := 1;
    v_column PLS_INTEGER := 1;
    j PLS_INTEGER := 1;
    str_len PLS_INTEGER;
    v_json json;
    v_cnt PLS_INTEGER;
  
  BEGIN

  init_chars;
  
  str_len := LENGTH(v_sample);

--DBMS_OUTPUT.PUT_LINE('First Pass>>>>>>>>>>>>>>>>>>');

  FOR i IN 1..str_len
  LOOP
    v_current_char := substr(v_sample, i, 1);
    
    handle_char(v_current_char, v_line, v_column);

  END LOOP;
/*  
  FOR j IN v_tokens.FIRST..v_tokens.LAST
  LOOP
      DBMS_OUTPUT.PUT_LINE('Line: ' || v_tokens(j).t_line ||
         ', Column: ' || v_tokens(j).t_column || ', Type: ' || v_tokens(j).t_type_name || ', Data: ' || v_tokens(j).t_data );
  END LOOP;    
*/  

  l_comment := false;
  
--DBMS_OUTPUT.PUT_LINE('Second Pass>>>>>>>>>>>>>>>>>>');

  FOR j IN v_tokens.FIRST..v_tokens.LAST
  LOOP
    do_secondpass(j, l_comment);        
    
    IF v_tokens.EXISTS(j) 
    THEN
          IF is_number(v_tokens(j).t_data)
          THEN
            v_tokens(j).t_type_name := 'NUMBER';
          ELSIF is_boolean(v_tokens(j).t_data)
          THEN
            v_tokens(j).t_type_name := 'BOOLEAN';
          ELSIF is_null(v_tokens(j).t_data)
          THEN
            v_tokens(j).t_type_name := 'NULL';
          END IF;  
    END IF;


    v_tokens(j).t_comment := l_comment;
  END LOOP;
/*  
  FOR j IN v_tokens.FIRST..v_tokens.LAST
  LOOP
    DBMS_OUTPUT.PUT_LINE('Line: ' || v_tokens(j).t_line ||
        ', Column: ' || v_tokens(j).t_column || ', Type: ' || v_tokens(j).t_type_name || ', Data: ' || v_tokens(j).t_data );

    --DBMS_OUTPUT.PUT_LINE('j= ' || j || ', i=' || i );
  END LOOP;  
*/

  
  
  v_sample := NULL;
  v_old_i := 0;
  l_comment := false;
  
  vTokenList := aTokenList();

--DBMS_OUTPUT.PUT_LINE('Third Pass>>>>>>>>>>>>>>>>>>');
  
  FOR j IN v_tokens.FIRST..v_tokens.LAST
  LOOP

    CASE 
    WHEN v_tokens(j).t_type_name = 'DELETED'
    THEN NULL;
    
    WHEN v_tokens(j).t_type_name IN ('SPACE', 'LF', 'COMMA') 
    THEN 
      IF l_comment
      THEN
        v_sample := v_sample || v_tokens(j).t_data;
      ELSE
        v_tokens(j).t_type_name := 'DELETED';  
      END IF;
    
    WHEN v_tokens(j).t_type_name = 'QUOTE'
    THEN
      IF l_comment
      THEN
        l_comment := false;
        vTokenList.extend;
        vTokenList(vTokenList.COUNT).t_type_name := v_tokens(j).t_type_name;
        vTokenList(vTokenList.COUNT).t_value := v_sample;
        v_sample := NULL;
      ELSE
        l_comment := TRUE;  
      END IF;
   ELSE
     IF l_comment
     THEN
       v_sample := v_sample || v_tokens(j).t_data;
     ELSE
       vTokenList.extend;
       vTokenList(vTokenList.COUNT).t_type_name := v_tokens(j).t_type_name;
       vTokenList(vTokenList.COUNT).t_value := v_tokens(j).t_data;
     END IF;
   END CASE; 

  END LOOP;      

/*
  FOR j IN vTokenList.FIRST..vTokenList.LAST
  LOOP
      DBMS_OUTPUT.PUT_LINE('Type: ' || v_tokens(j).t_type_name || ', Data: ' || v_tokens(j).t_data || 
          ', l_comment: ' ||
          CASE v_tokens(j).t_comment WHEN TRUE THEN 'TRUE' ELSE 'FASLE' END);
   END LOOP;
*/

--DBMS_OUTPUT.PUT_LINE('Fourth Pass>>>>>>>>>>>>>>>>>>');

  fourth_pass;
  
--DBMS_OUTPUT.PUT_LINE('Fifth Pass>>>>>>>>>>>>>>>>>>');

  v_json := fifth_pass;
  
  RETURN v_json;
   
/*   
*/

  END;
    
END;
/


sho err

exit

