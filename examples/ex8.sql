/*
This software has been released under the MIT license:

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
/*
  Using the JSON Path part of the JSON_EXT package
*/

set serveroutput on;
declare
  obj json := json(
'{
  "a" : true,
  "b" : [1,2,"3"],
  "c" : {
    "d" : [["array of array"], null, { "e": 7913 }]
  }
}');

begin
  /* What is the PL/JSON definition of JSON Path? */
  -- In languages such as javascript and python, one can interact with a json 
  -- structure in a sensible manner. But in PL/JSON we have to extract each 
  -- element as anydata, inspect the type and convert it. Basically what we want 
  -- to, is to extract an element without having to do any conversion. We know of
  -- more advanced implementations (http://goessner.net/articles/JsonPath/),
  -- but it lacks a formal grammar description and the use of regular expressions
  -- in the implementation is quite scary. The following examples explains how
  -- useful JSON Path is to PL/JSON.
   
  obj.print;
  -- If it exists, we want to get the 3rd element of member b, but only if it is
  -- an integer. Otherwise we want the e value of the 3rd element of d (also int).
  -- The code should be secure (no exceptions)
  /* Old way - still valid though*/
  declare 
    printme number := null;
    temp json_list;
    tempdata json_value;
    tempobj json;
  begin
    if(obj.exist('b')) then
      if(obj.get('b').is_array) then
        temp := json_list(obj.get('b'));
        tempdata := temp.get(3); --return null on outofbounds
        if(tempdata is not null) then
          if(tempdata.is_number) then
            printme := tempdata.get_number;
          end if;
        end if;
      end if; 
    end if;
    if(printme is null) then
      if(obj.exist('c')) then
        tempdata := obj.get('c');
        if(tempdata.is_object) then
          tempobj := json(tempdata);
          if(tempobj.exist('d')) then
            tempdata := tempobj.get('d');
            if(tempdata.is_array) then
              temp := json_list(tempdata);
              tempdata := temp.get(3);
              if(tempdata.is_object) then
                tempobj := json(tempdata);
                tempdata := tempobj.get('e');
                if(tempdata is not null and tempdata.is_number) then
                  printme := tempdata.get_number;
                end if;
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
    if(printme is not null) then dbms_output.put_line(printme); end if;
  end;

  --now the JSON Path way:
  declare 
    printme number := null;
  begin
    printme := json_ext.get_number(obj, 'b[3]');
    if(printme is null) then printme := json_ext.get_number(obj, 'c.d[3].e'); end if;
    if(printme is not null) then dbms_output.put_line(printme); end if;
  end;
  --see the point???

  /* About JSON Path for PL/JSON */
  -- it never raises an exception (null is returned instead)
  -- arrays are 1-indexed 
  -- use dots to navigate through the json scopes.
  -- the empty string as path returns the entire json object.
  -- JSON Path only work with JSON as input.
  -- 7 get types are supported: string, number, bool, null, json, json_list and date!
  -- spaces inside [ ] are not important, but is important otherwise
  
  obj := json('{" a ": "String", "b": false, "c": null, "d":{}, "e":[],"f": "2009-09-01 00:00:00", "g":-789456}');  
  dbms_output.put_line(json_ext.get_string(obj, ' a '));
  if(json_ext.get_json_value(obj, 'c') is not null) then dbms_output.put_line('null'); end if;
  dbms_output.put_line(json_ext.get_json(obj, 'd').to_char(false));
  dbms_output.put_line(json_ext.get_json_list(obj, 'e').to_char);
  dbms_output.put_line(json_ext.get_date(obj, 'f'));
  dbms_output.put_line(json_ext.get_number(obj, 'g'));

end;
/