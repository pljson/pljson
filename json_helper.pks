CREATE OR REPLACE PACKAGE json_helper 
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


  json_object_start CONSTANT CHAR(1) := '{';
  json_object_colon CONSTANT CHAR(1) := ':';
  json_object_stop CONSTANT CHAR(1) := '}';
  json_array_start CONSTANT CHAR(1) := '[';
  json_array_stop CONSTANT CHAR(1) := ']';
  json_comma CONSTANT CHAR(1) := ',';
  json_quote CONSTANT CHAR(1) := '"';
  
  null_value json_null;
  
  FUNCTION string_format( p_var IN VARCHAR2 )
    RETURN VARCHAR2;
    
  FUNCTION string_format( p_var IN BOOLEAN )
    RETURN VARCHAR2;
    
  FUNCTION string_format( p_var IN NUMBER )
    RETURN VARCHAR2;

   
  FUNCTION make_boolean(
    p_value BOOLEAN )
    RETURN json_bool;

    
  PROCEDURE put_line( 
    p_string IN VARCHAR2,
    p_crlf IN BOOLEAN DEFAULT TRUE );
  
  PROCEDURE put( 
    p_string IN VARCHAR2 );
  
  PROCEDURE setPrint( 
    p_print IN BOOLEAN );
    
  PROCEDURE setOutput;
    
  FUNCTION getOutput
    RETURN CLOB;    
    
  FUNCTION get_schema 
    RETURN VARCHAR2;  
END;
/

sho err

exit
    
    