-- run the app to create the tables, then run this script to add indexes
CREATE INDEX kudos_from_user_idx ON kudos (from_user);
CREATE INDEX kudos_to_user_idx ON kudos (to_user);
ALTER TABLE reactions ADD CONSTRAINT reactions_kudo_fk FOREIGN KEY (kudo_id) REFERENCES kudos (id) MATCH FULL;
ALTER TABLE reactions ADD CONSTRAINT reactions_value_fk FOREIGN KEY (value_id) REFERENCES values (id) MATCH FULL;
