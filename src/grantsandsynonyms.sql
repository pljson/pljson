--types
grant execute on json to public;
create or replace public synonym json for json;
grant execute on json_list to public;
create or replace public synonym json_list for json_list;
grant execute on json_value to public;
create or replace public synonym json_value for json_value;
grant execute on json_value_array to public;
create or replace public synonym json_value_array for json_value_array;
grant execute on json_table to public;
create or replace public synonym json_table for json_table;
--packages
grant execute on json_ext to public;
create or replace public synonym json_ext for json_ext;
grant execute on json_parser to public;
create or replace public synonym json_parser for json_parser;
grant execute on json_printer to public;
create or replace public synonym json_printer for json_printer;
grant execute on json_dyn to public;
create or replace public synonym json_dyn for json_dyn;
grant execute on json_ml to public;
create or replace public synonym json_ml for json_ml;
grant execute on json_xml to public;
create or replace public synonym json_xml for json_xml;
grant execute on json_util_pkg to public;
create or replace public synonym json_util_pkg for json_util_pkg;
grant execute on json_helper to public;
create or replace public synonym json_helper for json_helper;