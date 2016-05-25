Version: 1.0.6
  + Many thanks to the people who have contributed to this release
    (listed in chronological commit order):
    + Brian Shaver
    + Carlo Sirna
    + SigmaEpsilon
    + Borodulin Maxim
    + dsnz
    + E.I.Sarmas
  + Project build environment added
  + Project files re-organized
  + Tests fixed to run correctly
  + `escapeChar` and `escapeString` refactored
  + 12c name clashes fixed
  + Lots of code cleanups and bugs fixed

Version: 1.0.5
  + Fixed error with \r and \f in parser and printer

Version: 1.0.4
  + Error with empty_blob in json_dyn
  + New optional package: JSON_HELPER - Set operations.
  + JSON_AC.sql: Wrapper-package to enable autocompletion.

Version: 1.0.3
  + UTF8 fix in json_printer.
  + Small change in json_dyn_sql package.

Version: 1.0.2
  + Fix for number parsing for various nls settings
  + Enabled sys_refcursor in json_dyn (11g only)

Version: 1.0.1
  + forgot to commit example 18 and 19 to svn
  + fixed escape error in json_dyn package

Version: 1.0.0
  + json_list api has been changed
  + slight changes in json_value api + clob support
  + json_printer bug fixes
  + json_path bugfix
  + json_parser clob enhancement
  + json_printer clob enhancement
  + json_parser can now parse functions with comment-tag
  + json_printer emits functions with comment-tag
  + json_ext store blob in one base64 string
  + json_dyn now supports clobs and blobs
  + backwards compatibility in form of commented code in json_list.

Version: 0.9.6
  + Json_dyn addon can now bind variables
  + Fixed decode base64 error in json_ext
  + Option to erase clob in to_clob methods
  + Better UTF8 support
  + Added base 0 or 1 option in json path implementation
  + Path_remove added to json and json_list
  + Path_put error in json_list fixed
  + Changed anydata to sys.anydata

Version: 0.9.5
  + Bug fix: In addon json_util_pkg - fixed number issue, new stylesheet added.
  + Added a script to create synonyms and grants.
  + Added support for outputting JSONP - @James Sumners

Version: 0.9.4
  + Bug fix: clob list og numbers was not formatted correctly
  + Added printer option to escape solidus (default is false)
  + Added a max_chars_per_line option to the printer functions (to_char, to_clob, print)
  + Changed print procedures to use clob instead of varchar2
  + Added a htp function to json, json_list and json_value

Version: 0.9.3
  + Bug fix: incorrect json emitted when facing a number between -1 and 1 (not 0)
  + Added support for inheritance.
  + Fixed addon json_dyn to use json_ext.format_string instead of nls params
  + Fixed version function

Version: 0.9.2
  + Added set_elem to JSON_LIST
  + Added path_put methods to JSON and JSON_LIST
  + Fixed a bug in addon json_util_pkg
  + Fixed parser bug: commas where not nessesary in json objects
  + Added and corrected tests.

Version: 0.9.1
  + Strings are now stored unescaped. Escaped when using to_char.
  + Parser extended with names grammar, singlequote strings and /**/ comments.
  + Addons modules are: json_ml, json_dyn, json_util_pkg
  + JSON PATH rewritten with formal grammar.
  + Path selector in JSON and JSON_LIST
  + New method valueof can emit unescaped content to a string.
  + Empty strings can be used as a key in JSON.
  + Documentation.
  + Option of not to escape a string - enables the printer to emit javascript functions
  + More examples.

Version: 0.9.0
WARNING: You cannot do an easy upgrade because of changes in the API
  + Rewrote the API to increase speed and simplicity
  + 6 new methods to the json object: get_keys, get_values, index_of, get(indx), check_duplicate, remove_duplicates
  + New type: json_value - to hold the variables. Hooked to the printer. (anydata is now hidden away).
  + Added binary support through base64 in the json_ext package
  + New package json_dyn: Build json structures dynamically from selects (number, varchar2 and date fields are supported)
  + Parser can now parse any valid json value: json_parser.parse_any (accepts object, array, string, number, boolean, null)
  + Parserspeed has been improved
  + Object procedures are now faster due to the 'in out nocopy' directive
  + Cast from json_value to json or json_list in constructor
  + json and json_list can be converted to json_value with the function to_json_value.
  + Added 5 examples
  + Planning to create a wiki rather than update the documentation.

Version: 0.8.6
  + Added support for windows linebreak see json_printer

Version: 0.8.5
  + Fix in uninstall.sql (11g error)
  + Fix in simpletypes.sql (11g error)
  + Added prettyprint capabilities to anydata type
  + Added hooks to new printing cap. in json_ext (pp, pp_htp)
  + Added example/ex12.sql

Version: 0.8.4
  + Added clob methods
  + Enhanced the json-path to support bracket select in json objects
  + Updated documentation
  + Added one example file
  + Added NVL to various unittests.

Version: 0.8.3
  + Added optional compact output
  + four parser-errors catched.
  + Added a simple JSON Path implementation. You can get, put and remove with path arguments.
  + Added 16 unittests
  + Added 3 example files.
  + Updated documentation
  + Variable indentation in pretty printer

Version: 0.8.2
  + Bug fix: unicode character error in parser.
  + Documentation was edited by Wayne IV Mike.
  + Changes @ to @@ in the install script. That makes PL/JSON easier to use in other products.

Version: 0.8.1
  + Documentation is added
  + API: put and add methods now checks for null value.
    Stores JSON_NULL if null was found.

Version: 0.8
  + API is entirely rewritten
  + Memory Issue is solved
  + Parser is replaced (empty and nested arrays are now supported)
  + New pretty-printer
  + Exception handling is better now
  + A testsuite has been added
  + Many examples is available
  + An extension-package makes date-values possible
  + Version: 0.6
  + Added support for creating JSON from text input
  + Version 0.5
  + Initial release
  + Includes a JSON data type
  + Can create tables and columns of JSON
  + Supports API creation of JSON data type
