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
*/


DELIMITER ||


-- utility database
CREATE DATABASE IF NOT EXISTS `_`
	DEFAULT CHARACTER SET = 'utf8'
	DEFAULT COLLATE = 'utf8_general_ci';


/*
 *	Routines to modify SQL_MODE
 */


DROP PROCEDURE IF EXISTS `_`.`sql_mode_list`;
CREATE PROCEDURE `_`.`sql_mode_list`()
	CONTAINS SQL
	COMMENT 'Show a readable list of SQL_MODE flags'
BEGIN
	SELECT CONCAT('\n', REPLACE(@@global.sql_mode, ',', '\n'), '\n') AS `SQL_MODE_FLAGS`;
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
			'INSERT INTO `_`.`SQL_MODE_FLAGS` (`FLAG`) VALUES (''',
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
			SIGNAL SQLSTATE '45000' SET
				CLASS_ORIGIN = 'SQL_MODER',
				MESSAGE_TEXT = @message_text;
		*/
		SELECT @message_text AS `error`;
	ELSE
		SET @__stk__temp = NULL;
	END IF;
END;


DROP FUNCTION IF EXISTS `_`.`sql_mode_is_valid`;
CREATE FUNCTION `_`.`sql_mode_is_valid`(`sql_mode_string` TEXT)
	RETURNS BOOLEAN
	DETERMINISTIC
	CONTAINS SQL
	COMMENT 'Return wether SQL_MODE is valid'
BEGIN
	-- handle invalid SQL_MODE
	DECLARE EXIT HANDLER
		FOR 1231
	BEGIN
		RETURN FALSE;
	END;
	
	-- dont worry: as soon as this function ends,
	-- old SQL_MODE is restored
	SET @@session.sql_mode = `sql_mode_string`;
	RETURN TRUE;
END;


/*
 *	Routines to save/load SQL_MODE
 */


CREATE TABLE IF NOT EXISTS `_`.`sql_mode`
(
	`id`    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'PK',
	`name`  VARCHAR(130) NOT NULL UNIQUE COMMENT 'Unique identifier',
	`mode`  TEXT NOT NULL COMMENT 'SQL_MODE string'
)
	ENGINE = InnoDB,
	COMMENT = 'Saved SQL_MODEs';


DROP PROCEDURE IF EXISTS `_`.`install_default`;
CREATE PROCEDURE `_`.`install_default`()
	MODIFIES SQL DATA
	COMMENT 'Re-insert default SQL_MODEs'
BEGIN
	REPLACE INTO `_`.`sql_mode`
			(`name`, `mode`)
		VALUES
			('EMPTY', ''),
			('MYSQL56', 'NO_ENGINE_SUBSTITUTION'),
			('STRICT', 'ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION,ONLY_FULL_GROUP_BY,STRICT_ALL_TABLES,STRICT_TRANS_TABLES');
END;

CALL `_`.`install_default`();


DROP PROCEDURE IF EXISTS `_`.`sql_mode_save`;
CREATE PROCEDURE `_`.`sql_mode_save`(IN `sql_mode_name` VARCHAR(64), IN `sql_mode_string` VARCHAR(400))
	MODIFIES SQL DATA
	COMMENT 'Store specified SQL_MODE'
BEGIN
	-- duplicate key
	DECLARE EXIT HANDLER
		FOR 1062
	BEGIN
		SET @message_text = CONCAT('SQL_MODE already saved: \'', `sql_mode_name`, '\'');
		/*!50500
			SIGNAL SQLSTATE '45000' SET
					CLASS_ORIGIN = 'SQL_MODER',
					MESSAGE_TEXT = @message_text,
					SCHEMA_NAME = '_',
					TABLE_NAME = 'sql_mode',
					COLUMN_NAME = 'name',
					CONSTRAINT_SCHEMA = '_',
					CONSTRAINT_NAME = 'name';
		*/
		SELECT @message_text AS `error`;
	END;
	
	INSERT INTO `_`.`sql_mode`
			(`name`, `mode`)
		VALUE
			(`sql_mode_name`, UPPER(`sql_mode_string`));
END;


DROP PROCEDURE IF EXISTS `_`.`sql_mode_save_current`;
CREATE PROCEDURE `_`.`sql_mode_save_current`(IN `sql_mode_name` VARCHAR(64))
	MODIFIES SQL DATA
	COMMENT 'Store current session SQL_MODE'
BEGIN
	CALL `_`.`sql_mode_save`(`sql_mode_name`, @@session.sql_mode);
END;


DROP PROCEDURE IF EXISTS `_`.`sql_mode_force_save`;
CREATE PROCEDURE `_`.`sql_mode_force_save`(IN `sql_mode_name` VARCHAR(64), IN `sql_mode_string` VARCHAR(400))
	MODIFIES SQL DATA
	COMMENT 'Store specified SQL_MODE, even if exists'
BEGIN
	DECLARE EXIT HANDLER
		FOR 1305
	BEGIN
		SET @message_text = CONCAT('No transaction: cannot ROLLBACK old SQL_MODE deletion');
		/*!50500
			SIGNAL SQLSTATE '45000' SET
				CLASS_ORIGIN = 'SQL_MODER',
				MESSAGE_TEXT = @message_text;
		*/
		SELECT @message_text AS `error`;
	END;
	
	SAVEPOINT `sql_mode_force_save`;
	DELETE FROM `_`.`sql_mode` WHERE `name` = `sql_mode_name`;
	INSERT INTO `_`.`sql_mode`
			(`name`, `mode`)
		VALUE
			(`sql_mode_name`, UPPER(`sql_mode_string`));
	
	IF NOT ROW_COUNT() = 1 THEN
		ROLLBACK TO SAVEPOINT `sql_mode_force_save`;
	END IF;
END;


DROP PROCEDURE IF EXISTS `_`.`sql_mode_unsave`;
CREATE PROCEDURE `_`.`sql_mode_unsave`(IN `sql_mode_name` VARCHAR(64))
	MODIFIES SQL DATA
	COMMENT 'Delete specified SQL_MODE'
BEGIN
	DELETE FROM `_`.`sql_mode` WHERE `name` = `sql_mode_name`;
	
	IF NOT ROW_COUNT() > 0 THEN
		SET @message_text = CONCAT('SQL_MODE not found: \'', `sql_mode_name`, '\'');
		/*!50500
			SIGNAL SQLSTATE '45000' SET
				CLASS_ORIGIN = 'SQL_MODER',
				MESSAGE_TEXT = @message_text;
		*/
		SELECT @message_text AS `error`;
	END IF;
END;


DROP FUNCTION IF EXISTS `_`.`sql_mode_is_saved`;
CREATE FUNCTION `_`.`sql_mode_is_saved`(`sql_mode_name` VARCHAR(64))
	RETURNS BOOLEAN
	DETERMINISTIC
	READS SQL DATA
	COMMENT 'Return wether SQL_MODE is stored'
BEGIN
	RETURN EXISTS (SELECT 1 FROM `_`.`sql_mode` WHERE `name` = `sql_mode_name`);
END;


DROP PROCEDURE IF EXISTS `_`.`sql_mode_show_saved`;
CREATE PROCEDURE `_`.`sql_mode_show_saved`()
	READS SQL DATA
	COMMENT 'SHOW stored SQL_MODEs'
BEGIN
	SELECT * FROM `_`.`sql_mode`;
END;


DROP PROCEDURE IF EXISTS `_`.`sql_mode_show_saved_like`;
CREATE PROCEDURE `_`.`sql_mode_show_saved_like`(IN `like_pattern` TEXT)
	READS SQL DATA
	COMMENT 'SHOW stored SQL_MODEs WHERE name LIKE...'
BEGIN
	SELECT * FROM `_`.`sql_mode` WHERE `name` LIKE `like_pattern`;
END;


DROP FUNCTION IF EXISTS `_`.`sql_mode_get`;
CREATE FUNCTION `_`.`sql_mode_get`(`sql_mode_name` VARCHAR(64))
	RETURNS TEXT
	NOT DETERMINISTIC
	READS SQL DATA
	COMMENT 'Return stored SQL_MODE with specified name'
BEGIN
	RETURN (SELECT `mode` FROM `_`.`sql_mode` WHERE `name` = `sql_mode_name`);
END;


||
DELIMITER ;


COMMIT;

