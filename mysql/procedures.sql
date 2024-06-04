
-- *************** 以下为存储过程创建 ***************



-- *************** “改” ***************
-- A procedure that transfer money from one account to another. Transaction is used to ensure the atomicity of the operation.
DROP PROCEDURE if exists transfer_money;
delimiter //
CREATE PROCEDURE transfer_money(IN from_account_id VARCHAR(50), IN to_account_id VARCHAR(50), IN amount DECIMAL(20, 2), OUT sta INT)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE a INT;
    DECLARE continue HANDLER FOR SQLEXCEPTION SET s = 1;
    SET sta = 0;

    START TRANSACTION;
    -- Check whether both accounts exsit
    SELECT count(*) FROM account WHERE account_id = from_account_id or account_id = to_account_id INTO a;
    IF a != 2 THEN
        SET sta = -2;  -- Error code -2: account does not exist
    END IF;

    IF sta = 0 THEN
        -- Check if the balance is enough
        SELECT balance FROM account WHERE account_id = from_account_id INTO a;
        IF a < amount THEN
            SET sta = -3; -- Error code -3: balance is not enough
        ELSE
            -- Update the balaces of two accounts
            UPDATE account SET balance = balance - amount WHERE account_id = from_account_id;
            UPDATE account SET balance = balance + amount WHERE account_id = to_account_id;
        END IF;
    END IF;

    -- Process errors
    IF s = 0 AND sta = 0 THEN
        SET sta = 1;
        COMMIT;
    ELSE
        IF sta = 0 THEN
            SET sta = -9; -- Error code -9: unknown error within MySQL
        END IF;
        ROLLBACK;
    END IF;
END //
delimiter ;


-- A procedure that repays a loan. Transaction is used to ensure the atomicity of the operation.
DROP PROCEDURE if exists repay_loan;
delimiter //
CREATE PROCEDURE repay_loan(IN repay_loan_id VARCHAR(50), IN repay_account_id VARCHAR(50), IN repay_amount DECIMAL(20, 2), OUT sta INT)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE a INT;
    DECLARE continue HANDLER FOR SQLEXCEPTION SET s = 1;
    SET sta = 0;

    START TRANSACTION;
    -- Check whether the loan and account exsit
    SELECT count(*) FROM loan WHERE loan_id = repay_loan_id INTO a;
    IF a != 1 THEN
        SET sta = -2;  -- Error code -2: loan does not exist
    END IF;
    SELECT count(*) FROM account WHERE account_id = repay_account_id INTO a;
    IF a != 1 THEN
        SET sta = -3;  -- Error code -3: account does not exist
    END IF;

    IF sta = 0 THEN
        -- Check if the balance is enough
        SELECT balance FROM account WHERE account_id = repay_account_id INTO a;
        IF a < repay_amount THEN
            SET sta = -4; -- Error code -4: balance is not enough
        ELSE
            -- Update the balaces of the account and the loan
            UPDATE account SET balance = balance - repay_amount WHERE account_id = repay_account_id;
            UPDATE loan SET unrepayed_amount = unrepayed_amount - repay_amount WHERE loan_id = repay_loan_id;
        END IF;
    END IF;

    -- Process errors
    IF s = 0 AND sta = 0 THEN
        SET sta = 1;
        COMMIT;
    ELSE
        IF sta = 0 THEN
            SET sta = -9; -- Error code -9: unknown error within MySQL
        END IF; 
        ROLLBACK;
    END IF;
END //
delimiter ;


-- A procedure that changes the name of a bank.
DROP PROCEDURE if exists change_bank;
delimiter //
CREATE PROCEDURE change_bank(IN old_bank_name VARCHAR(50), IN new_bank_name VARCHAR(50), In new_bank_addr VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the bank exsit
    SELECT count(*) FROM bank WHERE bank_name = old_bank_name INTO a;
    IF a = 1 THEN 
        IF new_bank_name = old_bank_name THEN
            UPDATE bank SET bank_addr = new_bank_addr WHERE bank_name = old_bank_name;
            SET sta = 1;
        ELSE
            SELECT count(*) FROM bank WHERE bank_name = new_bank_name INTO a;
            IF a = 1 THEN
                SET sta = -4; -- Error code -4: New bank already exists
            ELSE
                INSERT INTO bank (bank_name, bank_addr) VALUES (new_bank_name, new_bank_addr);
                -- Update the bank_name of all accounts
                UPDATE account SET bank_name = new_bank_name WHERE bank_name = old_bank_name;
                -- Update the bank_name of all loans
                UPDATE loan SET bank_name = new_bank_name WHERE bank_name = old_bank_name;
                -- Update the bank_name of all departments
                UPDATE department SET bank_name = new_bank_name WHERE bank_name = old_bank_name;
                -- Delete the old bank
                DELETE FROM bank WHERE bank_name = old_bank_name;
                SET sta = 1;
            END IF;
        END IF;
    ELSE
        SET sta = -2; -- Error code -2: bank does not exist
    END IF;
END //
delimiter ;


-- A procedure that changes the id of a customer.
DROP PROCEDURE if exists change_customer;
delimiter //
CREATE PROCEDURE change_customer(IN old_customer_id VARCHAR(50), IN new_customer_id VARCHAR(50), IN new_name VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the customer exsit
    SELECT count(*) FROM customer WHERE id = old_customer_id INTO a;
    IF a = 1 THEN 
        IF new_customer_id = old_customer_id THEN
            UPDATE customer SET customer_name = new_name WHERE id = old_customer_id;
            SET sta = 1;
        ELSE
            SELECT count(*) FROM customer WHERE id = new_customer_id INTO a;
            IF a = 1 THEN
                SET sta = -4; -- Error code -4: New customer already exists
            ELSE
                -- Insert the new customer_id
                INSERT INTO customer (id, customer_name) VALUES (new_customer_id, new_name);
                -- Update the customer_id of all accounts
                UPDATE account SET customer_id = new_customer_id WHERE customer_id = old_customer_id;
                -- Update the customer_id of all loans
                UPDATE loan SET customer_id = new_customer_id WHERE customer_id = old_customer_id;
                -- Update the customer_id of all customer_loan relationships
                UPDATE customer_loan SET customer_id = new_customer_id WHERE customer_id = old_customer_id;
                -- Delete the old customer
                DELETE FROM customer WHERE id = old_customer_id;
                SET sta = 1;
            END IF;
        END IF;
    ELSE
        SET sta = -2; -- Error code -2: customer does not exist
    END IF;
END //
delimiter ;


-- A procedure that changes the id of an account.
DROP PROCEDURE if exists change_account;
delimiter //
CREATE PROCEDURE change_account(IN old_account_id VARCHAR(50), IN new_account_id VARCHAR(50), IN new_balance DECIMAL(20, 2), IN new_customer_id VARCHAR(50), IN new_bank_name VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE a INT;
    DECLARE continue HANDLER FOR SQLEXCEPTION SET s = 1;
    SET sta = 0;

    -- Check whether the new bank exsits
    SELECT count(*) FROM bank WHERE bank_name = new_bank_name INTO a;
    IF a = 0 THEN
        SET sta = -4; -- Error code -4: New bank does not exist
    END IF;
    -- Check whether the new customer exsits
    SELECT count(*) FROM customer WHERE id = new_customer_id INTO a;
    IF a = 0 THEN
        SET sta = -5; -- Error code -5: New customer does not exist
    END IF;
    -- Check whether the old account exsits
    SELECT count(*) FROM account WHERE account_id = old_account_id INTO a;
    IF a = 0 THEN
        SET sta = -2; -- Error code -2: Account does not exist
    END IF;

    IF sta = 0 THEN
        IF new_account_id = old_account_id THEN
            UPDATE account SET balance = new_balance, customer_id = new_customer_id, bank_name = new_bank_name WHERE account_id = old_account_id;
        ELSE
            -- Check whether the new account exsits
            SELECT count(*) FROM account WHERE account_id = new_account_id INTO a;
            IF a = 1 THEN
                SET sta = -6; -- Error code -6: New account already exists
            ELSE
                -- Update
                UPDATE account SET account_id = new_account_id, balance = new_balance, customer_id = new_customer_id, bank_name = new_bank_name WHERE account_id = old_account_id;
            END IF;
        END IF;
    END IF;

    -- Process errors
    IF s = 0 AND sta = 0 THEN
        SET sta = 1;
    ELSE
        IF sta = 0 THEN
            SET sta = -9; -- Error code -9: Unknown error within MySQL
        END IF;
    END IF;

END //
delimiter ;


-- A procedure that changes the id of a loan.
DROP PROCEDURE if exists change_loan;
delimiter //
CREATE PROCEDURE change_loan(IN old_loan_id VARCHAR(50), IN new_loan_id VARCHAR(50), IN new_loan_amount DECIMAL(20, 2), IN new_unrepayed_amount DECIMAL(20, 2), In new_customer_id VARCHAR(50), IN new_bank_name VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE a INT;
    DECLARE continue HANDLER FOR SQLEXCEPTION SET s = 1;
    SET sta = 0;

    -- Check whether the new bank exsits
    SELECT count(*) FROM bank WHERE bank_name = new_bank_name INTO a;
    IF a = 0 THEN
        SET sta = -5; -- Error code -5: New bank does not exist
    END IF;
    -- Check whether the new customer exsits
    SELECT count(*) FROM customer WHERE id = new_customer_id INTO a;
    IF a = 0 THEN
        SET sta = -6; -- Error code -6: New customer does not exist
    END IF;
    -- Check whether the old loan exsits
    SELECT count(*) FROM loan WHERE loan_id = old_loan_id INTO a;
    IF a = 0 THEN
        SET sta = -2; -- Error code -2: Loan does not exist
    END IF;
    -- Note that the check of nre_loan_amount and new_unrepayed_amount is complemented in db.py

    IF sta = 0 THEN
        IF new_loan_id = old_loan_id THEN
            UPDATE loan SET loan_amount = new_loan_amount, unrepayed_amount = new_unrepayed_amount, customer_id = new_customer_id, bank_name = new_bank_name WHERE loan_id = old_loan_id;
        ELSE
            -- Check whether the new loan exsits
            SELECT count(*) FROM loan WHERE loan_id = new_loan_id INTO a;
            IF a = 1 THEN
                SET sta = -15; -- Error code -15: New loan already exists
            ELSE
                -- Update
                UPDATE loan SET loan_id = new_loan_id, loan_amount = new_loan_amount, unrepayed_amount = new_unrepayed_amount, customer_id = new_customer_id, bank_name = new_bank_name WHERE loan_id = old_loan_id;
            END IF;
        END IF;
    END IF;

    -- Process errors
    IF s = 0 AND sta = 0 THEN
        SET sta = 1;
    ELSE
        IF sta = 0 THEN
            SET sta = -9; -- Error code -9: Unknown error within MySQL
        END IF;
    END IF;

END //
delimiter ;


-- A procedure that changes the id of a employee.
DROP PROCEDURE if exists change_employee;
delimiter //
CREATE PROCEDURE change_employee(IN old_id VARCHAR(50), IN new_id VARCHAR(50), IN new_name VARCHAR(50), IN new_path VARCHAR(100), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the employee exsit
    SELECT count(*) FROM employee WHERE id = old_id INTO a;
    IF a = 1 THEN 
        IF new_id = old_id THEN
            IF new_path = 'special_token_original' THEN
                SELECT path_to_photo FROM employee WHERE id = old_id INTO new_path;
            END IF;
            UPDATE employee SET employee_name = new_name, path_to_photo = new_path WHERE id = old_id;
            SET sta = 1;
        ELSE
            SELECT count(*) FROM employee WHERE id = new_id INTO a;
            IF a = 1 THEN
                SET sta = -4; -- Error code -4: New employee already exists
            ELSE
                -- If new_path is 'special_token_original', keep the old path
                IF new_path = 'special_token_original' THEN
                    SELECT path_to_photo FROM employee WHERE id = old_id INTO new_path;
                END IF;
                -- Insert the new employee
                INSERT INTO employee (id, employee_name, path_to_photo) VALUES (new_id, new_name, new_path);
                -- Update the id of all employee_department relationships
                UPDATE employee_department SET employee_id = new_id WHERE employee_id = old_id;
                -- Delete the old employee
                DELETE FROM employee WHERE id = old_id;
                SET sta = 1;
            END IF;
        END IF;
    ELSE
        SET sta = -2; -- Error code -2: employee does not exist
    END IF;
END //
delimiter ;


-- A procedure that changes the name of a department. 
DROP PROCEDURE if exists change_department;
delimiter //
CREATE PROCEDURE change_department(IN old_department_id VARCHAR(50), IN new_department_id VARCHAR(50), IN new_bank_name VARCHAR(50), IN new_department_name VARCHAR(50), IN new_leader_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE a INT;
    DECLARE continue HANDLER FOR SQLEXCEPTION SET s = 1;
    SET sta = 0;

    -- Check whether the new leader exsit
    SELECT count(*) FROM employee WHERE id = new_leader_id INTO a;
    IF a = 0 THEN
        SET sta = -5; -- Error code -5: New leader does not exist
    END IF;
    -- Check whether the new bank exsit
    SELECT count(*) FROM bank WHERE bank_name = new_bank_name INTO a;
    IF a = 0 THEN
        SET sta = -4; -- Error code -4: New bank does not exist
    END IF;
    -- Check whether the old department exsit
    SELECT count(*) FROM department WHERE department_id = old_department_id INTO a;
    IF a = 0 THEN
        SET sta = -2; -- Error code -2: Department does not exist
    END IF;

    IF sta = 0 THEN
        IF new_department_id = old_department_id THEN
            UPDATE department SET bank_name = new_bank_name, department_name = new_department_name, leader_id = new_leader_id WHERE department_id = old_department_id;
        ELSE
            -- Check whether the new department exsit
            SELECT count(*) FROM department WHERE department_id = new_department_id INTO a;
            IF a = 1 THEN
                SET sta = -6; -- Error code -6: New department already exists
            ELSE
                -- Delete the old employee_department relationships
                DELETE FROM employee_department WHERE department_id = old_department_id AND employee_id = old_leader_id;
                -- Insert the new department_name
                INSERT INTO department (department_id, bank_name, department_name, leader_id) VALUES (new_department_id, new_bank_name, new_department_name, new_leader_id);
                -- Update the bank_name and department_name of all employee_department relationships
                UPDATE employee_department SET department_id = new_department_id WHERE department_id = old_department_id;
                -- Delete the old department
                DELETE FROM department WHERE department_id = old_department_id;
            END IF;
        END IF;
    END IF;

    -- Process errors
    IF s = 0 AND sta = 0 THEN
        SET sta = 1;
    ELSE
        IF sta = 0 THEN
            SET sta = -7; -- Error code -7: Unknown error within MySQL
        END IF;
    END IF;

END //
delimiter ;

-- A procedure that changes the employee_department relationship.
DROP PROCEDURE if exists change_employee_department;
delimiter //
CREATE PROCEDURE change_employee_department(IN old_employee_id VARCHAR(50), IN old_department_id VARCHAR(50), IN new_employee_id VARCHAR(50), IN new_department_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE a INT;
    DECLARE continue HANDLER FOR SQLEXCEPTION SET s = 1;
    SET sta = 0;

    -- Check whether the new department exsit
    SELECT count(*) FROM department WHERE department_id = new_department_id INTO a;
    IF a = 0 THEN
        SET sta = -4; -- Error code -4: New department does not exist
    END IF;
    -- Check whether the new employee exsit
    SELECT count(*) FROM employee WHERE id = new_employee_id INTO a;
    IF a = 0 THEN
        SET sta = -2; -- Error code -2: New employee does not exist
    END IF;
    -- Check whether the old employee_department exsit
    SELECT count(*) FROM employee_department WHERE department_id = old_department_id AND employee_id = old_employee_id INTO a;
    IF a = 0 THEN
        SET sta = -5; -- Error code -5: Employee_department does not exist
    END IF;
    -- Check whether the old department exsit
    SELECT count(*) FROM department WHERE department_id = old_department_id INTO a;
    IF a = 0 THEN
        SET sta = -6; -- Error code -6: Old department does not exist
    END IF;
    -- Check whether the old employee exsit
    SELECT count(*) FROM employee WHERE id = old_employee_id INTO a;
    IF a = 0 THEN
        SET sta = -7; -- Error code -7: Old employee does not exist
    END IF;
    -- Check whether the old employee is the leader of the old department
    SELECT count(*) FROM department WHERE leader_id = old_employee_id AND department_id = old_department_id INTO a;
    IF a = 1 THEN
        SET sta = -9; -- Error code -9: The old employee is the leader of the old department
    END IF;

    IF sta = 0 THEN
        IF new_employee_id != old_employee_id OR new_department_id != old_department_id THEN
            -- Check whether the new employee_department exsit
            SELECT count(*) FROM employee_department WHERE department_id = new_department_id AND employee_id = new_employee_id INTO a;
            IF a = 1 THEN
                SET sta = -3; -- Error code -3: New employee_department already exists
            ELSE
                -- Update the employee_department relationship
                UPDATE employee_department SET department_id = new_department_id, employee_id = new_employee_id WHERE department_id = old_department_id AND employee_id = old_employee_id;
            END IF;
        END IF;
    END IF;

    -- Process errors
    IF s = 0 AND sta = 0 THEN
        SET sta = 1;
    ELSE
        IF sta = 0 THEN
            SET sta = -8; -- Error code -8: Unknown error within MySQL
        END IF;
    END IF;

END //
delimiter ;
























-- *************** “增” ***************

-- A procedure that creates a new bank.
DROP PROCEDURE if exists create_bank;
delimiter //
CREATE PROCEDURE create_bank(IN add_bank_name VARCHAR(50), IN bank_addr VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;
    
    -- Check whether the bank exsit
    SELECT count(*) FROM bank WHERE bank_name = add_bank_name INTO a;
    IF a = 0 THEN
        INSERT INTO bank (bank_name, bank_addr) VALUES (add_bank_name, bank_addr);
        SET sta = 1;
    ELSE
        SET sta = -3; -- Error code -3: bank already exists
    END IF;
END //
delimiter ;


-- A procedure that creates a new customer.
DROP PROCEDURE if exists create_customer;
delimiter //
CREATE PROCEDURE create_customer(IN customer_id VARCHAR(50), IN customer_name VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the customer exsit
    SELECT count(*) FROM customer WHERE id = customer_id INTO a;
    IF a = 0 THEN
        INSERT INTO customer (id, customer_name) VALUES (customer_id, customer_name);
        SET sta = 1;
    ELSE
        SET sta = -3; -- Error code -3: customer already exists
    END IF;
END //
delimiter ;


-- A procedure that creates a new account for a customer. Transaction is used to ensure the atomicity of the operation.
DROP PROCEDURE if exists create_account;
delimiter //
CREATE PROCEDURE create_account(IN add_account_id VARCHAR(50), IN add_customer_id VARCHAR(50), IN add_bank_name VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE a INT;
    DECLARE continue HANDLER FOR SQLEXCEPTION SET s = 1;
    SET sta = 0;

    START TRANSACTION;
    -- Check whether the bank exsit
    SELECT count(*) FROM bank WHERE bank_name = add_bank_name INTO a;
    IF a != 1 THEN
        SET sta = -4;  -- Error code -4: bank does not exist
    END IF;
    -- Check whether the customer exsit 
    SELECT count(*) FROM customer WHERE id = add_customer_id INTO a;
    IF a != 1 THEN
        SET sta = -5;  -- Error code -5: customer does not exist
    END IF;
    -- Check whether the account already exsits
    SELECT count(*) FROM account WHERE account_id = add_account_id INTO a;
    IF a != 0 THEN
        SET sta =-6;  -- Error code -6: account already exists
    END IF;

    -- No problem, insert the new account
    IF sta = 0 THEN
        INSERT INTO account (account_id, customer_id, bank_name) VALUES (add_account_id, add_customer_id, add_bank_name);
    END IF;

    -- Process errors
    IF s = 0 AND sta = 0 THEN
        SET sta = 1;
        COMMIT;
    ELSE
        IF sta = 0 THEN
            SET sta = -9; -- Error code -9: unknown error within MySQL
        END IF;
        ROLLBACK;
    END IF;

END //
delimiter ;


-- A procedure that creates a new loan for a customer. Transaction is used to ensure the atomicity of the operation.
DROP PROCEDURE if exists create_loan;
delimiter //
CREATE PROCEDURE create_loan(IN add_loan_id VARCHAR(50), IN add_loan_amount DECIMAL(20, 2), IN add_customer_id VARCHAR(50), IN add_bank_name VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE a INT;
    DECLARE add_unrepayed_amount DECIMAL(20, 2);
    DECLARE continue HANDLER FOR SQLEXCEPTION SET s = 1;
    SET sta = 0;
    SET add_unrepayed_amount = add_loan_amount;

    START TRANSACTION;
    -- Check whether the bank exsit
    SELECT count(*) FROM bank WHERE bank_name = add_bank_name INTO a;
    IF a != 1 THEN
        SET sta = -5;  -- Error code -5: bank does not exist
    END IF;
    -- Check whether the customer exsits
    SELECT count(*) FROM customer WHERE id = add_customer_id INTO a;
    IF a != 1 THEN
        SET sta = -6;  -- Error code -6: customer does not exist
    END IF;
    -- Check whether the loan already exsits
    SELECT count(*) FROM loan WHERE loan_id = add_loan_id INTO a;
    IF a != 0 THEN
        SET sta = -15;  -- Error code -15: loan already exists
    END IF;

    -- No problem, insert the new loan
    IF sta = 0 THEN
        INSERT INTO loan (loan_id, loan_amount, unrepayed_amount, customer_id, bank_name) VALUES (add_loan_id, add_loan_amount, add_unrepayed_amount, add_customer_id, add_bank_name);
    END IF;

    -- Process errors
    IF s = 0 AND sta = 0 THEN
        SET sta = 1;
        COMMIT;
    ELSE
        IF sta = 0 THEN
            SET sta = -9; -- Error code -9: unknown error within MySQL
        END IF;
        ROLLBACK;
    END IF;
END // 
delimiter ;


-- A procedure that creates a new employee.
DROP PROCEDURE if exists create_employee;
delimiter //
CREATE PROCEDURE create_employee(IN add_id VARCHAR(50), IN add_employee_name VARCHAR(50), IN add_path_to_photo VARCHAR(100), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the employee exsit
    SELECT count(*) FROM employee WHERE id = add_id INTO a;
    IF a = 0 THEN
        INSERT INTO employee (id, employee_name, path_to_photo) VALUES (add_id, add_employee_name, add_path_to_photo);
        SET sta = 1;
    ELSE
        SET sta = -3; -- Error code -3: employee already exists
    END IF;
END //
delimiter ;


-- A procedure that creates a new department.
DROP PROCEDURE if exists create_department;
delimiter //
CREATE PROCEDURE create_department(IN add_department_id VARCHAR(50), IN add_bank_name VARCHAR(50), IN add_department_name VARCHAR(50), IN add_leader_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE a INT;
    DECLARE continue HANDLER FOR SQLEXCEPTION SET s = 1;

    START TRANSACTION;
    SET sta = 0;
    -- Check whether the department exsit
    SELECT count(*) FROM department WHERE department_id = add_department_id INTO a;
    IF a != 0 THEN
        SET sta = -6;  -- Error code -6: department already exists
	END IF;
    -- Check whether the bank exsit
    SELECT count(*) FROM bank WHERE bank_name = add_bank_name INTO a;
    IF a != 1 THEN
        SET sta = -4;  -- Error code -4: new bank does not exist
    END IF;
    -- Check whether the leader exsit
    SELECT count(*) FROM employee WHERE id = add_leader_id INTO a;
    IF a != 1 THEN
        SET sta = -5;  -- Error code -5: leader does not exist
    END IF;
    -- No problem, insert the new department
    IF sta = 0 THEN
        INSERT INTO department (department_id, bank_name, department_name, leader_id) VALUES (add_department_id, add_bank_name, add_department_name, add_leader_id);
    END IF;
    -- Process errors
    IF s = 0 AND sta = 0 THEN
        SET sta = 1;
        COMMIT;
    ELSE
        IF sta = 0 THEN
            SET sta = -7; -- Error code -7: unknown error within MySQL
        END IF;
        ROLLBACK;
    END IF;
    
END //
delimiter ;


-- A procedure that creates a new employee_department relationship.
DROP PROCEDURE if exists create_employee_department;
delimiter //
CREATE PROCEDURE create_employee_department(IN add_employee_id VARCHAR(50), IN add_department_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE a INT;
    DECLARE continue HANDLER FOR SQLEXCEPTION SET s = 1;
    SET sta = 0;

    START TRANSACTION;
    -- Check whether the employee_department exsit
    SELECT count(*) FROM employee_department WHERE employee_id = add_employee_id AND department_id = add_department_id INTO a;
    IF a != 0 THEN
        SET sta = -3;  -- Error code -3: employee_department already exist
    END IF;
    -- Check whether the department exsit
    SELECT count(*) FROM department WHERE department_id = add_department_id INTO a;
    IF a != 1 THEN
        SET sta = -4;  -- Error code -4: department does not exist
    END IF;
    -- Check whether the employee exsit
    SELECT count(*) FROM employee WHERE id = add_employee_id INTO a;
    IF a != 1 THEN
        SET sta = -2;  -- Error code -2: employee does not exist
    END IF;

    -- No problem, insert the new department
    IF sta = 0 THEN
        INSERT INTO employee_department (employee_id, department_id) VALUES (add_employee_id, add_department_id);
    END IF;

    -- Process errors
    IF s = 0 AND sta = 0 THEN
        SET sta = 1;
        COMMIT;
    ELSE
        IF s = 1 AND sta = 0 THEN
            SET sta = -8; -- Error code -8: unknown error within MySQL
        END IF;
        ROLLBACK;
    END IF;
END //
delimiter ;


-- A procedure that creates a new customer_loan relationship.
DROP PROCEDURE if exists create_customer_loan;
delimiter //
CREATE PROCEDURE create_customer_loan(IN customer_id VARCHAR(50), IN loan_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE s INT DEFAULT 0;
    DECLARE a INT;
    DECLARE continue HANDLER FOR SQLEXCEPTION SET s = 1;

    START TRANSACTION;
    -- Check whether the customer exsit
    SELECT count(*) FROM customer WHERE id = customer_id INTO a;
    IF a != 1 THEN
        SET s = 2;  -- Error code 2: customer does not exist
    END IF;
    -- Check whether the loan exsit
    SELECT count(*) FROM loan WHERE loan_id = loan_id INTO a;
    IF a != 1 THEN
        SET s = 3;  -- Error code 3: loan does not exist
    END IF;

    -- Insert the new customer_loan relationship
    INSERT INTO customer_loan (customer_id, loan_id) VALUES (customer_id, loan_id);

    -- Process errors
    IF s = 0 THEN
        SET sta = 0;
        COMMIT;
    ELSE
        SET sta = -1000;
        ROLLBACK;
    END IF;
END //
delimiter ;






























-- *************** “删” ***************
-- A procedure that deletes a bank.
DROP PROCEDURE if exists delete_bank;
delimiter //
CREATE PROCEDURE delete_bank(IN delete_bank_name VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the bank exsit
    SELECT count(*) FROM bank WHERE bank_name = delete_bank_name INTO a;
    IF a = 1 THEN
        -- -- 删除与该银行有关的所有账户
        -- DELETE FROM account WHERE bank_name = bank_name;
        -- -- 删除与该银行有关的所有贷款
        -- DELETE FROM loan WHERE bank_name = bank_name;
        -- -- 删除该银行的所有部门
        -- DELETE FROM department WHERE bank_name = bank_name;
        -- 再删除该银行
        DELETE FROM bank WHERE bank_name = delete_bank_name;
        SET sta = 1;
    ELSE
        SET sta = -2; -- Error code -2: bank does not exist
    END IF;
END //
delimiter ;


-- A procedure that deletes a customer.
DROP PROCEDURE if exists delete_customer;
delimiter //
CREATE PROCEDURE delete_customer(IN customer_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the customer exsit
    SELECT count(*) FROM customer WHERE id = customer_id INTO a;
    IF a = 1 THEN
        -- -- 删除与该客户有关的所有账户
        -- DELETE FROM account WHERE customer_id = customer_id;
        -- -- 删除与该客户有关的所有贷款
        -- DELETE FROM loan WHERE customer_id = customer_id;
        -- 删除该客户
        DELETE FROM customer WHERE id = customer_id;
        SET sta = 1;
    ELSE
        SET sta = -2; -- Error code -2: customer does not exist
    END IF;
END //
delimiter ;


-- A procedure that deletes an account.
DROP PROCEDURE if exists delete_account;
delimiter //
CREATE PROCEDURE delete_account(IN delete_account_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the account exsit
    SELECT count(*) FROM account WHERE account_id = delete_account_id INTO a;
    IF a = 1 THEN
        -- 删除该账户
        DELETE FROM account WHERE account_id = delete_account_id;
        SET sta = 1;
    ELSE
        SET sta = -2; -- Error code -2: account does not exist
    END IF;
END //
delimiter ;


-- A procedure that deletes a loan.
DROP PROCEDURE if exists delete_loan;
delimiter //
CREATE PROCEDURE delete_loan(IN delete_loan_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the loan exsit
    SELECT count(*) FROM loan WHERE loan_id = delete_loan_id INTO a;
    IF a = 1 THEN
        -- 删除该贷款
        DELETE FROM loan WHERE loan_id = delete_loan_id;
        SET sta = 1;
    ELSE
        SET sta = -2; -- Error code -2: loan does not exist
    END IF;
END //
delimiter ;


-- A procedure that deletes an employee.
DROP PROCEDURE if exists delete_employee;
delimiter //
CREATE PROCEDURE delete_employee(IN del_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the employee exsit
    SELECT count(*) FROM employee WHERE id = del_id INTO a;
    IF a = 1 THEN
        -- 删除该员工
        DELETE FROM employee WHERE id = del_id;
        SET sta = 1;
    ELSE
        SET sta = -2; -- Error code -2: employee does not exist
    END IF;
END //
delimiter ;


-- A procedure that deletes a department.
DROP PROCEDURE if exists delete_department;
delimiter //
CREATE PROCEDURE delete_department(IN delete_department_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;
    SET sta = 0;

    -- Check whether the department exsit
    SELECT count(*) FROM department WHERE department_id = delete_department_id INTO a;
    IF a = 1 THEN
        -- -- 删除与该部门有关的所有员工-部门关系
        -- DELETE FROM employee_department WHERE department_id = delete_department_id;
        -- 删除该部门
        DELETE FROM department WHERE department_id = delete_department_id;
        SET sta = 1;
    ELSE
        IF sta = 0 THEN
            SET sta = -2; -- Error code -2: department does not exist
        END IF;
    END IF;
END //
delimiter ;


-- A procedure that deletes an employee_department relationship.
DROP PROCEDURE if exists delete_employee_department;
delimiter //
CREATE PROCEDURE delete_employee_department(IN delete_employee_id VARCHAR(50), IN delete_department_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the employee_department relationship exsit
    SELECT count(*) FROM employee_department WHERE employee_id = delete_employee_id AND department_id = delete_department_id INTO a;
    IF a = 1 THEN
        -- Check whether the employee is the leader of the department
        SELECT count(*) FROM department WHERE leader_id = delete_employee_id AND department_id = delete_department_id INTO a;
        IF a = 1 THEN
            SET sta = -9; -- Error code -9: The employee is the leader of the department
        ELSE
            -- 删除该员工-部门关系
            DELETE FROM employee_department WHERE employee_id = delete_employee_id AND department_id = delete_department_id;
            SET sta = 1;
        END IF;
    ELSE
        SET sta = -5; -- Error code -5: employee_department does not exist
    END IF;
END //
delimiter ;


-- A procedure that deletes a customer_loan relationship.
DROP PROCEDURE if exists delete_customer_loan;
delimiter //
CREATE PROCEDURE delete_customer_loan(IN customer_id VARCHAR(50), IN loan_id VARCHAR(50), OUT sta INT)
BEGIN
    DECLARE a INT;

    -- Check whether the customer_loan relationship exsit
    SELECT count(*) FROM customer_loan WHERE customer_id = customer_id and loan_id = loan_id INTO a;
    IF a = 1 THEN
        -- 删除该客户-贷款关系
        DELETE FROM customer_loan WHERE customer_id = customer_id and loan_id = loan_id;
        SET sta = 0;
    ELSE
        SET sta = -1000;
    END IF;
END //
delimiter ;



















-- Trigger

-- A trigger that create a new employee_department relationship when a new department is created.
DROP TRIGGER if exists create_employee_department_trigger;
delimiter //
CREATE TRIGGER create_employee_department_trigger
AFTER INSERT ON department
FOR EACH ROW
BEGIN
    INSERT INTO employee_department (employee_id, department_id) VALUES (NEW.leader_id, NEW.department_id);
END //
delimiter ;


-- A trigger that change the employee_department relationships when a department is changed.
DROP TRIGGER if exists change_department_trigger;
delimiter //
CREATE TRIGGER change_department_trigger
AFTER UPDATE ON department
FOR EACH ROW
BEGIN
    UPDATE employee_department SET department_id = NEW.department_id, employee_id = NEW.leader_id WHERE department_id = OLD.department_id;
END //
delimiter ;


-- A fuction that calculate the total asset of a bank
DROP FUNCTION if exists get_bank_asset;
delimiter //
CREATE FUNCTION get_bank_asset(search_bank_name VARCHAR(50))
RETURNS DECIMAL(20, 2)
READS SQL DATA
BEGIN
    DECLARE total_asset DECIMAL(20, 2);
    
    SELECT SUM(balance) INTO total_asset
    FROM account
    WHERE bank_name = search_bank_name;

    RETURN total_asset;
END//
delimiter ;


-- A function to calculate the total balance of a customer
DROP FUNCTION if exists get_total_balance;
delimiter //
CREATE FUNCTION get_total_balance(search_customer_id VARCHAR(50))
RETURNS DECIMAL(20, 2)
READS SQL DATA
BEGIN
    DECLARE total_balance DECIMAL(20, 2);
    SELECT SUM(balance) INTO total_balance
    FROM account
    WHERE customer_id = search_customer_id;
    RETURN total_balance;
END//
delimiter ;