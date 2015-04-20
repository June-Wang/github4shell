set linesize 200 
set term off verify off feedback off pagesize 999 
set markup html on entmap ON spool on preformat off

set trimout on   --去除标准输出每行的拖尾空格，缺省为off
set trimspool on  --去除重定向输出每行的拖尾空格，缺省为off
spool $output_file

sed -i 's/table,tr,td {/&mso-number-format:"0";text-align:left;mso-number-format:"\@";/' ${output_file}
