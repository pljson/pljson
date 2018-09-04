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

declare
 j pljson;
 a varchar2(100);
 b number;
 d date;
 c varchar2(100);
 j2 pljson;
begin
 j:=pljson_factory()
    .p('a','a')
    .p('b',123)
    .p('d',to_char(sysdate,'dd.mm.rrrr'))
    .p('c',
        pljson_factory()
        .p('c','c')
    )
    .get();
 dbms_output.put_line(j.to_char());
 
 pljson_factory.getter(
    pljson_factory(j)
        .g('a',a)        
        .g('c', j2)
        .get_json('c')
            .g('c', c)
        .up()
        .g('b',b)
        .g('d',d,'dd.mm.rrrr')
 );

 dbms_output.put_line('a = '||a);
 dbms_output.put_line('b = '||b); 
 dbms_output.put_line(j2.to_char());  
 dbms_output.put_line('c = '||c); 
 dbms_output.put_line('d = '||d); 
end;

