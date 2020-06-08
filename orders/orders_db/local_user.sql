CREATE USER IF NOT EXISTS 'local_orders'@'%' IDENTIFIED BY 'local_orders';
GRANT ALL ON `local_orders`.* TO 'local_orders'@'%';
ALTER USER 'local_orders'@'%' IDENTIFIED WITH mysql_native_password BY 'local_orders';
FLUSH PRIVILEGES;
