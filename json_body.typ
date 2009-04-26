CREATE OR REPLACE TYPE BODY json 
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


  CONSTRUCTOR FUNCTION json
    RETURN SELF AS RESULT
  AS
  BEGIN
    SELF.num_elements := 0;
    SELF.json_data := json_member_array();
  
    RETURN;
  END;
  
  CONSTRUCTOR FUNCTION json(
    p_name IN VARCHAR2, 
    p_value IN VARCHAR2)
    RETURN SELF AS RESULT
  AS
  BEGIN
    SELF.num_elements := 0;
    SELF.json_data := json_member_array();
    SELF.add_member(
        p_name => p_name, 
        p_value => p_value);

    RETURN;
  END;
  
 CONSTRUCTOR FUNCTION json(p_data IN json_member_array)
    RETURN SELF AS RESULT
 AS
 BEGIN
    SELF.num_elements := 1;
    SELF.json_data := p_data;
    
    RETURN;
    
 END; 
  
  CONSTRUCTOR FUNCTION json(p_data IN XMLType)
    RETURN SELF AS RESULT
  AS
  BEGIN
    -- Returns an empty object for now
    SELF.num_elements := 0;
    SELF.json_data := json_member_array();
    RETURN;
  END;
  
  CONSTRUCTOR FUNCTION json(p_data IN CLOB)
    RETURN SELF AS RESULT
  AS
  BEGIN
  
    SELF := json_parser.parse_json(p_data);
    RETURN;
  END;
  
  CONSTRUCTOR FUNCTION json(p_data IN VARCHAR2)
    RETURN SELF AS RESULT
  AS
  BEGIN
  
    SELF := json_parser.parse_json(p_data);
    RETURN;
  END;
  
  MEMBER FUNCTION print(p_indent IN NUMBER DEFAULT 0)
    RETURN NUMBER 
  AS
    v_interval NUMBER;
  BEGIN
    json_helper.setPrint(TRUE);
    v_interval := writer(p_indent);
    RETURN v_interval;
  END;
  
  MEMBER FUNCTION getString(p_indent IN NUMBER DEFAULT 0)
    RETURN VARCHAR2
  AS
    v_interval NUMBER;
    v_return LONG;
  BEGIN
    v_return := getCLOB(p_indent);
    RETURN v_return;
  END;

  MEMBER FUNCTION getXML(p_indent IN NUMBER DEFAULT 0)
    RETURN XMLType
  AS
    v_xml XMLType;
    v_interval NUMBER;
  BEGIN
    -- DOes not currently work
    json_helper.setPrint(FALSE);
    json_helper.setOutput;
    v_interval := print(p_indent);
    RETURN v_xml;
  END;
  
  
  MEMBER PROCEDURE print(p_indent IN NUMBER DEFAULT 0)
  AS
    v_interval NUMBER;
  BEGIN
    json_helper.setPrint(TRUE);
    v_interval := writer(p_indent);
  END;

  MEMBER FUNCTION getClob(p_indent IN NUMBER DEFAULT 0)
    RETURN CLOB
  AS
    v_interval NUMBER;
    v_return CLOB;
  BEGIN
    json_helper.setOutput;
    json_helper.setPrint(FALSE);
    v_interval := writer(p_indent);
    v_return := json_helper.getOutput;
    RETURN v_return;
  END;
  
  MEMBER FUNCTION writer(p_indent IN NUMBER DEFAULT 0)
    RETURN NUMBER
  AS
    v_var VARCHAR2(2000);
    v_number NUMBER;
    x NUMBER;
    v_json json;
    v_json_element_array json_element_array;
    v_json_element json_element;
    v_data_type VARCHAR2(30);
    v_indent NUMBER := p_indent;
    v_json_bool json_bool;
    v_json_null json_null;
    v_interval NUMBER;
    v_array_element_type VARCHAR2(30);
    
    v_output CLOB;
  BEGIN
  
      json_helper.PUT_LINE( 
        json_helper.json_object_start );
        
      v_indent := v_indent + 2;
      --json_helper.PUT( string_helper.spaces(v_indent) );

    FOR i IN 1..SELF.num_elements
    LOOP
     
       v_data_type := anydata.gettypename(sELF.json_data(i).member_data);
       
       json_helper.PUT( 
         json_helper.string_format(SELF.json_data(i).member_name) ||
         json_helper.json_object_colon );
       
       CASE
       
       WHEN v_data_type = 'SYS.VARCHAR2'
       THEN
         x := SELF.json_data(i).member_data.getvarchar2(v_var) ;
         
         json_helper.PUT( 
           json_helper.string_format(v_var)
         ); 
       WHEN v_data_type = 'SYS.NUMBER'
       THEN
         x := SELF.json_data(i).member_data.getnumber(v_number) ;
         
         json_helper.PUT( 
           json_helper.string_format(v_number)
         ); 
       WHEN v_data_type = json_helper.get_schema || '.JSON_BOOL'
       THEN
         x := SELF.json_data(i).member_data.getobject(v_json_bool) ;
         
         json_helper.PUT( 
           v_json_bool.boolean_data
         ); 
       WHEN v_data_type = json_helper.get_schema || '.JSON_NULL'
       THEN
         x := SELF.json_data(i).member_data.getobject(v_json_null) ;
         
         json_helper.PUT( 
           'null'
         ); 
       WHEN v_data_type = json_helper.get_schema || '.JSON'
       THEN

         x := SELF.json_data(i).member_data.getobject(v_json) ;
         
         v_interval := v_json.writer(v_interval);

       WHEN v_data_type = json_helper.get_schema || '.JSON_ELEMENT_ARRAY'
       THEN
       
         x := SELF.json_data(i).member_data.getcollection(v_json_element_array) ;
         
         json_helper.PUT( '[');
         
         FOR j IN 1..v_json_element_array.LAST
         LOOP
           v_json_element := v_json_element_array(j);

           v_array_element_type := anydata.gettypename(v_json_element.element_data);
           
           CASE v_array_element_type
           WHEN 'SYS.VARCHAR2'
           THEN

             x := v_json_element.element_data.getvarchar2(v_var) ;

             --v_json_element
             json_helper.PUT( 
               json_helper.string_format(v_var) );
               
           WHEN 'SYS.NUMBER'
           THEN

             x := v_json_element.element_data.getnumber(v_number) ;

             --v_json_element
             json_helper.PUT( 
               json_helper.string_format(v_number) );

           WHEN json_helper.get_schema || '.JSON_BOOL'
           THEN

             x := v_json_element.element_data.getobject(v_json_bool) ;

             --v_json_element
             json_helper.PUT( 
               v_json_bool.boolean_data );

           WHEN json_helper.get_schema || '.JSON_NULL'
           THEN

             x := v_json_element.element_data.getobject(v_json_null) ;

             --v_json_element
             json_helper.PUT( 
               'null' );

           WHEN json_helper.get_schema || '.JSON'
           THEN
             x := v_json_element.element_data.getobject(v_json) ;
         
             
--             json_helper.PUT( 
--               json_helper.string_format(v_json.json_data(1).member_name) ||
--               json_helper.json_object_colon );

             v_interval := v_json.writer(v_interval);

           ELSE
              
             json_helper.PUT_LINE('Unkonwn Array Element type: ' || v_data_type);
             
           END CASE;
             
           IF j != v_json_element_array.LAST
           THEN   
             json_helper.PUT( 
               json_helper.json_comma );
           END IF;
           
         --v_json_array.print();
        END LOOP;

         json_helper.PUT( ']');

       ELSE
     
        json_helper.PUT_LINE('Unkonwn Member Value type: ' || v_data_type);
       END CASE;

       IF i != num_elements
       THEN
         json_helper.PUT_LINE( 
           json_helper.json_comma );
       END IF;
       
     
     END LOOP;  
   --END IF;
  
         json_helper.PUT_LINE( 
           json_helper.json_object_stop );
           
     RETURN v_interval;
  
  END;
   
  MEMBER FUNCTION  add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN VARCHAR2)
    RETURN NUMBER   
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value, v_result );
    
    RETURN v_result;
  END;

  MEMBER PROCEDURE  add_member(
    p_name IN VARCHAR2, 
    p_value IN VARCHAR2)  
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value,  v_result );
  END;

 MEMBER PROCEDURE  add_member(
    p_name IN VARCHAR2, 
    p_value IN VARCHAR2,
    p_member_id OUT NUMBER)   
  AS
  BEGIN
    SELF.num_elements := SELF.num_elements + 1;
    
    SELF.json_data.extend;
    
    SELF.json_data(SELF.num_elements) := json_member(
       SELF.num_elements,
       p_name,
       anydata.convertvarchar2(p_value)
    );
    
    p_member_id := SELF.num_elements;
    
  END;
   MEMBER FUNCTION add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN json)  
    RETURN NUMBER   
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value, v_result );
    RETURN v_result;
  END;

   MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN json)  
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value, v_result );
  END;

  
  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN json,
    p_member_id OUT NUMBER)    
  AS
  BEGIN
    SELF.num_elements := SELF.num_elements + 1;
    
    SELF.json_data.extend;
    
    SELF.json_data(SELF.num_elements) := json_member(
       SELF.num_elements,
       p_name,
       anydata.convertobject( p_value )
    );
    
    
    p_member_id := SELF.num_elements;
  END;

  
  MEMBER FUNCTION  add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN NUMBER)  
    RETURN NUMBER   
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value, v_result );
    RETURN v_result;

 END;
  
  MEMBER PROCEDURE  add_member(
    p_name IN VARCHAR2, 
    p_value IN NUMBER)  
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value, v_result );
  END;
  
  MEMBER PROCEDURE  add_member(
    p_name IN VARCHAR2, 
    p_value IN NUMBER,
    p_member_id OUT NUMBER)   
  AS
  BEGIN
    SELF.num_elements := SELF.num_elements + 1;
    
    SELF.json_data.extend;
    
    SELF.json_data(SELF.num_elements) := json_member(
       SELF.num_elements,
       p_name,
       anydata.convertnumber( p_value )
    );
    
    p_member_id := SELF.num_elements;
  END;
  
  MEMBER PROCEDURE  add_member(
    p_name IN VARCHAR2, 
    p_value IN BOOLEAN)  
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value, v_result );
  END;
  MEMBER FUNCTION  add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN BOOLEAN)  
    RETURN NUMBER   
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value, v_result );
    RETURN v_result;
  END;
  
  MEMBER PROCEDURE  add_member(
    p_name IN VARCHAR2, 
    p_value IN BOOLEAN,
    p_member_id OUT NUMBER)   
  AS
    v_bool json_bool;
  BEGIN
  
    v_bool := json_helper.make_boolean( p_value );
    
    SELF.num_elements := SELF.num_elements + 1;
    
    SELF.json_data.extend;
    
    SELF.json_data(SELF.num_elements) := json_member(
       SELF.num_elements,
       p_name,
       anydata.convertobject( v_bool )
    );
    
    p_member_id := SELF.num_elements;
  END;
  
  MEMBER PROCEDURE  add_member(
    p_name IN VARCHAR2, 
    p_value IN json_null)  
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value, v_result );
  END;
  MEMBER FUNCTION  add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN json_null)  
    RETURN NUMBER   
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value, v_result );
    RETURN v_result;
  END;
  
  MEMBER PROCEDURE  add_member(
    p_name IN VARCHAR2, 
    p_value IN json_null,
    p_member_id OUT NUMBER)   
  AS
    v_bool json_bool;
  BEGIN
  
    SELF.num_elements := SELF.num_elements + 1;
    
    SELF.json_data.extend;
    
    SELF.json_data(SELF.num_elements) := json_member(
       SELF.num_elements,
       p_name,
       anydata.convertobject( p_value )
    );
    
    p_member_id := SELF.num_elements;
  END;
  
  MEMBER PROCEDURE  add_member(
    p_name IN VARCHAR2, 
    p_value IN json_member)  
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value, v_result );
  END;
  
  MEMBER FUNCTION  add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN json_member)  
    RETURN NUMBER   
  AS
    v_result NUMBER;
  BEGIN
  
    add_member( p_name, p_value, v_result );
    RETURN v_result;
  END;
  
    
  MEMBER PROCEDURE  add_member(
    p_name IN VARCHAR2, 
    p_value IN json_member,
    p_member_id OUT NUMBER) 
  AS
  BEGIN
    SELF.num_elements := SELF.num_elements + 1;
    
    SELF.json_data.extend;
    
    SELF.json_data(SELF.num_elements) := json_member(
       SELF.num_elements,
       p_name,
       anydata.convertobject( p_value )
    );
    
    p_member_id := SELF.num_elements;
  END;
  
  MEMBER FUNCTION add_array(
    SELF IN OUT json,
    p_name IN VARCHAR2 )
    RETURN NUMBER
  AS
    v_result PLS_INTEGER;
  BEGIN
    add_array( p_name, v_result );
    RETURN v_result;
  END;  
   

  MEMBER PROCEDURE add_array(
    p_name IN VARCHAR2,
    p_array_id OUT NUMBER)    
  AS
    v_json_element_array json_element_array := json_element_array();
  BEGIN
  
    SELF.num_elements := SELF.num_elements + 1;
    
    SELF.json_data.extend;
    
    SELF.json_data(SELF.num_elements) := json_member(
       SELF.num_elements,
       p_name,
       anydata.convertcollection( v_json_element_array )
    );
    
    p_array_id := SELF.num_elements;

  END;
  
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN VARCHAR2 )
  AS
    v_result PLS_INTEGER;
  BEGIN
    add_array_element(p_array_id, p_value, v_result);
  END;    
  
  MEMBER FUNCTION add_array_element(
    SELF IN OUT json,
    p_array_id IN NUMBER,
    p_value IN VARCHAR2 )
    RETURN PLS_INTEGER
  AS
    v_result PLS_INTEGER;
  BEGIN
    add_array_element(p_array_id, p_value, v_result);
    RETURN v_result;
  END;    
  
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN VARCHAR2,
    p_element_id OUT NUMBER)    
  AS
    v_json_element json_element;
    v_json_element_array json_element_array;
    x number;
  BEGIN
  
    x := SELF.json_data(p_array_id).member_data.getcollection(v_json_element_array) ;
    
    x := nvl(v_json_element_array.LAST,0) + 1;  
    
    v_json_element := json_element(
         x,
         anydata.convertvarchar2(p_value) );
     
    v_json_element_array.extend;
    
    v_json_element_array(x) :=  v_json_element;
        
    SELF.json_data(p_array_id).member_data := anydata.convertcollection( v_json_element_array );
    
    p_element_id := x;

  END;
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN NUMBER )
  AS
    v_result PLS_INTEGER;
  BEGIN
    add_array_element(p_array_id, p_value, v_result);
  END;    
  
  MEMBER FUNCTION add_array_element(
    SELF IN OUT json,
    p_array_id IN NUMBER,
    p_value IN NUMBER )
    RETURN PLS_INTEGER
  AS
    v_result PLS_INTEGER;
  BEGIN
    add_array_element(p_array_id, p_value, v_result);
    RETURN v_result;
  END;    
  
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN NUMBER,
    p_element_id OUT NUMBER)   
    AS
    v_json_element json_element;
    v_json_element_array json_element_array;
    x number;
  BEGIN
  
    x := SELF.json_data(p_array_id).member_data.getcollection(v_json_element_array) ;
    
    x := nvl(v_json_element_array.LAST,0) + 1;  
    
    v_json_element := json_element(
         x,
         anydata.convertnumber(p_value) );
     
    v_json_element_array.extend;
    
    v_json_element_array(x) :=  v_json_element;
        
    SELF.json_data(p_array_id).member_data := anydata.convertcollection( v_json_element_array );
    
    p_element_id := x;

  END;
  
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN BOOLEAN )
  AS
    v_result PLS_INTEGER;
  BEGIN
    add_array_element(p_array_id, p_value, v_result);
  END;    
  
  MEMBER FUNCTION add_array_element(
    SELF IN OUT json,
    p_array_id IN NUMBER,
    p_value IN BOOLEAN )
    RETURN PLS_INTEGER
  AS
    v_result PLS_INTEGER;
  BEGIN
    add_array_element(p_array_id, p_value, v_result);
    RETURN v_result;
  END;    
  
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN BOOLEAN,
    p_element_id OUT NUMBER)   
  AS
    v_json_element json_element;
    v_json_element_array json_element_array;
    x number;
    v_value json_bool;
  BEGIN
  
    x := SELF.json_data(p_array_id).member_data.getcollection(v_json_element_array) ;
    
    x := nvl(v_json_element_array.LAST,0) + 1;  
    
    v_json_element := json_element(
         x,
         anydata.convertobject(json_helper.make_boolean(p_value)) );
     
    v_json_element_array.extend;
    
    v_json_element_array(x) :=  v_json_element;
        
    SELF.json_data(p_array_id).member_data := anydata.convertcollection( v_json_element_array );
    
    p_element_id := x;

  END;
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN json )
  AS
    v_result PLS_INTEGER;
  BEGIN
    add_array_element(p_array_id, p_value, v_result);
  END;    
  
  MEMBER FUNCTION add_array_element(
    SELF IN OUT json,
    p_array_id IN NUMBER,
    p_value IN json )
    RETURN PLS_INTEGER
  AS
    v_result PLS_INTEGER;
  BEGIN
    add_array_element(p_array_id, p_value, v_result);
    RETURN v_result;
  END;    
  
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN json,
    p_element_id OUT NUMBER)   
    
  AS
    v_json_element json_element;
    v_json_element_array json_element_array;
    x number;
  BEGIN
  
    x := SELF.json_data(p_array_id).member_data.getcollection(v_json_element_array) ;
    
    x := nvl(v_json_element_array.LAST,0) + 1;  
    
    v_json_element := json_element(
         x,
         anydata.convertobject(p_value) );
     
    v_json_element_array.extend;
    
    v_json_element_array(x) :=  v_json_element;
        
    SELF.json_data(p_array_id).member_data := anydata.convertcollection( v_json_element_array );

    p_element_id := x;

  END;
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN json_null)
  AS
    v_result PLS_INTEGER;
  BEGIN
    add_array_element(p_array_id, p_value, v_result);
  END;    
  
  MEMBER FUNCTION add_array_element(
    SELF IN OUT json,
    p_array_id IN NUMBER,
    p_value IN json_null )
    RETURN PLS_INTEGER
  AS
    v_result PLS_INTEGER;
  BEGIN
    add_array_element(p_array_id, p_value, v_result);
    RETURN v_result;
  END;    
  
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN json_null,
    p_element_id OUT NUMBER)   
  AS
    v_json_element json_element;
    v_json_element_array json_element_array;
    x number;
    v_value json_bool;
  BEGIN
  
    x := SELF.json_data(p_array_id).member_data.getcollection(v_json_element_array) ;
    
    x := nvl(v_json_element_array.LAST,0) + 1;  
    
    v_json_element := json_element(
         x,
         anydata.convertobject(json_null) );
     
    v_json_element_array.extend;
    
    v_json_element_array(x) :=  v_json_element;
        
    SELF.json_data(p_array_id).member_data := anydata.convertcollection( v_json_element_array );
    
    p_element_id := x;

  END;
    


    
 END;
 /
 
 sho err
 
 exit
 