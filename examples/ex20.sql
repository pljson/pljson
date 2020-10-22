/* retrieving sql results as json clob */
set serveroutput on;
create or replace function ufx_plson_get_json_from_sql (i_sql in varchar2)
return clob
as
  -- Local variables here
  tstjson_list pljson_list;
  l_Result_json_clob clob;
begin
  -- Test statements here
  dbms_lob.createtemporary(l_Result_json_clob, true);

  tstjson_list := pljson_util_pkg.sql_to_json(i_sql);
  tstjson_list.to_clob(l_Result_json_clob);

  return l_Result_json_clob;
exception
  when others then raise;
end;
/
/* example */
select ufx_plson_get_json_from_sql (i_sql =>
          q'[ select sysdate, systimestamp, user from dual]') sql_result_as_json
  from dual;
