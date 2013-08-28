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


CREATE DATABASE IF NOT EXISTS `test_sql_mode`;


DROP PROCEDURE IF EXISTS `test_sql_mode`.`before_all_tests`;
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


DROP PROCEDURE IF EXISTS `test_sql_mode`.`after_all_tests`;
CREATE PROCEDURE `test_sql_mode`.`after_all_tests`()
BEGIN
	SET @@global.sql_mode = @backup_sql_mode;
END;


DROP PROCEDURE IF EXISTS `test_sql_mode`.`set_up`;
CREATE PROCEDURE `test_sql_mode`.`set_up`()
BEGIN
	SET @@global.sql_mode = 'STRICT_ALL_TABLES';
END;


DROP PROCEDURE IF EXISTS `test_sql_mode`.`test_sql_mode_is_set`;
CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_is_set`()
BEGIN
	CALL `stk_unit`.`assert_true`(`_`.`sql_mode_is_set`('STRICT_ALL_TABLES'), 'STRICT_ALL_TABLES is set');
	CALL `stk_unit`.`assert_false`(`_`.`sql_mode_is_set`('HIGH_NOT_PRECEDENCE'), 'HIGH_NOT_PRECEDENCE is NOT set');
END;


DROP PROCEDURE IF EXISTS `test_sql_mode`.`test_sql_mode_set`;
CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_set`()
BEGIN
	CALL `_`.`sql_mode_set`('HIGH_NOT_PRECEDENCE');
	CALL `stk_unit`.`assert_true`(`_`.`sql_mode_is_set`('HIGH_NOT_PRECEDENCE'), NULL);
END;


DROP PROCEDURE IF EXISTS `test_sql_mode`.`test_sql_mode_unset`;
CREATE PROCEDURE `test_sql_mode`.`test_sql_mode_unset`()
BEGIN
	-- flag is set
	CALL `_`.`sql_mode_unset`('STRICT_ALL_TABLES');
	CALL `stk_unit`.`assert_false`(`_`.`sql_mode_is_set`('STRICT_ALL_TABLES'), NULL);
	
	-- test is not set
	CALL `stk_unit`.`expect_any_exception`();
	CALL `_`.`sql_mode_unset`('HIGH_NOT_PRECEDENCE');
	CALL `stk_unit`.`assert_false`(`_`.`sql_mode_is_set`('HIGH_NOT_PRECEDENCE'), NULL);
END;


||
DELIMITER ;


COMMIT;


