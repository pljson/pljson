create or replace package json_path as
  function json_path(obj JSON, expr varchar2, args varchar2 default 'VALUE') return json_list;
end json_path;
/

create or replace package body json_path as
  type innerobj is record (obj json, v_result_type varchar2(5), v_result json_list);

  function json_path(obj JSON, expr varchar2, args varchar2 default 'VALUE') return json_list AS
    v_inner innerobj;
  begin
    v_inner.obj := obj;
    if(args not in ('VALUE', 'PATH')) then
      raise_application_error(-20104, 'VALUE or PATH expected as argument');
    end if;
    v_inner.v_result_type := args;
    v_inner.v_result := json_list();
    return v_inner.v_result;
  end json_path;

end json_path;
/
