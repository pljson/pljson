  /*
  Copyright (c) 2009 Lewis R Cunningham, Jonas Krogsboell

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

CREATE OR REPLACE TYPE json_null AS OBJECT (
  null_data char,
  CONSTRUCTOR FUNCTION json_null RETURN SELF AS RESULT  
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

CREATE OR REPLACE TYPE json_bool AS OBJECT (
  boolean_data number, --new impl: 1 is true, otherwise false  varchar2(5),
  CONSTRUCTOR FUNCTION json_bool(b boolean) RETURN SELF AS RESULT,
  member function to_char return varchar2,
  member function is_true return boolean,
  member function is_false return boolean,
  static function maketrue return json_bool,
  static function makefalse return json_bool
  
);
/

sho err

CREATE OR REPLACE TYPE BODY json_bool
AS

  CONSTRUCTOR FUNCTION json_bool(b boolean)
    RETURN SELF AS RESULT 
  AS
  BEGIN
    --if(b) then self.boolean_data := 'true'; else self.boolean_data := 'false'; end if;
    if(b) then self.boolean_data := 1; else self.boolean_data := 0; end if;
    RETURN;
  END;
  
  member function to_char return varchar2 as
  begin
    if(boolean_data = 1) then return 'true'; else return 'false'; end if;
  end;
  
  member function is_true return boolean as
  begin
    if(boolean_data = 1) then return true; else return false; end if;
  end;
  
  member function is_false return boolean as
  begin
    if(boolean_data = 1) then return false; else return true; end if;
  end;

  static function maketrue return json_bool as
  begin
    return json_bool(true);
  end;
  
  static function makefalse return json_bool as
  begin
    return json_bool(false);
  end;
  
END;
/

sho err

CREATE OR REPLACE TYPE json_member AS OBJECT (
  id NUMBER,
  member_name VARCHAR2(4000),
  member_data anydata 
);
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
