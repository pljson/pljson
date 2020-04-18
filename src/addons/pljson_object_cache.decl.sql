create or replace package pljson_object_cache as
  
  /* E.I.Sarmas (github.com/dsnz)   2020-04-18   object cache to speed up internal operations */
  
  /* !!! NOTE: this package is used internally by pljson and it's not part of the api !!! */
  
  /* index by string of "id.path" or "path" */
  type pljson_element_tab is table of pljson_element index by varchar2(250);
  
  last_id number := 0;
  pljson_element_cache pljson_element_tab;
  cache_reqs number := 0;
  cache_hits number := 0;
  cache_invalid_reqs number := 0;
  
  procedure reset;
  procedure flush;
  procedure print_stats;
  function next_id return number;
  function object_key(elem pljson_element, piece varchar2) return varchar2;
  function get(key varchar2) return pljson_element;
  procedure set(key varchar2, val pljson_element);
end;
/
show err