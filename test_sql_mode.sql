/*
	SQL_MODER
	Copyright Federico Razzoli  2013
	
	This file is part of SQL_MODER.
	
	SQL_MODER is free software: you can redistribute it and/or modify
	it under the terms of the GNU Affero General Public License as published by
	the Free Software Foundation, version 3 of the License.
	
	SQL_MODER is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Affero General Public License for more details.
	
	You should have received a copy of the GNU Affero General Public License
	along with SQL_MODER.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
	To run this Test Case, you need to install STK/Unit:
	http://stk.wikidot.com/stk-unit
	The command to run the Test Case and see human-readable results on the command line is:
	CALL stk_unit.tc('test_sql_mode');
*/


DELIMITER ||


DROP DATABASE IF EXISTS `test_sql_mode`;
CREATE DATABASE `test_sql_mode`;


CREATE PROCEDURE `test_sql_mode`.`before_all_tests`()
BEGIN
	SET @backup_sql_mode = @@global.sql_mode;
	SELECT
		CONCAT(
				'\nNOTE: If this test is interrupted for some reason, please restore your SQL_MODE this way:\n',
				'SET @@global.sql_mode = ', QUOTE(@@global.sql_mode),
				'\n'
			)
		AS `Note`;
END;


CREATE PROCEDURE `test_sql_mode`.`after_all_tests`()
BEGIN
	CALL `_`.`install_default`();
	SET @@global.sql_mode = @backup_sql_mode;
END;


CREATE PROCEDURE `test_sql_mode`.`set_up`()
BEGIN
	SET @@global.sql_mode = 'STRICT_ALL_TABLES';
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_is_set`()
BEGIN
	CALL `stk_unit`.`assert_true`(`_`.`sql_mode_is_set`('STRICT_ALL_TABLES'), 'STRICT_ALL_TABLES is set');
	CALL `stk_unit`.`assert_false`(`_`.`sql_mode_is_set`('HIGH_NOT_PRECEDENCE'), 'HIGH_NOT_PRECEDENCE is NOT set');
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_set`()
BEGIN
	CALL `_`.`sql_mode_set`('HIGH_NOT_PRECEDENCE');
	CALL `stk_unit`.`assert_true`(`_`.`sql_mode_is_set`('HIGH_NOT_PRECEDENCE'), NULL);
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_unset`()
BEGIN
	TRUNCATE `_`.`sql_mode`;
	
	-- flag is set
	CALL `_`.`sql_mode_unset`('STRICT_ALL_TABLES');
	CALL `stk_unit`.`assert_false`(`_`.`sql_mode_is_set`('STRICT_ALL_TABLES'), NULL);
	
	-- test is not set
	CALL `stk_unit`.`expect_any_exception`();
	CALL `_`.`sql_mode_unset`('HIGH_NOT_PRECEDENCE');
	CALL `stk_unit`.`assert_false`(`_`.`sql_mode_is_set`('HIGH_NOT_PRECEDENCE'), NULL);
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_is_valid`()
BEGIN
	-- valid modes
	CALL `stk_unit`.`assert_true`(`_`.`sql_mode_is_valid`(''), NULL);
	CALL `stk_unit`.`assert_true`(`_`.`sql_mode_is_valid`('STRICT_TRANS_TABLES'), NULL);
	CALL `stk_unit`.`assert_true`(`_`.`sql_mode_is_valid`('STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER'), NULL);
	
	-- invalid modes
	CALL `stk_unit`.`assert_false`(`_`.`sql_mode_is_valid`(NULL), NULL);
	CALL `stk_unit`.`assert_false`(`_`.`sql_mode_is_valid`('qqqqqqq'), NULL);
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_get_not_exists`()
BEGIN
	TRUNCATE `_`.`sql_mode`;
	CALL `stk_unit`.`assert_null`(`_`.`sql_mode_get`('not_exists'), NULL);
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_save`()
BEGIN
	TRUNCATE `_`.`sql_mode`;
	
	SET @flags = '';
	CALL `_`.`sql_mode_save`('uno', @flags);
	CALL `stk_unit`.`assert_equal`(`_`.`sql_mode_get`('uno'), @flags, NULL);
	
	SET @flags = 'STRICT_TRANS_TABLES';
	CALL `_`.`sql_mode_save`('due', @flags);
	CALL `stk_unit`.`assert_equal`(`_`.`sql_mode_get`('due'), @flags, NULL);
	
	SET @flags = 'STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER';
	CALL `_`.`sql_mode_save`('tre', @flags);
	CALL `stk_unit`.`assert_equal`(`_`.`sql_mode_get`('tre'), @flags, NULL);
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_save_duplicate`()
BEGIN
	TRUNCATE `_`.`sql_mode`;
	
	CALL `_`.`sql_mode_save`('uno', '');
	CALL `stk_unit`.`expect_any_exception`();
	CALL `_`.`sql_mode_save`('uno', '');
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_unsave`()
BEGIN
	TRUNCATE `_`.`sql_mode`;
	
	CALL `_`.`sql_mode_save`('uno', '');
	CALL `_`.`sql_mode_unsave`('uno');
	CALL `stk_unit`.`assert_false`(`_`.`sql_mode_is_set`('uno'), NULL);
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_unsave_not_exists`()
BEGIN
	TRUNCATE `_`.`sql_mode`;
	
	CALL `stk_unit`.`expect_any_exception`();
	CALL `_`.`sql_mode_unsave`('not_exists');
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_force_save`()
BEGIN
	TRUNCATE `_`.`sql_mode`;
	
	-- just test that we get no exceptions
	CALL `_`.`sql_mode_force_save`('uno', '');
	CALL `_`.`sql_mode_force_save`('uno', '');
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_is_saved`()
BEGIN
	TRUNCATE `_`.`sql_mode`;
	
	CALL `stk_unit`.`assert_false`(`_`.`sql_mode_is_saved`('not_exists'), NULL);
	
	CALL `_`.`sql_mode_save`('uno', '');
	CALL `stk_unit`.`assert_true`(`_`.`sql_mode_is_saved`('uno'), NULL);
END;


CREATE PROCEDURE `test_sql_mode`.`test_default_sql_modes`()
BEGIN
	TRUNCATE `_`.`sql_mode`;
	CALL `_`.`install_default`();
	
	CALL `stk_unit`.`assert_true`(`_`.`sql_mode_is_saved`('EMPTY'), NULL);
	CALL `stk_unit`.`assert_true`(`_`.`sql_mode_is_saved`('MYSQL56'), NULL);
	CALL `stk_unit`.`assert_true`(`_`.`sql_mode_is_saved`('STRICT'), NULL);
END;


CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_save_current`()
BEGIN
	TRUNCATE `_`.`sql_mode`;
	CALL `_`.`sql_mode_save_current`('x');
	CALL `stk_unit`.`assert_equal`(`_`.`sql_mode_get`('x'), @@session.sql_mode, NULL);
END;


||
DELIMITER ;


COMMIT;


