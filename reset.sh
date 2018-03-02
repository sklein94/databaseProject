
  get_table_order() {
    for script in tables/*.sql ; do
      tbl_name=$(echo ${script%\.sql} |sed s/"tables\/"// |tr [A-Z] [a-z])
      echo "$tbl_name $tbl_name"
      for ref_name in $(grep -i references $script |tr [A-Z] [a-z] | sed s/"^.*references[ ]*\([a-z0-9_]*\).*$"/"\1"/) ; do
        echo "$ref_name $tbl_name"
      done;
    done |tsort |sed s/"\(.*\)"/"tables\/\1.sql"/
  }

  rm tmp_last_log.txt
  rm tmp_last_sql.sql
  {

  cat types/*.sql

  cat functions/*.sql

  cat procedures/*.sql

  for tbl_script in $(get_table_order) ; do
    cat $tbl_script;
  done

  cat views/*.sql

  for pkg in packages/*/; do
	echo "create or replace package " $(basename "${pkg}")
	echo "authid current_user"
	echo "as"
	for scr in $pkg*.sql ; do
		cat $scr;
	done
	echo "end" $(basename "${pkg}") ";"
	echo "/"
  done

  for pkgb in package_bodies/*/; do
	echo "create or replace package body " $(basename "${pkgb}")
	echo "as"
	for scrb in $pkgb*.sql ; do
		cat $scrb;
	done
	echo "end" $(basename "${pkgb}") ";"
	echo "/"
  done

  cat jobs/*.sql

  cat admin/example_data.sql

  } > tmp_last_sql.sql

  {
  cat tmp_last_sql.sql
  } |sqlplus usr/pw@server > tmp_last_log.txt
