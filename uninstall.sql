
  /*
  Copyright (c) 2010 Jonas Krogsboell

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

declare begin
  begin execute immediate 'drop package json_parser'; exception when others then null; end;
  begin execute immediate 'drop package json_printer'; exception when others then null; end;
  begin execute immediate 'drop package json_ext'; exception when others then null; end;
  begin execute immediate 'drop package json_dyn'; exception when others then null; end;
  begin execute immediate 'drop package json_ml'; exception when others then null; end;
  begin execute immediate 'drop package json_xml'; exception when others then null; end;
  begin execute immediate 'drop package json_util_pkg'; exception when others then null; end;
  begin execute immediate 'drop package json_helper'; exception when others then null; end;
  begin execute immediate 'drop package json_ac'; exception when others then null; end;
  begin execute immediate 'drop type json force'; exception when others then null; end;
  begin execute immediate 'drop type json_member_array force'; exception when others then null; end;
  begin execute immediate 'drop type json_member force'; exception when others then null; end;
  begin execute immediate 'drop type json_list force'; exception when others then null; end;
  begin execute immediate 'drop type json_element_array force'; exception when others then null; end;
  begin execute immediate 'drop type json_element force'; exception when others then null; end;
  begin execute immediate 'drop type json_bool force'; exception when others then null; end;
  begin execute immediate 'drop type json_null force'; exception when others then null; end;
  begin execute immediate 'drop type json_value_array force'; exception when others then null; end;
  begin execute immediate 'drop type json_value force'; exception when others then null; end;
end;
/
