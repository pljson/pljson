CREATE OR REPLACE PACKAGE BODY json_helper 
AS


  /*
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


  v_output CLOB;
  v_print BOOLEAN := TRUE;
  v_crlf VARCHAR2(10) := chr(10);
  v_parsed json;

  TYPE a_queue IS TABLE OF VARCHAR2(30)
    INDEX BY BINARY_INTEGER;
    
  v_queue a_queue;
  
  FUNCTION string_format( p_var IN VARCHAR2 )
    RETURN VARCHAR2
  AS
  BEGIN
    RETURN '"' || p_var || '"';
  END;  
    
  FUNCTION string_format( p_var IN BOOLEAN )
    RETURN VARCHAR2
  AS
  BEGIN
    IF p_var
    THEN
      RETURN 'true';
    ELSE
      RETURN 'false';
    END IF;  
  END;
    
  FUNCTION string_format( p_var IN NUMBER )
    RETURN VARCHAR2
  AS
  BEGIN
    RETURN to_char(p_var);
  END;
  
  FUNCTION make_boolean(
    p_value BOOLEAN )
    RETURN json_bool
  AS
    v_bool json_bool;
  BEGIN  

      IF p_value
      THEN
        v_bool := json_bool('true');
      ELSE
        v_bool := json_bool('false');
      END IF;
    
    RETURN v_bool;
  END;
  
  PROCEDURE put( 
    p_string IN VARCHAR2 )
  AS
  BEGIN
    put_line(p_string, FALSE );
  END;

  PROCEDURE put_line( 
    p_string IN VARCHAR2,
    p_crlf IN BOOLEAN DEFAULT TRUE )
  IS
  BEGIN
  
    IF json_helper.v_print 
    THEN
      IF p_crlf
      THEN
        DBMS_OUTPUT.PUT_LINE(p_string);
      ELSE  
        DBMS_OUTPUT.PUT(p_string);
      END IF;
    ELSE
      DBMS_LOB.writeappend(json_helper.v_output, length(p_string), p_string);
      IF p_crlf
      THEN
        DBMS_LOB.writeappend(json_helper.v_output, length(v_crlf), v_crlf);
      END IF;      
    END IF;

 
  END;
  
  PROCEDURE setPrint( 
    p_print IN BOOLEAN )
  AS
  BEGIN
    json_helper.v_print := p_print;
  END;

  PROCEDURE setOutput
  AS
  BEGIN
    v_output := NULL;
    DBMS_LOB.CREATETEMPORARY(v_output,TRUE, DBMS_LOB.SESSION);
    DBMS_LOB.OPEN(
          lob_loc    => v_output
        , open_mode  => DBMS_LOB.LOB_READWRITE
    );
  END;
  
  FUNCTION getOutput
  RETURN CLOB
  AS
    v_clob CLOB;
  BEGIN
    DBMS_LOB.CLOSE(lob_loc => json_helper.v_output);
    
    v_clob := json_helper.v_output;
    
    DBMS_LOB.FREETEMPORARY(lob_loc => json_helper.v_output);
    
    REturn V_CLOB;
  END;

  FUNCTION get_schema 
    RETURN VARCHAR2
  AS
  BEGIN
    RETURN sys_context('userenv', 'current_schema');
  END;  
  
END;  
/

sho err

exit
    