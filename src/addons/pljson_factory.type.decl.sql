/*
  Copyright (c) 2018 Borodulin Maksim (github.com/boriborm)

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

CREATE OR REPLACE 
TYPE pljson_factory force as object (

  j pljson,
  parent pljson,

  constructor function pljson_factory return self as result,
  constructor function pljson_factory (json in out nocopy pljson) return self as result,
  constructor function pljson_factory (json in out nocopy pljson, parentJson pljson) return self as result,

  member function get return pljson,

  member function p(pair_name varchar2, pair_value varchar2, position pls_integer default null) return pljson_factory,
  member function p(pair_name varchar2, pair_value number, position pls_integer default null) return pljson_factory,
  member function p(pair_name varchar2, pair_value boolean, position pls_integer default null) return pljson_factory,
  member function p(pair_name varchar2, pair_value binary_double, position pls_integer default null)return pljson_factory,
  member function p(pair_name varchar2, pair_value pljson, position pls_integer default null) return pljson_factory,
  member function p(pair_name varchar2, pair_value pljson_list, position pls_integer default null) return pljson_factory,
  
  member function p(pair_name varchar2, pair_value pljson_factory, position pls_integer default null) return pljson_factory,

  member function get_json(pair_name varchar2) return pljson_factory,

  member function g(pair_name varchar2, value out varchar2) return pljson_factory,
  member function g(pair_name varchar2, value out number) return pljson_factory,
  member function g(pair_name varchar2, value out boolean) return pljson_factory,
  member function g(pair_name varchar2, value out date, format in varchar2) return pljson_factory,
  member function g(pair_name varchar2, value out pljson) return pljson_factory,
  member function g(pair_name varchar2, value out pljson_list) return pljson_factory,

  member function up return pljson_factory,

  static procedure getter(factory in pljson_factory)

) not final
/
