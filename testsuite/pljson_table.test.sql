/**
 * Test of PLSQL PLJSON_Table
 **/

set serveroutput on format wrapped

begin

  pljson_ut.testsuite('pljson_table test', 'pljson_table.test.sql');

  begin
  
    begin

      execute immediate 'drop table pljson_table_test';
      pljson_ut.assertTrue(true, 'DROP TABLE pljson_table_test');

    exception
      when others then
        if (sqlcode = -942) then
          pljson_ut.assertTrue(true, 'DROP TABLE pljson_table_test; ignored, table did not exist');
        else
          pljson_ut.assertTrue(false, 'Unexpected error dropping pljson_table_test');
          dbms_output.put_line(sqlerrm);
        end if;
    end;

    begin

      execute immediate 'create table pljson_table_test (num number not null, col clob)';
      pljson_ut.assertTrue(true, 'CREATE TABLE pljson_table_test');

    exception
      when others then
        pljson_ut.assertTrue(false, 'CREATE TABLE pljson_table_test');
    end;
    
    execute immediate q'#
    insert all
    into pljson_table_test values(1,
    '{"data":
      {
       "name": "name 1",
       "description": "Cloud computing can support a company''s speed and agility, ...",
       "type": "link",
       "created_time": "2015-05-12T16:26:12+0000",
       "shares": { "count": 1 },
       "extra": "x1",
       "maps" : [ true ]
      }
    }')
    into pljson_table_test values(2,
    '{"data":
      {
       "name": "name 2",
       "description": "Oracle''s suite of SaaS applications not only reduces costs but...",
       "type": "link",
       "created_time": "2015-05-29T19:23:27+0000",
       "shares": { "count": 5 },
       "extra": "x5",
       "maps" : [ true ]
      }
    }')
    into pljson_table_test values(3,
    '{"data":
      {
       "name": "name 3",
       "description": "blah blah...",
       "type": "text",
       "created_time": "2015-12-21T19:23:29+0000",
       "shares": { "count": 100 },
       "extra": null,
       "maps" : [ true, true, false ]
      }
    }')
    select * from dual#';
    
    pljson_ut.assertTrue(true, 'pljson_table_test example data');
    
    commit;

  exception
    when others then
      pljson_ut.assertTrue(false, 'pljson_table_test example data creation');
  end;

  -- cartesian
  pljson_ut.testcase('Test SELECT statements (cartesian)');
  declare
    l_n integer;
  begin

    begin
    
      l_n := -1;
      execute immediate '
        select  count(*)
        from    table(pljson_table.json_table(
                  ''{"data":
                    {
                     "name": "name 3",
                     "description": "blah blah...",
                     "type": "text",
                     "created_time": "2015-12-21T19:23:29+0000",
                     "shares": { "count": 100 },
                     "extra": null,
                     "maps" : [ true, true, false ]
                    }
                  }'',
                  pljson_varray(''data.name'', ''data.extra'', ''data.maps'', ''data.shares.count'', ''data.missing''),
                  pljson_varray(''name'', ''extra'', ''map'', ''count'', ''whatelse'')
                ))'
      into l_n;

    exception
      when others then
        null;
    end;
    pljson_ut.assertTrue(l_n = 3, 'select from literal');

    begin
    
      l_n := -1;
      execute immediate '
        select  count(*)
        from    pljson_table_test pljt,
                table(pljson_table.json_table(
                    pljt.col,
                    pljson_varray(''data.name'', ''data.extra'', ''data.maps'', ''data.shares.count'', ''data.missing''),
                    pljson_varray(''name'', ''extra'', ''map'', ''count'', ''whatelse'')
                ))'
      into l_n;

    exception
      when others then
        null;
    end;
    pljson_ut.assertTrue(l_n = 5, 'select from table');

    begin

      l_n := -1;
      execute immediate '
        select  count(*)
        from    pljson_table_test pljt,
                table(pljson_table.json_table(
                  ''{"data":
                    {
                     "name": "name 3",
                     "description": "blah blah...",
                     "type": "text",
                     "created_time": "2015-12-21T19:23:29+0000",
                     "shares": { "count": 100 },
                     "extra": null,
                     "maps" : [ true, true, false ]
                    }
                  }'',
                  pljson_varray(''data.name'', ''data.extra'', ''data.maps'', ''data.shares.count'', ''data.missing''),
                  pljson_varray(''name'', ''extra'', ''map'', ''count'', ''whatelse'')
                ))'
      into l_n;

    exception
      when others then
        null;
    end;
    pljson_ut.assertTrue(l_n = 9, 'select from table cartesian join with literal');
    
  end;

  -- nested
  pljson_ut.testcase('Test SELECT statements (nested)');
  declare
    l_n integer;
  begin

    begin

      l_n := -1;
      execute immediate '
        select  count(*)
        from    table(pljson_table.json_table(
                  ''[
                    { "id": 0, "displayname": "Back",  "qty": 5, "extras": [ { "xid": 1, "xtra": "extra_1" }, { "xid": 21, "xtra": "extra_21" } ] },
                    { "id": 2, "displayname": "Front", "qty": 2, "extras": [ { "xid": 9, "xtra": "extra_9" }, { "xid": 90, "xtra": "extra_90" } ] },
                    { "id": 3, "displayname": "Middle", "qty": 9, "extras": [ { "xid": 5, "xtra": "extra_5" }, { "xid": 20, "xtra": "extra_20" } ] }
                  ]'',
                  pljson_varray(''[*].id'', ''[*].displayname'', ''[*].qty'', ''[*].extras[*].xid'', ''[*].extras[*].xtra''),
                  pljson_varray(''id'', ''displayname'', ''qty'', ''xid'', ''xtra''),
                  table_mode => ''nested''
                ))'
      into l_n;

    exception
      when others then
        null;
    end;
    pljson_ut.assertTrue(l_n = 6, 'select from literal');

    begin

      l_n := -1;
      execute immediate '
        select  count(*)
        from    table(pljson_table.json_table(
                  ''{
                    "PONumber" : 1600,
                    "Reference" : "ABULL-20140421",
                    "Requestor" : "Alexis Bull",
                    "User" : "ABULL",
                    "CostCenter" : "A50",
                    "ShippingInstructions" : {"name" : "Alexis Bull",
                                              "Address" : {"street" : "200 Sporting Green",
                                                           "city" : "South San Francisco",
                                                           "state" : "CA",
                                                           "zipCode" : 99236,
                                                           "country" : "United States of America"},
                                              "Phone"   : [{"type" : "Office", "number" : "909-555-7307"},
                                                           {"type" : "Mobile", "number" : "415-555-1234"}]},
                    "Special Instructions" : null,
                    "AllowPartialShipment" : true,
                    "LineItems" : [{"ItemNumber" : 1,
                                    "Part" : {"Description" : "One Magic Christmas",
                                              "UnitPrice" : 19.95,
                                              "UPCCode" : 13131092899},
                                              "Quantity" : 9.0},
                                   {"ItemNumber" : 2,
                                    "Part" : {"Description" : "Lethal Weapon",
                                              "UnitPrice" : 19.95,
                                              "UPCCode" : 85391628927},
                                              "Quantity" : 5.0}]
                  }'',
                pljson_varray(''Requestor'', ''ShippingInstructions.Address.state'', ''ShippingInstructions.Phone[*].type'', ''ShippingInstructions.Phone[*].number''),
                pljson_varray(''requestor'', ''state'', ''phone_type'', ''phone_num''),
                table_mode => ''nested''
              ))'
      INTO l_n;

    exception
      when others then
        null;
    end;
    pljson_ut.assertTrue(l_n = 2, 'select from literal (2)');

    begin

      l_n := -1;
      execute immediate '
        select  count(*)
        from    table(pljson_table.json_table(
                  ''{
                    "PONumber" : 1600,
                    "Reference" : "ABULL-20140421",
                    "Requestor" : "Alexis Bull",
                    "User" : "ABULL",
                    "CostCenter" : "A50",
                    "ShippingInstructions" : {"name" : "Alexis Bull",
                                              "Address" : {"street" : "200 Sporting Green",
                                                           "city" : "South San Francisco",
                                                           "state" : "CA",
                                                           "zipCode" : 99236,
                                                           "country" : "United States of America"},
                                              "Phone"   : [{"type" : "Office", "number" : "909-555-7307"},
                                                           {"type" : "Mobile", "number" : "415-555-1234"}]},
                    "Special Instructions" : null,
                    "AllowPartialShipment" : true,
                    "LineItems" : [{"ItemNumber" : 1,
                                    "Part" : {"Description" : "One Magic Christmas",
                                              "UnitPrice" : 19.95,
                                              "UPCCode" : 13131092899},
                                              "Quantity" : 9.0},
                                   {"ItemNumber" : 2,
                                    "Part" : {"Description" : "Lethal Weapon",
                                              "UnitPrice" : 19.95,
                                              "UPCCode" : 85391628927},
                                              "Quantity" : 5.0}]
                  }'',
                pljson_varray(''LineItems[*].ItemNumber'', ''LineItems[*].Part.Description'', ''LineItems[*].Quantity''),
                pljson_varray(''item_number'', ''description'', ''quantity''),
                table_mode => ''nested''
              ))'
      into l_n;

    exception
      when others then
        null;
    end;
    pljson_ut.assertTrue(l_n = 2, 'select from literal (3)');
    
  end;

  pljson_ut.testsuite_report;

end;
/