-- Runs once, when the MySQL volume is new. The ghostspeak user is made by the image.
CREATE DATABASE IF NOT EXISTS `ghostspeak`;
CREATE DATABASE IF NOT EXISTS `ghostspeak-log`;
CREATE DATABASE IF NOT EXISTS `ghostspeak_auth`;
GRANT ALL PRIVILEGES ON `ghostspeak`.* TO 'ghostspeak'@'%';
GRANT ALL PRIVILEGES ON `ghostspeak-log`.* TO 'ghostspeak'@'%';
GRANT ALL PRIVILEGES ON `ghostspeak_auth`.* TO 'ghostspeak'@'%';
