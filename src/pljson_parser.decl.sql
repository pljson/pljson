create or replace package pljson_parser as
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

  /** Internal type for processing. */
  /* scanner tokens:
    '{', '}', ',', ':', '[', ']', STRING, NUMBER, TRUE, FALSE, NULL
  */
  type rToken IS RECORD (
    type_name VARCHAR2(7),
    line PLS_INTEGER,
    col PLS_INTEGER,
    data VARCHAR2(32767),
    data_overflow clob); -- max_string_size

  type lTokens is table of rToken index by pls_integer;
  type json_src is record (len number, offset number, src varchar2(32767), s_clob clob);

  json_strict boolean not null := false;

  function next_char(indx number, s in out nocopy json_src) return varchar2;
  function next_char2(indx number, s in out nocopy json_src, amount number default 1) return varchar2;
  function parseObj(tokens lTokens, indx in out nocopy pls_integer) return pljson;

  function prepareClob(buf in clob) return pljson_parser.json_src;
  function prepareVarchar2(buf in varchar2) return pljson_parser.json_src;
  function lexer(jsrc in out nocopy json_src) return lTokens;
  procedure print_token(t rToken);

  /**
   * <p>Primary parsing method. It can parse a JSON object.</p>
   *
   * @return An instance of <code>pljson</code>.
   * @throws PARSER_ERROR -20101 when invalid input found.
   * @throws SCANNER_ERROR -20100 when lexing fails.
   */
  function parser(str varchar2) return pljson;
  function parse_list(str varchar2) return pljson_list;
  function parse_any(str varchar2) return pljson_value;
  function parser(str clob) return pljson;
  function parse_list(str clob) return pljson_list;
  function parse_any(str clob) return pljson_value;
  procedure remove_duplicates(obj in out nocopy pljson);
  function get_version return varchar2;

end pljson_parser;
/
show err