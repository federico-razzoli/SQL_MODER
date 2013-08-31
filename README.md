SQL_MODER
=========

Convenient routines to work with SQL_MODE

License: GNU Affero General Public License, version 3
Copyright Federico Razzoli  2013

Overview
========

Working with SQL_MODE is unconfortable, because it is a (long?) comma-separated list.
With these routines, you can easily show, check, set or unset an individual flag.
Note that sql_mode_set() also accepts a comma-separated list of flags.

Usage
=====

```
void _.sql_mode_list()
Show a human-readable list of active SQL_MODE flags.

void _.sql_mode_show()
A better (but slower) version of sql_mode_list().

BOOL _.sql_mode_is_set(flag_name)
Return TRUE if flag_name is set, else return FALSE.

void _.sql_mode_set(flag_name)
Set the specified SQL_MODE flag. Errors are not handled.

void _.sql_mode_unset(flag_name)
Unset the specified SQL_MODE flag. If it wasn't set (or doesn't exist) an error is produced (SQLSTATE: '45000').
```
	
Example
=======

```sql
SET @flag = 'HIGH_NOT_PRECEDENCE';
CALL _.sql_mode_list();
CALL _.sql_mode_set(@flag);
SELECT _.sql_mode_is_set(@flag);
CALL _.sql_mode_unset(@flag);
SELECT _.sql_mode_is_set(@flag);
```

Tests
=====

The test_sql_mode.sql file contains a Test Case. To tun it, you need to install STK/Unit:
http://stk.wikidot.com/stk-unit

The command to run the Test Case and see human-readable results on the command line is:

```
CALL stk_unit.tc('test_sql_mode');
```

The results will appear in the command line.

To-Do
=====

Nothing: this is ok for me.
But if you want generalized versions of these routines, to work with
@@session.sql_mode or optimizer_switch or other vars, just let me know.

