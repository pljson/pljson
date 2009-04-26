
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


set linesize 9999
SET SERVEROUTPUT ON

DECLARE
  v_json json;
  v_json2 json;
   
  v_arr_id NUMBER;
  v_ele_id NUMBER;
BEGIN

  -- Create the first object instance
  v_json := json();
  
  -- Assign some members to the object
  -- first is a string memberk
  v_json.add_member(
        p_name => 'title', 
        p_value => 'SQL Starter');
        
  -- a null member      
  v_json.add_member(
        p_name => 'author', 
        p_value => json_helper.null_value);
        
  -- a boolean member      
  v_json.add_member(
       p_name => 'monkeyman', 
       p_value => false);
   
  -- a number member    
  v_json.add_member(
       p_name => 'age', 
       p_value => 21);

  -- Add an array to the object
  v_json.add_array(
       p_name => 'myarray', 
       p_array_id => v_arr_id );

  -- Add some elements to the array
  -- a string element
  v_json.add_array_element( 
       p_array_id => v_arr_id, 
       p_value => 'hello', 
       p_element_id => v_ele_id );
       
  -- a boolean element     
  v_json.add_array_element( 
       p_array_id => v_arr_id, 
       p_value => true, 
       p_element_id => v_ele_id );
       
  -- a number element     
  v_json.add_array_element( 
       p_array_id => v_arr_id, 
       p_value => 99, 
       p_element_id => v_ele_id );
       
  -- a null element     
  v_json.add_array_element( 
       p_array_id => v_arr_id, 
       p_value => json_null, 
       p_element_id => v_ele_id );

  -- create a new json object instance
  v_json2 := json();
  
  -- a varchra2 memeber to the new object
  v_json2.add_member(
       p_name => 'what do you want', 
       p_value => 'de nada');

  -- a number memeber to the new object
  v_json2.add_member(
       p_name => '2 members is enough to test', 
       p_value => 198364556.32344393);

  -- Add another array and sone elements
  v_json.add_array(
       p_name => 'myarraywithjson', 
       p_array_id => v_arr_id );
       
  v_json.add_array_element( 
       p_array_id => v_arr_id, 
       p_value => 'goodbye', 
       p_element_id => v_ele_id );
       
  -- Add a json object as an element of the array     
  v_json.add_array_element( 
       p_array_id => v_arr_id, 
       p_value => v_json2, 
       p_element_id => v_ele_id );
       
  -- Finish off that array with a number element     
  v_json.add_array_element( 
       p_array_id => v_arr_id, 
       p_value => 99, 
       p_element_id => v_ele_id );
  
  -- clear the second json object by create a new instance
  v_json2 := json();


  -- Add a JSON member to the final object 
  -- the json being added is the first object with all of the  
  -- members and array
  -- "working"  becomes the highest level member of the object
  v_json2.add_member(
       p_name => 'working', 
       p_value => v_json);
  
  -- USe the print proc to display dbms_output
  DBMS_OUTPUT.PUT_LINE('PRINT Output - ');
  v_json2.print();
  
  DBMS_OUTPUT.PUT_LINE('--------------------------------');
  DBMS_OUTPUT.PUT_LINE('--------------------------------');

  -- Use dbms_output to display stringified json
  DBMS_OUTPUT.PUT_LINE('String Output - ');
  DBMS_OUTPUT.PUT_LINE(v_json2.getString);
END;
/

exit

  