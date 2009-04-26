
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


DROP TYPE json FORCE;
DROP TYPE json_element_array FORCE;
DROP TYPE json_element FORCE;
DROP TYPE json_member_array FORCE;
DROP TYPE json_member FORCE;
DROP TYPE json_bool FORCE;
DROP TYPE json_null FORCE;

CREATE OR REPLACE TYPE json_member AS OBJECT (
  id NUMBER,
  member_name VARCHAR2(2000),
  member_data anydata );
/

sho err

CREATE OR REPLACE TYPE json_member_array AS 
  TABLE OF json_member;
/

sho err
  
CREATE OR REPLACE TYPE json_element AS OBJECT (
  element_id NUMBER,
  element_data anydata  
  );
/

sho err

CREATE OR REPLACE TYPE json_element_array AS 
  TABLE OF json_element;
/

sho err
  
CREATE OR REPLACE TYPE json_bool AS OBJECT (
  boolean_data varchar2(5)  
  );
/

sho err

CREATE OR REPLACE TYPE json_null AS OBJECT (
  null_data char,

  CONSTRUCTOR FUNCTION json_null
    RETURN SELF AS RESULT  
  );
/

sho err

CREATE OR REPLACE TYPE BODY json_null 
AS

  CONSTRUCTOR FUNCTION json_null
    RETURN SELF AS RESULT 
  AS
  BEGIN
    RETURN;
  END;
  
END;
/


sho err
  
exit
  
