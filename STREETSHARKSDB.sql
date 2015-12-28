-- this is a table that holds utility branches 
-- utility branches will store workers and utilities
-- found in the city and associated with that utility branch
CREATE TABLE UTILITY_BRANCH
(
utility_branch_id DECIMAL(9,0) UNSIGNED NOT NULL,
utility_branch_name VARCHAR(20) NOT NULL UNIQUE,
utility_branch_address_id DECIMAL(9,0) UNSIGNED NOT NULL,
PRIMARY KEY(utility_branch_id)
);

-- address is a holder table that stores everything
-- needed to know for an address (anything can point
-- to an address, a worker, a utility branch, and anything
-- extended to this database
CREATE TABLE ADDRESS
(
address_id DECIMAL(9,0) UNSIGNED NOT NULL,
street VARCHAR(100) NOT NULL,
city VARCHAR(40) NOT NULL,
state CHAR(2) NOT NULL,
zip_code DECIMAL(5,0) UNSIGNED NOT NULL,
phone_number DECIMAL(10,0) UNSIGNED NOT NULL,
PRIMARY KEY(address_id)
);

-- this table holds worker values
-- which will point to a certain utility_branch
-- and the values required for a worker to hold,
-- such as wages and their address, tasks and schedules
-- will point to worker so that they can reference
-- who is doing the job and when
CREATE TABLE WORKER
(
worker_id DECIMAL(9,0) UNSIGNED NOT NULL,
worker_utility_branch_id DECIMAL(9,0) UNSIGNED NOT NULL,
first_name VARCHAR(25) NOT NULL,
last_name VARCHAR(25) NOT NULL,
worker_address_id DECIMAL(9,0) UNSIGNED NOT NULL,
wage DECIMAL(7, 2) UNSIGNED NOT NULL,
PRIMARY KEY(worker_id)
);

-- this table is essentially the schedule for a worker
-- although schedule is a pre-named name in mysql
-- this schedule is assumed to be a 2 week period 
-- associated with a worker
CREATE TABLE TASK_SCHEDULE
(
schedule_id DECIMAL(9,0) UNSIGNED NOT NULL,
schedule_worker_id DECIMAL(9,0) UNSIGNED NOT NULL,
start_date DATE NOT NULL,
end_date DATE NOT NULL,
PRIMARY KEY(schedule_id)
);

-- a trigger that prevents schedule dates from overlapping on a worker and also prevents overlapping schedules on insert
DELIMITER $$ 
CREATE TRIGGER preventInvalidScheduleDates BEFORE INSERT ON TASK_SCHEDULE
FOR EACH ROW 
BEGIN
		IF ((NEW.start_date > NEW.end_date) OR (NEW.start_date > (NEW.end_date - INTERVAL 2 WEEK))) THEN
	    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: START DATE CANNOT BE AFTER END DATE OR LESS THAN A 2 WEEK PERIOD';
        END IF;
	    IF EXISTS(SELECT ts.schedule_worker_id FROM TASK_SCHEDULE ts WHERE ts.schedule_worker_id = NEW.schedule_worker_id AND
		((NEW.start_date >= ts.start_date AND
		NEW.start_date <= ts.end_date) OR
		(NEW.end_date <= ts.end_date AND
		NEW.end_date >= ts.start_date))) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: ONE WORKER CANT HAVE OVERLAPPING SCHEDULES';
        END IF;
END$$ 
DELIMITER ;

-- a trigger that prevents schedule dates from overlapping on a worker and also prevents overlapping schedules on update
DELIMITER $$ 
CREATE TRIGGER preventInvalidScheduleDates2 BEFORE UPDATE ON TASK_SCHEDULE
FOR EACH ROW 
BEGIN
		IF ((NEW.start_date > NEW.end_date) OR (NEW.start_date > (NEW.end_date - INTERVAL 2 WEEK))) THEN
	    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: START DATE CANNOT BE AFTER END DATE OR LESS THAN A 2 WEEK PERIOD';
        END IF;
	    IF EXISTS(SELECT ts.schedule_worker_id FROM TASK_SCHEDULE ts WHERE ts.schedule_worker_id = NEW.schedule_worker_id AND
		((NEW.start_date >= ts.start_date AND
		NEW.start_date <= ts.end_date) OR
		(NEW.end_date <= ts.end_date AND
		NEW.end_date >= ts.start_date))) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: ONE WORKER CANT HAVE OVERLAPPING SCHEDULES';
        END IF;
END$$ 
DELIMITER ;

-- a table that stores different types of utilities that a city would manage
-- in our case we only added LP and TF which stood for LightPost and Transformer
-- as well as the global positioning coordinates for said utility
CREATE TABLE UTILITY
(
utility_id DECIMAL(9,0) UNSIGNED NOT NULL,
description CHAR(2) NOT NULL,
latitude DECIMAL(6, 4) NOT NULL UNIQUE,
longitude DECIMAL(7, 4) NOT NULL UNIQUE,
PRIMARY KEY(utility_id)
);

-- trigger to prevent invalid coordinates from being entered on insert
DELIMITER $$ 
CREATE TRIGGER preventInvalidCoordinates BEFORE INSERT ON UTILITY
FOR EACH ROW 
BEGIN
			IF NEW.latitude > 90 OR NEW.latitude < -90 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: INVALID COORDINATES';
            END IF;
            IF NEW.longitude > 180 OR NEW.longitude < -180 THEN
		    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: INVALID COORDINATES';
            END IF;
END$$ 
DELIMITER ;

-- trigger to prevent invalid coordinates from being entered on update
DELIMITER $$ 
CREATE TRIGGER preventInvalidCoordinates2 BEFORE UPDATE ON UTILITY
FOR EACH ROW 
BEGIN
			IF NEW.latitude > 90 OR NEW.latitude < -90 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: INVALID COORDINATES';
            END IF;
            IF NEW.longitude > 180 OR NEW.longitude < -180 THEN
		    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: INVALID COORDINATES';
            END IF;
END$$ 
DELIMITER ;

-- task table is a table that is used to piece together a worker 
-- with a schedule, and fill up a worker's schedule with various tasks
-- at various times, 
-- it is the crux of the database, as it stores a worker reference, a 
-- schedule references and a utility reference 
-- as well as the exact time that the appointment is scheduled for
-- we assume that appointment dates and times would be entered correctly,
-- that is, a worker could work on one task and then the next minute, 
-- be working on another
CREATE TABLE TASK
(
task_id DECIMAL(9,0) UNSIGNED NOT NULL,
task_utility_id DECIMAL(9,0) UNSIGNED NOT NULL,
task_schedule_id DECIMAL(9,0) UNSIGNED NOT NULL,
appointment_date DATETIME,
PRIMARY KEY(task_id)
);

-- a trigger to prevent an appointment date from being before the schedule beginning
-- or after the schedule end, as well as preventing from appointment dates being
-- at exactly the same time (over lapping) on insert
DELIMITER $$ 
CREATE TRIGGER preventInvalidApptDate BEFORE INSERT ON TASK
FOR EACH ROW 
BEGIN
			-- task must be within schedule time
			IF NEW.appointment_date < (select ts.start_date from task_schedule ts where NEW.task_schedule_id = ts.schedule_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: APPOINTMENT DATE CANNOT BE BEFORE BEGINNING OF SCHEDULE';
            END IF;
            IF NEW.appointment_date > (select ts.end_date from task_schedule ts where NEW.task_schedule_id = ts.schedule_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: APPOINTMENT DATE CANNOT BE AFTER END OF SCHEDULE';
            END IF;
			-- checks if there is already an appointment date or not
			IF NEW.appointment_date = ANY(select t.appointment_date from task_schedule ts, task t where NEW.task_schedule_id = ts.schedule_id) THEN
		    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: APPOINTMENT DATE CANNOT BE AT THE SAME TIME AS AN EXISTING APPOINTMENT';
			END IF;
END$$ 
DELIMITER ;

-- a trigger to prevent an appointment date from being before the schedule beginning
-- or after the schedule end, as well as preventing from appointment dates being
-- at exactly the same time (over lapping) on update
DELIMITER $$ 
CREATE TRIGGER preventInvalidApptDate2 BEFORE UPDATE ON TASK
FOR EACH ROW 
BEGIN
			-- task must be within schedule time
			IF NEW.appointment_date < (select ts.start_date from task_schedule ts where NEW.task_schedule_id = ts.schedule_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: APPOINTMENT DATE CANNOT BE BEFORE BEGINNING OF SCHEDULE';
            END IF;
            IF NEW.appointment_date > (select ts.end_date from task_schedule ts where NEW.task_schedule_id = ts.schedule_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: APPOINTMENT DATE CANNOT BE AFTER END OF SCHEDULE';
            END IF;
			-- checks if there is already an appointment date or not
			IF NEW.appointment_date = ANY(select t.appointment_date from task_schedule ts, task t where NEW.task_schedule_id = ts.schedule_id) THEN
		    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: APPOINTMENT DATE CANNOT BE AT THE SAME TIME AS AN EXISTING APPOINTMENT';
			END IF;
END$$ 
DELIMITER ;

-- equipment table is used to store various equipment
-- used for certain tasks and stored at various utility branches
CREATE TABLE EQUIPMENT
(
equipment_id DECIMAL(9,0) UNSIGNED NOT NULL,
equipment_utility_branch_id DECIMAL(9,0) UNSIGNED NOT NULL,
quantity DECIMAL(6,0) NOT NULL,
description VARCHAR(250) NOT NULL,
PRIMARY KEY(equipment_id, equipment_utility_branch_id)
);

-- equipment required table will store all of the certain equipment required
-- associated with completing a task as well as the quantity
-- and will point to various tasks and equipments as necessary
CREATE TABLE EQUIPMENT_REQUIRED
(
equipment_required_task_id DECIMAL(9,0) UNSIGNED NOT NULL,
equipment_required_equipment_id DECIMAL(9,0) UNSIGNED NOT NULL,
quantity DECIMAL(2,0) NOT NULL,
PRIMARY KEY(equipment_required_task_id, equipment_required_equipment_id)
);

-- this table is used to keep track of how much equipment is currently
-- out at a certain branch, as well as what worker has what equipment
-- we make an assumption on this table that we didn't do in our console app
-- because the project is more about databasing and less about console app
-- we did NOT automatically update the count in equipment when an 
-- equipment_out record is entered 
CREATE TABLE EQUIPMENT_OUT
(
equipment_out_equipment_id DECIMAL(9,0) UNSIGNED NOT NULL,
equipment_out_utility_branch_id DECIMAL(9,0) UNSIGNED NOT NULL,
equipment_out_worker_id DECIMAL(9,0) UNSIGNED NOT NULL,
count DECIMAL(6,0) NOT NULL,
PRIMARY KEY(equipment_out_equipment_id, equipment_out_utility_branch_id, equipment_out_worker_id)
);

-- a trigger to prevent a user from pulling out insufficient stock from an equipment in a certain utility branch on insert
-- we make an assumption on this table that we didn't do in our console app
-- because the project is more about databasing and less about console app
-- we did NOT automatically update the count in equipment when an 
-- equipment_out record is entered 
DELIMITER $$ 
CREATE TRIGGER preventOverCheckOut BEFORE INSERT ON EQUIPMENT_OUT
FOR EACH ROW 
BEGIN
			IF NEW.count > ANY (select quantity from equipment where equipment_utility_branch_id = NEW.equipment_out_utility_branch_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: INSUFFICIENT STOCK TO CHECK OUT THAT ITEM';
            END IF;
            IF NEW.equipment_out_utility_branch_id != ANY (select worker_utility_branch_id from worker where worker_id = new.equipment_out_worker_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: WORKER CANNOT CHECK OUT FROM OTHER BRANCHES';
            END IF;
END$$ 
DELIMITER ;

-- a trigger to prevent a user from pulling out insufficient stock from an equipment in a certain utility branch on update
-- we make an assumption on this table that we didn't do in our console app
-- because the project is more about databasing and less about console app
-- we did NOT automatically update the count in equipment when an 
-- equipment_out record is entered 
DELIMITER $$ 
CREATE TRIGGER preventOverCheckOut2 BEFORE UPDATE ON EQUIPMENT_OUT
FOR EACH ROW 
BEGIN
			IF NEW.count > (select quantity from equipment where equipment_utility_branch_id = NEW.equipment_out_utility_branch_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: INSUFFICIENT STOCK TO CHECK OUT THAT ITEM';
            END IF;
            IF NEW.equipment_out_utility_branch_id != (select worker_utility_branch_id from worker where worker_id = new.equipment_out_worker_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAILURE: WORKER CANNOT CHECK OUT FROM OTHER BRANCHES';
            END IF;
END$$ 
DELIMITER ;

-- simple constraint adding at the end for foreign key references on each table
-- we did all of our foreign key creations at the end of the creation of the tables because
-- this way no compilation errors will occur as going down and we don't have to
-- order our tables properly

-- start foreign key creations
ALTER TABLE UTILITY_BRANCH
ADD CONSTRAINT UBFK1
FOREIGN KEY (utility_branch_address_id) REFERENCES ADDRESS(address_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE WORKER
ADD CONSTRAINT ADDRFK1
FOREIGN KEY (worker_address_id) REFERENCES ADDRESS(address_id)
ON DELETE CASCADE
ON UPDATE CASCADE,

ADD CONSTRAINT UBFK2
FOREIGN KEY(worker_utility_branch_id) REFERENCES utility_branch(utility_branch_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE TASK_SCHEDULE
ADD CONSTRAINT TSFK1
FOREIGN KEY (schedule_worker_id) REFERENCES WORKER(worker_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE TASK
ADD CONSTRAINT TFK1
FOREIGN KEY (task_utility_id) REFERENCES UTILITY(utility_id)
ON DELETE CASCADE
ON UPDATE CASCADE,

ADD CONSTRAINT TFK2
FOREIGN KEY (task_schedule_id) REFERENCES TASK_SCHEDULE(schedule_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE EQUIPMENT
ADD CONSTRAINT EFK1
FOREIGN KEY (equipment_utility_branch_id) REFERENCES UTILITY_BRANCH(utility_branch_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE EQUIPMENT_REQUIRED
ADD CONSTRAINT EQRFK1
FOREIGN KEY (equipment_required_equipment_id) REFERENCES EQUIPMENT(equipment_id)
ON DELETE CASCADE
ON UPDATE CASCADE,

ADD CONSTRAINT EQRFK2
FOREIGN KEY (equipment_required_task_id) REFERENCES TASK(task_id)
ON DELETE CASCADE 
ON UPDATE CASCADE;

ALTER TABLE EQUIPMENT_OUT
ADD CONSTRAINT EQOFK1
FOREIGN KEY (equipment_out_worker_id) REFERENCES WORKER(worker_id)
ON DELETE CASCADE
ON UPDATE CASCADE,

ADD CONSTRAINT EQOFK2
FOREIGN KEY (equipment_out_equipment_id) REFERENCES EQUIPMENT(equipment_id)
ON DELETE CASCADE
ON UPDATE CASCADE,

ADD CONSTRAINT EQ0FK3
FOREIGN KEY (equipment_out_utility_branch_id) REFERENCES UTILITY_BRANCH(utility_branch_id)
ON DELETE CASCADE
ON UPDATE CASCADE;
-- end foreign key creations

-- begin inserts
insert into address values(000000001, '1st Ave', 'Seattle', 'WA', 98121, 2065550123);
insert into address values(000000002, '2nd Ave', 'Seattle', 'WA', 98121, 2065550124); -- 002    
insert into utility_branch values(000000001, 'Original', 000000001);  
insert into worker values(000000001, 000000001,  'John', 'Smith', 000000002, 99999.99); -- 002
insert into task_schedule values(000000001, 00000001, '2015-11-16', '2015-11-30');
insert into utility values(000000001, 'TF', 47.6039, -122.3342);
insert into utility values(000000002, 'LP', 41.0002, -120.0002); -- 002
insert into equipment values(000000001, 000000001, 1, 'Hammer');
insert into task values(000000001, 000000001, 000000001, '2015-11-18 17:30:00');
insert into equipment_required values(000000001, 000000001, 1);
insert into equipment_out values(000000001, 000000001, 000000001, 1);
insert into equipment values(000000002, 000000001, 1, 'Wrench'); -- 002
insert into task values(000000002, 000000002, 000000001, '2015-11-18 17:41:00'); -- 002
insert into equipment_required values(000000002, 000000002, 1); -- 002
insert into equipment_out values(000000002, 000000001, 000000001, 1); -- 002

insert into address values(000000003, '3rd Ave', 'Bothell', 'WA', 98107, 2065550125);
insert into address values(000000004, '4th Ave', 'Bothell', 'WA', 98107, 2065550126); -- 004    
insert into utility_branch values(000000003, 'Unoriginal', 000000003);  
insert into worker values(000000003, 000000003, 'John', 'Daley', 000000004, 43000.99); -- 004
insert into utility values(000000003, 'TF', 31.6048, -89.0413);
insert into utility values(000000004, 'LP', 11.0001, -34.0784); -- 004
insert into equipment values(000000004, 000000003, 1, 'Wrench'); -- 004
insert into task values(000000004, 000000004, 000000001,'2015-11-18 16:29:00'); -- 004

insert into address values(000000005, '5th Ave', 'Monroe', 'WA', 98272, 2065550127);
insert into address values(000000006, '6th Ave', 'Monroe', 'WA', 98272, 2065550128); 
insert into address values(000000007, '7th Ave', 'Monroe', 'WA', 98272, 2065550129);
insert into address values(000000008, '8th Ave', 'Monroe', 'WA', 98272, 2065550130);
insert into utility_branch values(000000005, 'UBIII', 000000005);  
insert into worker values(000000005, 000000005, 'John', 'Mcmahon', 000000006, 56777.99);
insert into worker values(000000006, 000000005, 'John', 'Tate', 000000007, 21340.99);
insert into worker values(000000007, 000000005, 'John', 'Lasicky', 000000008, 87450.21);
insert into task_schedule values(000000005, 00000005, '2015-11-16', '2015-11-30');
insert into task_schedule values(000000006, 00000006, '2015-11-16', '2015-11-30');
insert into task_schedule values(000000007, 00000007, '2015-11-16', '2015-11-30');

insert into utility values(0000000010, 'TF', 64.213, -41.897);
insert into utility values(000000011, 'LP', 9.0321, -46.704);
insert into utility values(000000012, 'TF', 57.6048, -21.0413);
insert into utility values(000000013, 'LP', 13.8760, -10.0784);
insert into utility values(000000014, 'TF', 52.6048, -87.0413);
insert into utility values(000000015, 'LP', 12.3412, -10.1234);

insert into equipment values(000000006, 000000005, 1, 'Hammer');
insert into equipment values(000000007, 000000005, 1, 'Wrench');
insert into equipment values(000000008, 000000005, 1, 'Wire');
insert into task values(000000005, 0000000010, 000000005, '2015-11-18 14:30:00');
insert into equipment_required values(000000005, 000000006, 1);
insert into equipment_out values(000000008, 000000005, 000000006, 1);

insert into task_schedule values(000000009, 00000007, '2015-12-01', '2015-12-15');
insert into task values(000000006, 0000000010, 000000009, '2015-12-07 08:30:00');
insert into task values(000000007, 0000000011, 000000009, '2015-12-07 13:45:00');
insert into task values(000000008, 0000000013, 000000009, '2015-12-09 10:00:00');
insert into task values(000000009, 0000000014, 000000009, '2015-12-09 20:15:00');
insert into task values(000000010, 0000000010, 000000009, '2015-12-05 15:37:46');
insert into task values(000000011, 0000000015, 000000009, '2015-12-05 16:37:46');
-- end inserts