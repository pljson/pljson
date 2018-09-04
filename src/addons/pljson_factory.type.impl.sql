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

TYPE BODY pljson_factory as

  constructor function pljson_factory return self as result as
  begin
    self.j:=pljson();
    self.parent:=null;
    return;
  end;

  constructor function pljson_factory (json in out nocopy pljson) return self as result as
  begin
    self.j:=json;
    self.parent:=null;
    return;
  end;

  constructor function pljson_factory (json in out nocopy pljson, parentJson pljson) return self as result as
  begin
    self.j:=json;
    self.parent:=parentJson;
    return;
  end;

  member function get return pljson as
  begin
    return self.j;
  end;
  member function p(pair_name varchar2, pair_value varchar2, position pls_integer default null) return pljson_factory as
    j pljson:=self.j;
  begin
    j.put(pair_name, pljson_value(pair_value), position);
    return pljson_factory(j);
  end;

  member function p(pair_name varchar2, pair_value number, position pls_integer default null) return pljson_factory as
    j pljson:=self.j;
  begin
    j.put(pair_name, pljson_value(pair_value), position);
    return pljson_factory(j);
  end;

  member function p(pair_name varchar2, pair_value boolean, position pls_integer default null) return pljson_factory as
    j pljson:=self.j;
  begin
    j.put(pair_name, pljson_value(pair_value), position);
    return pljson_factory(j);
  end;

  member function p(pair_name varchar2, pair_value binary_double, position pls_integer default null) return pljson_factory as
    j pljson:=self.j;
  begin
    j.put(pair_name, pljson_value(pair_value), position);
    return pljson_factory(j);
  end;

  member function p(pair_name varchar2, pair_value pljson_factory, position pls_integer default null) return pljson_factory as
    j pljson:=self.j;
  begin
    j.put(pair_name, pair_value.get(), position);
    return pljson_factory(j);
  end;

  member function p(pair_name varchar2, pair_value pljson, position pls_integer default null) return pljson_factory as
    j pljson:=self.j;
  begin
    j.put(pair_name, pair_value, position);
    return pljson_factory(j);
  end;

  member function p(pair_name varchar2, pair_value pljson_list, position pls_integer default null) return pljson_factory as
    j pljson:=self.j;
  begin
    j.put(pair_name, pair_value, position);
    return pljson_factory(j);
  end;

  member function g(pair_name varchar2, value out varchar2) return pljson_factory as
  begin
    value:=self.j.get(pair_name).get_string();
    return self;
  end;
  member function g(pair_name varchar2, value out number) return pljson_factory as
  begin
   value:=self.j.get(pair_name).get_number();
   return self;
  end;

  member function g(pair_name varchar2, value out boolean) return pljson_factory as
  begin
   value:=self.j.get(pair_name).get_bool();
   return self;
  end;
  
  member function g(pair_name varchar2, value out date, format in varchar2) return pljson_factory as
  begin
   value:=to_date(self.j.get(pair_name).get_string(), format);
   return self;
  end;

  member function g(pair_name varchar2, value out pljson) return pljson_factory as
  begin
   value:=pljson(self.j.get(pair_name));
   return self;
  end;

  member function g(pair_name varchar2, value out pljson_list) return pljson_factory as
  begin
   value:=pljson_list(self.j.get(pair_name));
   return self;
  end;

  member function get_json(pair_name varchar2) return pljson_factory as
    j2 pljson:=pljson(self.j.get(pair_name));
  begin
    return pljson_factory(json=>j2,parentJson=> j);
  end;

  member function up return pljson_factory as
    parent pljson:=self.parent;
  begin
    if parent is not null then
        return pljson_factory(parent);
    end if;
    return null;
  end;
  
  static procedure getter(factory in pljson_factory) as
  begin
    null;
  end;
end;
/
