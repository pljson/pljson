
set termout off
drop table pljson_testsuite;
set termout on
create table pljson_testsuite (
  suite_id number,
  suite_name varchar2(30),
  file_name varchar2(30),
  passed number,
  failed number,
  total number
);

create or replace package pljson_ut as

  /*
   *
   *  E.I.Sarmas (github.com/dsnz)   2017-07-22
   *  
   *  Simple unit test framework for pljson
   *  
   */

  suite_id number;
  suite_name varchar2(100);
  file_name varchar2(100);
  pass_count number;
  fail_count number;
  total_count number;
  
  case_name varchar2(100);
  case_pass number;
  case_fail number;
  case_total number;
  
  INDENT_1 varchar2(10) := '  ';
  INDENT_2 varchar2(10) := '    ';
  
  procedure testsuite(suite_name_ varchar2, file_name_ varchar2);
  procedure testcase(case_name_ varchar2);
  
  procedure pass(test_name varchar2 := null);
  procedure fail(test_name varchar2 := null);
  
  procedure assertTrue(b boolean, test_name varchar2 := null);
  procedure assertFalse(b boolean, test_name varchar2 := null);
  
  procedure testsuite_report;
  
  procedure startup;
  procedure shutdown;

end pljson_ut;
/

create or replace package body pljson_ut as
  
  /*
   *
   *  E.I.Sarmas (github.com/dsnz)   2017-07-22
   *  
   *  Simple unit test framework for pljson
   *  
   */
  
  procedure testsuite(suite_name_ varchar2, file_name_ varchar2) is
  begin
    suite_id := suite_id + 1;
    suite_name := suite_name_;
    file_name := file_name_;
    pass_count := 0;
    fail_count := 0;
    total_count := 0;
    dbms_output.put_line(suite_name_);
  end;
  
  procedure testcase(case_name_ varchar2) is
  begin
    case_name := case_name_;
    case_pass := 0;
    case_fail := 0;
    case_total := 0;
    dbms_output.put_line(INDENT_1 || case_name_);
  end;
  
  procedure pass(test_name varchar2 := null) is
  begin
    if (case_total = 0) then
      pass_count := pass_count + 1;
      total_count := total_count + 1;
    end if;
    case_pass := case_pass + 1;
    case_total := case_total + 1;
    if (test_name is not null) then
      dbms_output.put_line(INDENT_2 || 'OK: '|| test_name);
    end if;
  end;
  
  procedure fail(test_name varchar2 := null) is
  begin
    if (case_fail = 0) then
      fail_count := fail_count + 1;
      if (case_total = 0) then
        total_count := total_count + 1;
      else
        pass_count := pass_count - 1;
      end if;
    end if;
    case_fail := case_fail + 1;
    case_total := case_total + 1;
    if (test_name is not null) then
      dbms_output.put_line(INDENT_2 || 'FAILED: '|| test_name);
    end if;
  end;
  
  procedure assertTrue(b boolean, test_name varchar2 := null) is
  begin
    if (b) then
      pass(test_name);
    else
      fail(test_name);
    end if;
  end;
  
  procedure assertFalse(b boolean, test_name varchar2 := null) is
  begin
    if (not b) then
      pass(test_name);
    else
      fail(test_name);
    end if;
  end;
  
  procedure testsuite_report is
  begin
    dbms_output.put_line('');
    dbms_output.put_line(
      total_count || ' tests, '
      || pass_count || ' passed, '
      || fail_count || ' failed'
    );
    
    execute immediate 'insert into pljson_testsuite values (:1, :2, :3, :4, :5, :6)'
      using suite_id, suite_name, file_name, pass_count, fail_count, total_count;
  end;
  
  procedure startup is
  begin
    suite_id := 0;
    execute immediate 'truncate table pljson_testsuite';
  end;
  
  procedure shutdown is
  begin
    commit;
    
    dbms_output.put_line('');
    for rec in (
      select suite_id, suite_name, passed, failed, total, file_name
      from (
        select 3 s, suite_id,
        lpad(suite_name, 30) suite_name,
        to_char(passed, '999999') passed,
        to_char(failed, '999999') failed,
        to_char(total, '999999') total,
        lpad(file_name, 30) file_name
        from pljson_testsuite
      union
        select 1 s, 0 suite_id,
        lpad('SUITE_NAME', 30) suite_name,
        lpad('PASSED', 7) passed,
        lpad('FAILED', 7) failed,
        lpad('TOTAL', 7) total,
        lpad('FILE_NAME', 30) file_name
        from dual
      union
        select 5 s, 0,
        lpad('ALL TESTS', 30) suite_name,
        to_char(sum(passed), '999999') passed,
        to_char(sum(failed), '999999') failed,
        to_char(sum(total), '999999') total,
        lpad(' ', 30) file_name
        from pljson_testsuite
      union
        select 2 s, 0 suite_id,
        lpad('-', 30, '-') suite_name,
        lpad('-', 7, '-') passed,
        lpad('-', 7, '-') failed,
        lpad('-', 7, '-') total,
        lpad('-', 30, '-') file_name
        from dual
      union
        select 4 s, 0 suite_id,
        lpad('-', 30, '-') suite_name,
        lpad('-', 7, '-') passed,
        lpad('-', 7, '-') failed,
        lpad('-', 7, '-') total,
        lpad('-', 30, '-') file_name
        from dual
      order by s, suite_id
      )
    )
    loop
      dbms_output.put_line(
        rec.suite_name||' '||rec.passed||' '||rec.failed||' '||rec.total||' '||rec.file_name
      );
    end loop;
  end;
  
end pljson_ut;
/