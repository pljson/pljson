--types
grant execute on json to public;
create or replace public synonym json for json;
grant execute on json_list to public;
create or replace public synonym json_list for json_list;
grant execute on json_value to public;
create or replace public synonym json_value for json_value;
grant execute on json_value_array to public;
create or replace public synonym json_value_array for json_value_array;
--packages
grant execute on json_ext to public;
create or replace public synonym json_ext for json_ext;
grant execute on json_parser to public;
create or replace public synonym json_parser for json_parser;
grant execute on json_printer to public;
create or replace public synonym json_printer for json_printer;


