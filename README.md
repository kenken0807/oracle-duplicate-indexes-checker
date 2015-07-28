# oracle-duplicate-indexes-checker
Find duplicate index keys on ORACLE. It will work Oracle 11gR1 or Later  
It will find indexes that cover the same columns as another index in the same order 
#install
<pre>
cpanm install DBD::Oracle
</pre>

#Options
<pre>
$ perl oracle-duplicate-indexes-checker.pl
[ERROR] Check Options
--db  SID[dafault none]
--user username[default none]
--password user's password[default none]
--host hostname or IP[default localhost]
--port listener port[default 1521]
--table tablename if you want to check only one table[dafault none]
</pre>

#exec(sample)
<pre>
perl oracle-duplicate-indexes-checker.pl --db ORCR --user orauser --password orauser

------------------------------------------------------------------------------------------
drop_recommend: DROP INDEX BBBB_AA
tablename: BBBB
duplicate_index: BBBB_AA                        columns: AA
          index: BBBB_PK                        columns: AA,BB

------------------------------------------------------------------------------------------
drop_recommend: DROP INDEX ID2_IND
tablename: INDTEST
duplicate_index: ID2_IND                        columns: ID2
          index: ID2_TEXT_IND                   columns: ID2,TEXT
          index: ID2_ID_IND                     columns: ID2,ID
          index: ID2_TEXT_ID_IND                columns: ID2,TEXT,ID

------------------------------------------------------------------------------------------
drop_recommend: DROP INDEX ID2_TEXT_IND
tablename: INDTEST
duplicate_index: ID2_TEXT_IND                   columns: ID2,TEXT
          index: ID2_TEXT_ID_IND                columns: ID2,TEXT,ID
</pre>
