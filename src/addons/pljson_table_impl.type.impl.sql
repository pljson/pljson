create or replace type body pljson_table_impl as

  /*
  Copyright (c) 2016 E.I.Sarmas (github.com/dsnz)

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

  /*
    E.I.Sarmas (github.com/dsnz)   2016-02-09   first version

    E.I.Sarmas (github.com/dsnz)   2017-07-21   minor update, better parameter names
    E.I.Sarmas (github.com/dsnz)   2017-09-23   major update, table_mode = cartesian/nested
    E.I.Sarmas (github.com/dsnz)   2020-04-18   caching to speedup nested mode
    E.I.Sarmas (github.com/dsnz)   2020-05-12   optimization for json structure of issue #197
  */

  /*
    *** NOTICE ***

    json_table() cannot work with all bind variables
    at least one of the 'column_paths' or 'column_names' parameters must be literal
    and for this reason it cannot work with cursor_sharing=force
    this is not a limitation of PLJSON but rather a result of how Oracle Data Cartridge works currently
  */

  static function ODCITableDescribe(
    rtype out anytype,
    json_str clob, column_paths pljson_varray, column_names pljson_varray := null,
    table_mode varchar2 := 'cartesian'
  ) return number is
    atyp anytype;
  begin
    --dbms_output.put_line('>>Describe');

    anytype.begincreate(dbms_types.typecode_object, atyp);
    if column_names is null then
      for i in column_paths.FIRST .. column_paths.LAST loop
        atyp.addattr('JSON_' || ltrim(to_char(i)), dbms_types.typecode_varchar2, null, null, 32767, null, null);
      end loop;
    else
      for i in column_names.FIRST .. column_names.LAST loop
        atyp.addattr(upper(column_names(i)), dbms_types.typecode_varchar2, null, null, 32767, null, null);
      end loop;
    end if;
    atyp.endcreate;

    anytype.begincreate(dbms_types.typecode_table, rtype);
    rtype.SetInfo(null, null, null, null, null, atyp, dbms_types.typecode_object, 0);
    rtype.endcreate();

    --dbms_output.put_line('>>Describe end');
    return odciconst.success;
  exception
    when others then
      return odciconst.error;
  end;

  static function ODCITablePrepare(
    sctx out pljson_table_impl,
    ti in sys.ODCITabFuncInfo,
    json_str clob, column_paths pljson_varray, column_names pljson_varray := null,
    table_mode varchar2 := 'cartesian'
  ) return number is
    elem_typ sys.anytype;
    prec  pls_integer;
    scale pls_integer;
    len   pls_integer;
    csid  pls_integer;
    csfrm pls_integer;
    tc    pls_integer;
    aname varchar2(30);
  begin
    --dbms_output.put_line('>>Prepare');

    tc := ti.RetType.GetAttrElemInfo(1, prec, scale, len, csid, csfrm, elem_typ, aname);
    sctx := pljson_table_impl(
      json_str, column_paths, column_names,
      table_mode,
      pljson_vtab(), pljson_narray(), pljson_narray(),
      pljson_varray(), pljson_varray(),  pljson_narray(), pljson_varray(),
      pljson_narray(), pljson_varray(), pljson_varray(),
      0,
      pljson(),
      pljson_varray(),
      elem_typ
    );
    return odciconst.success;
  end;

  -- E.I.Sarmas (github.com/dsnz)   2017-09-23   NEW support for nested/cartesian table generation
  static function ODCITableStart(
    sctx in out pljson_table_impl,
    json_str clob, column_paths pljson_varray, column_names pljson_varray := null,
    table_mode varchar2 := 'cartesian'
  ) return number is
    json_obj pljson;
    json_val pljson_element;
    buf varchar2(32767);
    --data_tab pljson_vtab := pljson_vtab();
    json_arr pljson_list;
    json_elem pljson_element;
    value_array pljson_varray := pljson_varray();

    -- E.I.Sarmas (github.com/dsnz)   2017-09-23   NEW support for array as root json data
    root_val pljson_element;
    root_list pljson_list;
    root_array_size number := 0;
    /* for nested mode */
    last_nested_path_full varchar2(32767);
    column_path varchar(32767);
    array_pos number;
    nested_path_prefix varchar2(32767);
    nested_path_ext varchar2(32767);
    column_path_part varchar2(32767);
    /* a starts with b */
    function starts_with(a in varchar2, b in varchar2) return boolean is
    begin
      if b is null then
        return True;
      end if;
      if substr(a, 1, length(b)) = b then
        return True;
      end if;
      return False;
    end;
  begin
    --dbms_output.put_line('>>Start');

    --dbms_output.put_line('json_str='||json_str);
    -- json_obj := pljson(json_str);
    root_val := pljson_parser.parse_any(json_str);
    --dbms_output.put_line('parsed: ' || root_val.get_type());
    if root_val.typeval = 2 then
      root_list := pljson_list(root_val);
      root_array_size := root_list.count;
      json_obj := pljson(root_list);
    else
      -- implicit root of size 1
      root_array_size := 1;
      json_obj := pljson(root_val);
    end if;
    --dbms_output.put_line('... array size = ' || root_array_size);

    /*
      E.I.Sarmas (github.com/dsnz)   2018-05-27   minor enhancement

      to be able to work with bind variables for some of the parameters
      but at least one of column_paths or column_names must be literal
      it's impossible (currently) to have all parameters in bind variables
    */
    sctx.str := json_str;
    sctx.column_paths := column_paths;
    sctx.column_names := column_names;
    sctx.table_mode := table_mode;

    sctx.json_obj := json_obj;
    sctx.root_array_size := root_array_size;
    sctx.data_tab.delete;

    if table_mode = 'cartesian' then
      for i in column_paths.FIRST .. column_paths.LAST loop
        --dbms_output.put_line('path='||column_paths(i));
        json_val := pljson_ext.get_json_element(json_obj, column_paths(i));
        --dbms_output.put_line('type='||json_val.get_type());
        case json_val.typeval
          --when 1 then 'object';
          when 2 then -- 'array';
            json_arr := pljson_list(json_val);
            value_array.delete;
            for j in 1 .. json_arr.count loop
              json_elem := json_arr.get(j);
              case json_elem.typeval
                --when 1 then 'object';
                --when 2 then -- 'array';
                when 3 then -- 'string';
                  buf := json_elem.get_string();
                  --dbms_output.put_line('res[](string)='||buf);
                  value_array.extend(); value_array(value_array.LAST) := buf;
                when 4 then -- 'number';
                  buf := to_char(json_elem.get_number());
                  --dbms_output.put_line('res[](number)='||buf);
                  value_array.extend(); value_array(value_array.LAST) := buf;
                when 5 then -- 'bool';
                  buf := case json_elem.get_bool() when true then 'true' when false then 'false' end;
                  --dbms_output.put_line('res[](bool)='||buf);
                  value_array.extend(); value_array(value_array.LAST) := buf;
                when 6 then -- 'null';
                  buf := null;
                  --dbms_output.put_line('res[](null)='||buf);
                  value_array.extend(); value_array(value_array.LAST) := buf;
                else
                  -- if object is unknown or does not exist add new element of type null
                  buf := null;
                  --dbms_output.put_line('res[](unknown)='||buf);
                  sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
              end case;
            end loop;
            sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := value_array;
          when 3 then -- 'string';
            buf := json_val.get_string();
            --dbms_output.put_line('res(string)='||buf);
            sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
          when 4 then -- 'number';
            buf := to_char(json_val.get_number());
            --dbms_output.put_line('res(number)='||buf);
            sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
          when 5 then -- 'bool';
            buf := case json_val.get_bool() when true then 'true' when false then 'false' end;
            --dbms_output.put_line('res(bool)='||buf);
            sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
          when 6 then -- 'null';
            buf := null;
            --dbms_output.put_line('res(null)='||buf);
            sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
          else
            -- if object is unknown or does not exist add new element of type null
            buf := null;
            --dbms_output.put_line('res(unknown)='||buf);
            sctx.data_tab.extend(); sctx.data_tab(sctx.data_tab.LAST) := pljson_varray(buf);
        end case;
      end loop;

      --dbms_output.put_line('initialize row indexes');
      sctx.row_ind.delete;
      --for i in data_tab.FIRST .. data_tab.LAST loop
      for i in column_paths.FIRST .. column_paths.LAST loop
        sctx.row_ind.extend();
        sctx.row_ind(sctx.row_ind.LAST) := 1;
      end loop;
    else
      /* setup nested mode */
      sctx.nested_path_full.delete;
      sctx.nested_path_ext.delete;
      sctx.column_path_part.delete;
      sctx.column_nested_index.delete;
      for i in column_paths.FIRST .. column_paths.LAST loop
        --dbms_output.put_line(i || ', column_path = ' || column_paths(i));
        column_path := column_paths(i);
        array_pos := instr(column_path, '[*]', -1);
        if array_pos > 0 then
          nested_path_prefix := substr(column_path, 1, array_pos+2);
        else
          nested_path_prefix := '';
        end if;
        --dbms_output.put_line(i || ', nested_path_prefix = ' || nested_path_prefix);
        last_nested_path_full := '';
        if sctx.nested_path_full.LAST is not null then
          last_nested_path_full := sctx.nested_path_full(sctx.nested_path_full.LAST);
        end if;
        --dbms_output.put_line(i || ', last_nested_path_full = ' || last_nested_path_full);
        if not starts_with(nested_path_prefix, last_nested_path_full) then
          --dbms_output.put_line('column paths are not nested, column# ' || i);
          raise_application_error(-20120, 'column paths are not nested, column# ' || i);
        end if;
        if i = 1 or nested_path_prefix != last_nested_path_full
        or (nested_path_prefix is not null and last_nested_path_full is null) then
          nested_path_ext := substr(nested_path_prefix, nvl(length(last_nested_path_full), 0)+1);
          if instr(nested_path_ext, '[*]') != instr(nested_path_ext, '[*]', -1) then
            --dbms_output.put_line('column introduces more than one array, column# ' || i);
            raise_application_error(-20120, 'column introduces more than one array, column# ' || i);
          end if;
          sctx.nested_path_full.extend();
          sctx.nested_path_full(sctx.nested_path_full.LAST) := nested_path_prefix;
          --dbms_output.put_line(i || ', new nested_path_full = ' || nested_path_prefix);
          sctx.nested_path_ext.extend();
          sctx.nested_path_ext(sctx.nested_path_ext.LAST) := nested_path_ext;
          --dbms_output.put_line(i || ', new nested_path_ext = ' || nested_path_ext);
          sctx.start_column.extend();
          sctx.start_column(sctx.start_column.LAST) := i;
        end if;
        sctx.column_nested_index.extend();
        sctx.column_nested_index(sctx.column_nested_index.LAST) := sctx.nested_path_full.LAST;
        --dbms_output.put_line(i || ', column_nested_index = ' || sctx.nested_path_full.LAST);
        column_path_part := substr(column_path, nvl(length(nested_path_prefix), 0)+1);
        sctx.column_path_part.extend();
        sctx.column_path_part(sctx.column_path_part.LAST) := column_path_part;
        --dbms_output.put_line(i || ', column_path_part = ' || column_path_part);
      end loop;
      --dbms_output.put_line('initialize row indexes');
      sctx.row_ind.delete;
      sctx.row_count.delete;
      sctx.nested_path_literal.delete;
      if sctx.nested_path_full.LAST is not null then
        for i in 1 .. sctx.nested_path_full.LAST loop
          sctx.row_ind.extend();
          sctx.row_ind(sctx.row_ind.LAST) := -1;
          sctx.row_count.extend();
          sctx.row_count(sctx.row_count.LAST) := -1;
          sctx.nested_path_literal.extend();
          sctx.nested_path_literal(sctx.nested_path_literal.LAST) := '';
        end loop;
      end if;
      sctx.column_val.delete;
      /* E.I.Sarmas (github.com/dsnz)   2020-05-12   optimization for json structure of issue #197 */
      sctx.cached_names.delete;
      declare
        bra_index number;
        dot_index number;
        a_path varchar2(32767);
        a_name varchar2(32767);
      begin
        for i in 1 .. sctx.column_paths.LAST loop
          sctx.column_val.extend();
          sctx.column_val(sctx.column_val.LAST) := '';
          a_path := sctx.column_paths(i);
          bra_index := instr(a_path, '[', -1);
          dot_index := instr(a_path, '.', -1);
          /* yyy.xxx */
          if dot_index > bra_index then
            a_name := substr(a_path, dot_index+1);
            if not a_name member of sctx.cached_names then
              sctx.cached_names.extend();
              sctx.cached_names(sctx.cached_names.LAST) := a_name;
              --dbms_output.put_line('add cached name: ' || a_name);
            end if;
          end if;
        end loop;
      end;
      pljson_object_cache.set_names_set(sctx.cached_names);
      pljson_object_cache.reset;
    end if;

    return odciconst.success;
  end;

  member function ODCITableFetch(
    self in out pljson_table_impl, nrows in number, outset out anydataset
  ) return number is
    --data_row pljson_varray := pljson_varray();
    --type index_array is table of number;
    --row_ind index_array := index_array();
    j number;
    num_rows number := 0;

    --json_obj pljson;
    json_val pljson_element;
    buf varchar2(32767);
    --data_tab pljson_vtab := pljson_vtab();
    json_arr pljson_list;
    json_elem pljson_element;
    value_array pljson_varray := pljson_varray();

    /* E.I.Sarmas (github.com/dsnz)   2020-05-12   optimization for json structure of issue #197 */
    /* extra caching as get on associative table is slow because of large object copying */
    last_prefix_array varchar2(250);
    last_prefix_array_val pljson_element;

    /* nested mode */
    temp_path varchar(32767);
    start_index number;
    k number;
    /*
      k is nested path index and not column index
      sets row_count()
    */
    procedure set_count(k number) is
      temp_path varchar(32767);
    begin
      if k = 1 then
        if nested_path_full(1) is null or nested_path_full(1) = '[*]' then
          row_count(1) := root_array_size;
          return;
        else
          temp_path := substr(nested_path_full(1), 1, length(nested_path_full(1)) - 3);
        end if;
      else
        temp_path := nested_path_literal(k - 1) || substr(nested_path_ext(k), 1, length(nested_path_ext(k)) - 3);
      end if;
      --dbms_output.put_line(k || ', set_count temp_path = ' || temp_path);
      json_val := pljson_ext.get_json_element(json_obj, temp_path);
      if json_val.typeval != 2 then
        raise_application_error(-20120, 'column introduces array with [*] but is not array in json, column# ' || k);
      end if;
      row_count(k) := pljson_list(json_val).count;
    end;
    /*
      k is nested path index and not column index
      sets nested_path_literal() for row_ind(k)
    */
    procedure set_nested_path_literal(k number) is
      temp_path varchar(32767);
    begin
      if k = 1 then
        if nested_path_full(1) is null then
          return;
        end if;
        temp_path := substr(nested_path_full(1), 1, length(nested_path_full(1)) - 2);
      else
        temp_path := nested_path_literal(k - 1) || substr(nested_path_ext(k), 1, length(nested_path_ext(k)) - 2);
      end if;
      nested_path_literal(k) := temp_path || row_ind(k) || ']';
    end;

    /* assumes it is always called with same root object = 'json_obj' */
    function get_json_element_with_cache(json_obj pljson, temp_path varchar2) return pljson_element is
      bra_index number;
      dot_index number;
      prefix varchar2(250);
      piece varchar2(250);
      piece_index number;
      prefix_val pljson_element;
      piece_val pljson_element;
      prefix_array varchar2(250);
      prefix_index number;
      prefix_lbra_index number;
      cache_key varchar2(32767);
      cached_piece varchar2(250);
      cached_piece_val pljson_element;
      cached_piece_path varchar2(250);
      cached_piece_count number;
      scan_count number;
    begin
      prefix := null;
      piece := null;
      bra_index := instr(temp_path, '[', -1);
      dot_index := instr(temp_path, '.', -1);
      /* yyy.xxx */
      if dot_index > bra_index then
        /* E.I.Sarmas (github.com/dsnz)   2020-05-12   optimization for json structure of issue #197 */
        /* check first for cached entry */
        /*
        piece_val := pljson_object_cache.get(temp_path);
        if piece_val is not null then
          --dbms_output.put_line('got cached: ' || temp_path);
          return piece_val;
        end if;
        */
        /* inline expansion (begin) */
        pljson_object_cache.cache_reqs := pljson_object_cache.cache_reqs + 1;
        if pljson_object_cache.pljson_element_cache.exists(temp_path) then
          pljson_object_cache.cache_hits := pljson_object_cache.cache_hits + 1;
          return pljson_object_cache.pljson_element_cache(temp_path);
        end if;
        /* inline expansion (end) */

        /* normal processing */
        prefix := substr(temp_path, 1, dot_index-1);
        piece := substr(temp_path, dot_index+1);
        /* E.I.Sarmas (github.com/dsnz)   2020-05-12   optimization for json structure of issue #197 */
        /* special case of array, must not rescan for every index but cache array */
        /* also cache last array in local variable */
        if substr(prefix, length(prefix)) = ']' then
          prefix_lbra_index := instr(prefix, '[', -1);
          prefix_index := to_number(substr(prefix, prefix_lbra_index + 1, length(prefix) - prefix_lbra_index - 1));
          prefix_array := substr(prefix, 1, prefix_lbra_index - 1);
          if prefix_array = last_prefix_array then
            null;
          else
            last_prefix_array := prefix_array;
            last_prefix_array_val := null;
            --prefix_val := pljson_object_cache.get(prefix);
            /* inline expansion (begin) */
            cache_key := last_prefix_array;
            if cache_key is null then
              cache_key := '$';
            end if;
            pljson_object_cache.cache_reqs := pljson_object_cache.cache_reqs + 1;
            if pljson_object_cache.pljson_element_cache.exists(cache_key) then
              pljson_object_cache.cache_hits := pljson_object_cache.cache_hits + 1;
              last_prefix_array_val := pljson_object_cache.pljson_element_cache(cache_key);
            end if;
            if last_prefix_array_val is null then
              --dbms_output.put_line(temp_path ||' dot(smart)=> '|| prefix_array ||','|| to_char(prefix_index) ||' + '|| piece);
              last_prefix_array_val := pljson_ext.get_json_element(json_obj, last_prefix_array);
              --pljson_object_cache.set(prefix_array, prefix_val);
              pljson_object_cache.pljson_element_cache(cache_key) := last_prefix_array_val;
            end if;
            /* inline expansion (end) */
          end if;
          --dbms_output.put_line(temp_path ||' dot(smart)=> '|| prefix ||' ('|| prefix_val.typeval ||'),'||
          --                      to_char(prefix_index) ||' + '|| piece);
          --piece_val := prefix_val.path(piece); --pljson_ext.get_json_element(treat(prefix_val as pljson), piece);
          prefix_val := last_prefix_array_val.get(prefix_index);
        else
          --prefix_val := pljson_object_cache.get(prefix);
          /* inline expansion (begin) */
          pljson_object_cache.cache_reqs := pljson_object_cache.cache_reqs + 1;
          prefix_val := null;
          if pljson_object_cache.pljson_element_cache.exists(prefix) then
             pljson_object_cache.cache_hits := pljson_object_cache.cache_hits + 1;
            prefix_val := pljson_object_cache.pljson_element_cache(prefix);
          end if;
          if prefix_val is null then
            --dbms_output.put_line(temp_path ||' dot=> '|| prefix ||' + '|| piece);
            prefix_val := pljson_ext.get_json_element(json_obj, prefix);
            --pljson_object_cache.set(prefix, prefix_val);
            pljson_object_cache.pljson_element_cache(prefix) := prefix_val;
          end if;
          /* inline expansion (end) */
          --dbms_output.put_line(temp_path ||' dot=> '|| prefix ||' ('|| prefix_val.typeval ||') + '|| piece);
        end if;

        /* E.I.Sarmas (github.com/dsnz)   2020-05-12   optimization for json structure of issue #197 */
        /* cache pieces for all cached_names, except current name */
        cached_piece_count := 1;
        scan_count := 0;
        for i in 1 .. prefix_val.count loop
          scan_count := scan_count + 1;
          piece_val := prefix_val.get(i);
          cached_piece := piece_val.mapname;
          if pljson_object_cache.in_names_set(cached_piece) and cached_piece != piece then
            cached_piece_count := cached_piece_count + 1;
            cached_piece_path := prefix || '.' || cached_piece;
            --dbms_output.put_line('cache piece: ' || cached_piece_path);
            cached_piece_val := prefix_val.get(cached_piece);
            --pljson_object_cache.set(cached_piece_path, cached_piece_val);
            /* inline expansion (begin) */
            pljson_object_cache.pljson_element_cache(cached_piece_path) := cached_piece_val;
            /* inline expansion (end) */
          end if;
          exit when cached_piece_count = cached_names.count;
        end loop;
        --dbms_output.put_line('scanned elements#: ' || to_char(scan_count));

        --piece_val := prefix_val.path(piece); --pljson_ext.get_json_element(treat(prefix_val as pljson), piece);
        piece_val := prefix_val.get(piece);
        return piece_val;
      /* yyy.xxx[...] */
      /* E.I.Sarmas (github.com/dsnz)   2020-05-12   optimization for json structure of issue #197 */
      /* special case of array, must not rescan for every index but cache array */
      /* also cache last array in local variable */
      elsif dot_index < bra_index then
        prefix_array := substr(temp_path, 1, bra_index-1);
        piece := substr(temp_path, bra_index);
        piece_index := to_number(substr(piece, 2, length(piece)-2));
        if prefix_array = last_prefix_array then
          null;
        else
          last_prefix_array := prefix_array;
          last_prefix_array_val := null;
          --prefix_val := pljson_object_cache.get(prefix);
          /* inline expansion (begin) */
          cache_key := last_prefix_array;
          if cache_key is null then
            cache_key := '$';
          end if;
          pljson_object_cache.cache_reqs := pljson_object_cache.cache_reqs + 1;
          if pljson_object_cache.pljson_element_cache.exists(cache_key) then
            pljson_object_cache.cache_hits := pljson_object_cache.cache_hits + 1;
            last_prefix_array_val := pljson_object_cache.pljson_element_cache(cache_key);
          end if;
          if last_prefix_array_val is null then
            --dbms_output.put_line(temp_path ||' bra=> '|| prefix_array ||' + '|| piece);
            last_prefix_array_val := pljson_ext.get_json_element(json_obj, last_prefix_array);
            --pljson_object_cache.set(prefix, prefix_val);
            pljson_object_cache.pljson_element_cache(cache_key) := last_prefix_array_val;
          end if;
          /* inline expansion (end) */
        end if;
        --dbms_output.put_line(temp_path ||' bra=> '|| prefix ||' ('|| prefix_val.typeval ||') + '|| piece);
        --piece_val := prefix_val.path(piece); --pljson_ext.get_json_element(treat(prefix_val as ...), piece);

        piece_val := last_prefix_array_val.get(piece_index);
        return piece_val;
      /* xxx, both must be zero */
      else
        --dbms_output.put_line(temp_path ||' => ...');
        piece_val := pljson_ext.get_json_element(json_obj, temp_path);
        return piece_val;
      end if;
    end;

  begin
    --dbms_output.put_line('>>Fetch, nrows = ' || nrows);

    if table_mode = 'cartesian' then
      outset := null;

      if row_ind(1) = 0 then
        --dbms_output.put_line('>>Fetch End');
        return odciconst.success;
      end if;

      anydataset.begincreate(dbms_types.typecode_object, self.ret_type, outset);

      /* iterative cartesian product algorithm */
      <<main_loop>>
      while True loop
        exit when num_rows = nrows or row_ind(1) = 0;
        --data_row.delete;
        outset.addinstance;
        outset.piecewise();
        --dbms_output.put_line('put one row piece');
        for i in data_tab.FIRST .. data_tab.LAST loop
          --data_row.extend();
          --data_row(data_row.LAST) := data_tab(i)(row_ind(i));
          --dbms_output.put_line('json_'||ltrim(to_char(i)));
          --dbms_output.put_line('['||ltrim(to_char(row_ind(i)))||']');
          --dbms_output.put_line('='||data_tab(i)(row_ind(i)));
          outset.setvarchar2(data_tab(i)(row_ind(i)));
        end loop;
        --pipe row(data_row);
        num_rows := num_rows + 1;

        --dbms_output.put_line('adjust row indexes');
        j := row_ind.COUNT;
        <<index_loop>>
        while True loop
          row_ind(j) := row_ind(j) + 1;
          if row_ind(j) <= data_tab(j).COUNT then
            exit index_loop;
          end if;
          row_ind(j) := 1;
          j := j - 1;
          if j < 1 then
            row_ind(1) := 0; -- hack to indicate end of all fetches
            exit main_loop;
          end if;
        end loop index_loop;
      end loop main_loop;

      outset.endcreate;
      --dbms_output.put_line('>>Fetch Complete, rows = ' || num_rows || ', row_ind(1) = ' || row_ind(1));
    else
      /* fetch nested mode */
      outset := null;

      anydataset.begincreate(dbms_types.typecode_object, self.ret_type, outset);

      <<main_loop_nested>>
      while True loop
        /* find starting column */
        /*
          in first run, loop will not assign value to start_index, so start_index := 0
          in last run after all rows produced, the same will happen and start_index := 0
          but the last run will have row_count(1) >= 0
        */
        start_index := 0;
        for i in REVERSE row_ind.FIRST .. row_ind.LAST loop
          if row_ind(i) < row_count(i) then
            start_index := start_column(i);
            exit;
          end if;
        end loop;
        if start_index = 0 then
          if num_rows = nrows or row_count(1) >= 0 then
            --dbms_output.put_line('>>Fetch End');
            exit main_loop_nested;
          else
            start_index := 1;
          end if;
        end if;

        /* fetch rows */
        --dbms_output.put_line('fetch new row, start from column# '|| start_index);
        <<row_loop_nested>>
        for i in start_index .. column_paths.LAST loop
          k := column_nested_index(i);
          /* new nested path */
          if start_column(k) = i then
            --dbms_output.put_line(i || ', new nested path');
            /* new count */
            if row_ind(k) = row_count(k) then
              set_count(k);
              row_ind(k) := 0;
              --dbms_output.put_line(i || ', new nested count = ' || row_count(k));
            end if;
            /* advance row_ind */
            row_ind(k) := row_ind(k) + 1;
            set_nested_path_literal(k);
          end if;
          temp_path := nested_path_literal(k) || column_path_part(i);
          --dbms_output.put_line(i || ' lit: ' || nested_path_literal(k) || ' part: ' || column_path_part(i));
          --dbms_output.put_line(i || ', path = ' || temp_path);
          ---json_val := pljson_ext.get_json_element(json_obj, temp_path);
          json_val := get_json_element_with_cache(json_obj, temp_path);
          --dbms_output.put_line('type='||json_val.get_type());
          case json_val.typeval
            --when 1 then 'object';
            --when 2 then -- 'array';
            when 3 then -- 'string';
              buf := json_val.get_string();
              --dbms_output.put_line('res(string)='||buf);
              column_val(i) := buf;
            when 4 then -- 'number';
              buf := to_char(json_val.get_number());
              --dbms_output.put_line('res(number)='||buf);
              column_val(i) := buf;
            when 5 then -- 'bool';
              buf := case json_val.get_bool() when true then 'true' when false then 'false' end;
              --dbms_output.put_line('res(bool)='||buf);
              column_val(i) := buf;
            when 6 then -- 'null';
              buf := null;
              --dbms_output.put_line('res(null)='||buf);
              column_val(i) := buf;
            else
              -- if object is unknown or does not exist add new element of type null
              buf := null;
              --dbms_output.put_line('res(unknown)='||buf);
              column_val(i) := buf;
          end case;
          if i = column_paths.LAST then
            outset.addinstance;
            outset.piecewise();
            for j in column_val.FIRST .. column_val.LAST loop
              outset.setvarchar2(column_val(j));
            end loop;
            num_rows := num_rows + 1;
          end if;
        end loop row_loop_nested;
      end loop main_loop_nested;

      outset.endcreate;
      --dbms_output.put_line('>>Fetch Complete, rows = ' || num_rows);
    end if;

    return odciconst.success;
  end;

  member function ODCITableClose(self in pljson_table_impl) return number is
  begin
    --dbms_output.put_line('>>Close');
    ----------pljson_object_cache.reset;
    return odciconst.success;
  end;
end;
/
show err