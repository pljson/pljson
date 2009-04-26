CREATE OR REPLACE TYPE json AS OBJECT (

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

  json_data json_member_array,
  
  num_elements NUMBER,
  
  CONSTRUCTOR FUNCTION json
    RETURN SELF AS RESULT,
    
  CONSTRUCTOR FUNCTION json(
    p_name IN VARCHAR2, 
    p_value IN VARCHAR2)
    RETURN SELF AS RESULT,
    
  CONSTRUCTOR FUNCTION json(p_data IN XMLType)
    RETURN SELF AS RESULT,
  
 CONSTRUCTOR FUNCTION json(p_data IN json_member_array)
    RETURN SELF AS RESULT,
  
  CONSTRUCTOR FUNCTION json(p_data IN CLOB)
    RETURN SELF AS RESULT,
  
  CONSTRUCTOR FUNCTION json(p_data IN VARCHAR2)
    RETURN SELF AS RESULT,
  
  MEMBER FUNCTION getString(p_indent IN NUMBER DEFAULT 0)
    RETURN VARCHAR2,

  MEMBER FUNCTION getCLOB(p_indent IN NUMBER DEFAULT 0)
    RETURN CLOB,

  MEMBER FUNCTION getXML(p_indent IN NUMBER DEFAULT 0)
    RETURN XMLType,
  
  MEMBER FUNCTION print(p_indent IN NUMBER DEFAULT 0)
    RETURN NUMBER,  

  MEMBER PROCEDURE print(p_indent IN NUMBER DEFAULT 0),  

  MEMBER FUNCTION writer(p_indent IN NUMBER DEFAULT 0)
    RETURN NUMBER,
   
  MEMBER PROCEDURE  add_member(
    p_name IN VARCHAR2, 
    p_value IN VARCHAR2),

  MEMBER FUNCTION  add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN VARCHAR2)
    RETURN NUMBER,
    
  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN VARCHAR2,
    p_member_id OUT NUMBER)    ,
    
  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN NUMBER),

  MEMBER FUNCTION  add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN NUMBER)  
    RETURN NUMBER   ,

  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN NUMBER,
    p_member_id OUT NUMBER)    ,
    
  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN BOOLEAN),
    
  MEMBER FUNCTION  add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN BOOLEAN)  
    RETURN NUMBER   ,

  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN BOOLEAN,
    p_member_id OUT NUMBER)    ,
    
  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN json_null),
    
  MEMBER FUNCTION  add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN json_null)  
    RETURN NUMBER   ,

  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN json_null,
    p_member_id OUT NUMBER)    ,
    
  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN json_member),
 
  MEMBER FUNCTION  add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN json_member)  
    RETURN NUMBER   ,
    
  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN json_member,
    p_member_id OUT NUMBER)    ,
    
  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN json),
    
  MEMBER FUNCTION add_member(
    SELF IN OUT json,
    p_name IN VARCHAR2, 
    p_value IN json)  
    RETURN NUMBER   ,

  MEMBER PROCEDURE add_member(
    p_name IN VARCHAR2, 
    p_value IN json,
    p_member_id OUT NUMBER)    ,
   
  MEMBER PROCEDURE add_array(
    p_name IN VARCHAR2,
    p_array_id OUT NUMBER),   

  MEMBER FUNCTION add_array(
    SELF IN OUT json,
    p_name IN VARCHAR2 )
    RETURN NUMBER,   
    
  MEMBER FUNCTION add_array_element(
    SELF IN OUT json,
    p_array_id IN NUMBER,
    p_value IN VARCHAR2)
    RETURN PLS_INTEGER ,
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN VARCHAR2,
    p_element_id OUT NUMBER)   ,
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN VARCHAR2)   ,
    
  MEMBER FUNCTION add_array_element(
    SELF IN OUT json,
    p_array_id IN NUMBER,
    p_value IN NUMBER)
    RETURN PLS_INTEGER ,
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN NUMBER,
    p_element_id OUT NUMBER)   ,
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN NUMBER)   ,
    
  MEMBER FUNCTION add_array_element(
    SELF IN OUT json,
    p_array_id IN NUMBER,
    p_value IN BOOLEAN)
    RETURN PLS_INTEGER ,
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN BOOLEAN,
    p_element_id OUT NUMBER)   ,
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN BOOLEAN)   ,
    
  MEMBER FUNCTION add_array_element(
    SELF IN OUT json,
    p_array_id IN NUMBER,
    p_value IN json)
    RETURN PLS_INTEGER ,
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN json,
    p_element_id OUT NUMBER)   ,
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN json)   ,
    
  MEMBER FUNCTION add_array_element(
    SELF IN OUT json,
    p_array_id IN NUMBER,
    p_value IN json_null)
    RETURN PLS_INTEGER ,
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN json_null,
    p_element_id OUT NUMBER)   ,
    
  MEMBER PROCEDURE add_array_element(
    p_array_id IN NUMBER,
    p_value IN json_null)  
      
 );
 /
 sho err
 
 exit
 
 
 