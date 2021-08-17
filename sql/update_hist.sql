CREATE TABLE IF NOT EXISTS test (           
  message varchar(255) NOT NULL         
  );          
  INSERT INTO test(message) VALUES('update hist');
ALTER TABLE test OWNER TO "dbusername";
