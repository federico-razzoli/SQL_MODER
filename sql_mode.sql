/*
	SQL_MODER
	Copyright Federico Razzoli  2013
	Contacts: santec [At) riseup d0t net
	
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
	Working with SQL_MODE is unconfortable, because it is a (long?) comma-separated list.
	With these routines, you can easily show, check, set or unset an individual flag.
	Note that sql_mode_set() also accepts a comma-separated list of flags.
	
	Usage:
		void _.sql_mode_list()
			Show a human-readable list of active SQL_MODE flags.
		void _.sql_mode_show()
			A better (but slower) version of sql_mode_list().
		BOOL _.sql_mode_is_set(flag_name)
			Return TRUE if flag_name is set, else return FALSE.
		void _.sql_mode_set(flag_name)
			Set the specified SQL_MODE flag. Errors are not handled.
		void _.sql_mode_unset(flag_name)
			Unset the specified SQL_MODE flag. If it wasn't set (or doesn't exist) an error
			is produced (SQLSTATE: '45000').
	
	Example:
		SET @flag = 'HIGH_NOT_PRECEDENCE';
		CALL _.sql_mode_list();
		CALL _.sql_mode_show();
		CALL _.sql_mode_set(@flag);
		SELECT _.sql_mode_is_set(@flag);
		CALL _.sql_mode_unset(@flag);
		SELECT _.sql_mode_is_set(@flag);
	
	To-Do:
		Nothing: this is ok for me.
		But if you want generalized versions of these routines, to work with
		@@session.sql_mode or optimizer_switch or other vars, just let me know.
*/


DELIMITER ||


-- utility database
CREATE DATABASE IF NOT EXISTS `_`
	DEFAULT CHARACTER SET = 'utf8'
	DEFAULT COLLATE = 'utf8_general_ci';


DROP PROCEDURE IF EXISTS `_`.`sql_mode_list`;
CREATE PROCEDURE `_`.`sql_mode_list`()
	CONTAINS SQL
	COMMENT 'Show a readable list of SQL_MODE flags'
BEGIN
	SELECT CONCAT('\n', REPLACE(@@global.sql_mode, ',', '\n'), '\n') AS `SQL_MODE Flags`;
END;


DROP PROCEDURE IF EXISTS `_`.`sql_mode_show`;
CREATE PROCEDURE `_`.`sql_mode_show`()
	CONTAINS SQL
	COMMENT 'Show SQL_MODE flags as a resultset'
BEGIN
	-- SQL to create flag list table
	DROP TEMPORARY TABLE IF EXISTS `_`.`SQL_MODE_FLAGS`;
	CREATE TEMPORARY TABLE `_`.`SQL_MODE_FLAGS` (`FLAG` VARCHAR(30) NOT NULL) ENGINE = MEMORY;
	SET @__stk__temp = CONCAT(
			'INSERT INTO `_`.`sql_mode_flags` (`FLAG`) VALUES (''',
			REPLACE(@@global.sql_mode, ',', '''), ('''),
			''');'
		);
	
	-- exec SQL & free memory
	PREPARE __stk__stmt FROM @__stk__temp;
	EXECUTE __stk__stmt;
	DEALLOCATE PREPARE __stk__stmt;
	SET @__stk__temp = NULL;
	
	-- show flags
	SELECT `FLAG` FROM `SQL_MODE_FLAGS` ORDER BY `FLAG`;
	
	DROP TEMPORARY TABLE IF EXISTS `_`.`sql_mode_flags`;
END;


DROP FUNCTION IF EXISTS `_`.`sql_mode_is_set`;
CREATE FUNCTION `_`.`sql_mode_is_set`(`flag_name` TEXT)
	RETURNS BOOL
	CONTAINS SQL
	COMMENT 'Return TRUE if specified SQL_MODE flag is set'
BEGIN
	RETURN @@global.sql_mode LIKE CONCAT('%', `flag_name`, '%');
END;


DROP PROCEDURE IF EXISTS `_`.`sql_mode_set`;
CREATE PROCEDURE `_`.`sql_mode_set`(IN `flag_name` TEXT)
	CONTAINS SQL
	COMMENT 'Set SQL_MODE flag'
BEGIN
	SET @@global.sql_mode = CONCAT(@@global.sql_mode, ',', `flag_name`);
END;


DROP PROCEDURE IF EXISTS `_`.`sql_mode_unset`;
CREATE PROCEDURE `_`.`sql_mode_unset`(IN `flag_name` TEXT)
	CONTAINS SQL
	COMMENT 'Unset SQL_MODE flag'
BEGIN
	SET @__stk__temp = @@global.sql_mode;
	SET @@global.sql_mode = REPLACE(UPPER(@@global.sql_mode), UPPER(`flag_name`), '');
	IF @__stk__temp = @@global.sql_mode THEN
		SET @__stk__temp = NULL;
		SET @message_text = CONCAT('Flag \'', `flag_name`, '\' was not set');
		/*!50500
			SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = @message_text;
		*/
		SELECT @message_text AS `error`;
	ELSE
		SET @__stk__temp = NULL;
	END IF;
END;


||
DELIMITER ;


COMMIT;

