-- ============================================================
-- CoreFW Database Schema
-- Import this FIRST before any seed files.
-- Requires: MySQL 5.7+ or MariaDB 10.2+
-- ============================================================

CREATE TABLE IF NOT EXISTS `groups` (
    `name`     VARCHAR(50) PRIMARY KEY,
    `label`    VARCHAR(100) NOT NULL,
    `priority` INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `players` (
    `id`         INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL UNIQUE,
    `last_name`  VARCHAR(60) DEFAULT NULL,
    `group`      VARCHAR(50) DEFAULT 'user',
    `position`   TEXT DEFAULT '{"x":-269.4,"y":-955.3,"z":31.2,"heading":205.0}',
    `health`     INT DEFAULT 200,
    `armour`     INT DEFAULT 0,
    `weapons`    TEXT DEFAULT '[]',
    `money`      INT DEFAULT 0,
    `kills`      INT DEFAULT 0,
    `deaths`     INT DEFAULT 0,
    `xp`         INT DEFAULT 0,
    `playtime`   INT DEFAULT 0,
    `job`        VARCHAR(50) DEFAULT 'unemployed',
    `job_grade`  INT DEFAULT 0,
    `status`     TEXT DEFAULT '{"wanted":false,"jailed":false,"jail_time":0,"bounty":0,"is_dead":false}',
    `skin`       TEXT DEFAULT NULL,
    `inventory`  TEXT DEFAULT '[]',
    `last_seen`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    FOREIGN KEY (`group`) REFERENCES `groups`(`name`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jobs` (
    `name`  VARCHAR(50) PRIMARY KEY,
    `label` VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `job_grades` (
    `id`        INT AUTO_INCREMENT PRIMARY KEY,
    `job_name`  VARCHAR(50) NOT NULL,
    `grade`     INT NOT NULL,
    `label`     VARCHAR(100) NOT NULL,
    `salary`    INT DEFAULT 0,
    UNIQUE KEY `uq_job_grade` (`job_name`, `grade`),
    FOREIGN KEY (`job_name`) REFERENCES `jobs`(`name`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `bans` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `identifier`  VARCHAR(60) NOT NULL,
    `reason`      VARCHAR(255) DEFAULT 'No reason given',
    `banned_by`   VARCHAR(60) DEFAULT 'Console',
    `ban_time`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expire_time` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_ban_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `items` (
    `name`     VARCHAR(50) PRIMARY KEY,
    `label`    VARCHAR(100) NOT NULL,
    `weight`   INT DEFAULT 1,
    `usable`   TINYINT DEFAULT 0,
    `metadata` TEXT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Default groups — imported as part of schema (required for FK)
-- ============================================================
INSERT INTO `groups` (`name`, `label`, `priority`) VALUES
    ('user',       'User',        0),
    ('mod',        'Moderator',  50),
    ('admin',      'Admin',      75),
    ('superadmin', 'Superadmin', 100)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `priority` = VALUES(`priority`);

-- ============================================================
-- Default items
-- ============================================================
INSERT INTO `items` (`name`, `label`, `weight`, `usable`) VALUES
    ('bread',   'Brot',    1, 1),
    ('water',   'Wasser',  1, 1),
    ('bandage', 'Verband', 1, 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `weight` = VALUES(`weight`), `usable` = VALUES(`usable`);
