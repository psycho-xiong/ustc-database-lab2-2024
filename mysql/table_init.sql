-- 一个银行管理系统，涉及：银行信息、客户信息、账户信息、贷款信息、银行部门信息、员工信息相关实体。
-- 本文件用于创建数据库表
use db_lab2;

SET foreign_key_checks=0;  # 关闭外键检查
DROP TABLE if EXISTS bank, customer, account, loan, department, employee, employee_department;
SET foreign_key_checks=1;  # 开启外键检查

CREATE TABLE bank (
    bank_name VARCHAR(50) PRIMARY KEY,
    bank_addr VARCHAR(100) NOT NULL
);

CREATE TABLE customer (
    id VARCHAR(50) PRIMARY KEY,
    customer_name VARCHAR(50) NOT NULL
);

CREATE TABLE account (
    account_id VARCHAR(50) PRIMARY KEY,
    balance DECIMAL(20, 2) DEFAULT 0.00,
    customer_id VARCHAR(50) NOT NULL,
    bank_name VARCHAR(50) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE,
    FOREIGN KEY (bank_name) REFERENCES bank(bank_name) ON DELETE CASCADE,
    CONSTRAINT CHK_balance CHECK (balance >= 0)
);

CREATE TABLE loan (
    loan_id VARCHAR(50) PRIMARY KEY,
    loan_amount DECIMAL(20, 2) NOT NULL,
    unrepayed_amount DECIMAL(20, 2) NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    bank_name VARCHAR(50) NOT NULL,
    -- statu VARCHAR(50) DEFAULT 'unrepayed' NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE,
    FOREIGN KEY (bank_name) REFERENCES bank(bank_name) ON DELETE CASCADE,
    -- CONSTRAINT CHK_loan_repayed CHECK (loan_amount >= repayed_amount),
    -- CONSTRAINT CHK_repayed_amount CHECK (repayed_amount >= 0),
    CONSTRAINT CHK_loan_amount CHECK (loan_amount >= 0),
    CONSTRAINT CHK_unrepayed_amount CHECK (unrepayed_amount >= 0),
    CONSTRAINT CHK_unrepayed_loan CHECK (unrepayed_amount <= loan_amount)
    -- CONSTRAINT CHK_loan_statu CHECK (statu IN ('unrepayed', 'repayed'))
);

-- CREATE TABLE repay(
--     loan_id VARCHAR(50) PRIMARY KEY,
--     unrepayed_amount DECIMAL(20, 2) NOT NULL,
--     -- repayment_data DATE DEFAULT (curdate()),
--     repayed_amount DECIMAL(20, 2) NOT NULL,
--     FOREIGN KEY (loan_id) REFERENCES loan(loan_id),
--     CONSTRAINT CHK_repayed_amount CHECK (unrepayed_amount >= 0)
-- );

CREATE TABLE employee (
    id VARCHAR(50) PRIMARY KEY,
    employee_name VARCHAR(50) NOT NULL,
    path_to_photo VARCHAR(100)
);

CREATE TABLE department (
    -- department_name VARCHAR(50) PRIMARY KEY,
    -- bank_name VARCHAR(50) PRIMARY KEY,
    department_id VARCHAR(50) PRIMARY KEY,
    bank_name VARCHAR(50) NOT NULL,
    department_name VARCHAR(50) NOT NULL,
    leader_id VARCHAR(50) NOT NULL,
    FOREIGN KEY (bank_name) REFERENCES bank(bank_name) ON DELETE CASCADE,
    FOREIGN KEY (leader_id) REFERENCES employee(id) ON DELETE CASCADE
);

CREATE TABLE employee_department (
    employee_id VARCHAR(50) NOT NULL,
    department_id VARCHAR(50) NOT NULL,
    PRIMARY KEY (employee_id, department_id),
    FOREIGN KEY (employee_id) REFERENCES employee(id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES department(department_id) ON DELETE CASCADE
);

-- CREATE TABLE customer_loan (
--     customer_id VARCHAR(50) NOT NULL,
--     loan_id VARCHAR(50) NOT NULL,
--     PRIMARY KEY (customer_id, loan_id),
--     FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE,
--     FOREIGN KEY (loan_id) REFERENCES loan(loan_id) ON DELETE CASCADE
-- );





-- *************** 以下为触发器、存储过程、函数的创建 ***************

-- -- A function to calculate the total balance of a customer
-- DROP FUNCTION if exists get_total_balance;
-- delimiter //
-- CREATE FUNCTION get_total_balance(customer_id VARCHAR(50))
-- RETURNS DECIMAL(20, 2)
-- READS SQL DATA
-- BEGIN
--     DECLARE total_balance DECIMAL(20, 2);
--     SELECT SUM(balance) INTO total_balance
--     FROM account
--     WHERE customer_id = customer_id;
--     RETURN total_balance;
-- END//
-- delimiter ;

-- -- A fuction that calculate the total asset of a bank
-- DROP FUNCTION if exists get_bank_asset;
-- delimiter //
-- CREATE FUNCTION get_bank_asset(search_bank_name VARCHAR(50))
-- RETURNS DECIMAL(20, 2)
-- READS SQL DATA
-- BEGIN
--     DECLARE total_asset DECIMAL(20, 2);

--     SELECT SUM(balance) INTO total_asset
--     FROM account
--     WHERE bank_name = search_bank_name;

--     RETURN total_asset;
-- END//
-- delimiter ;

-- -- A trigger that change the statu of a loan when the unrepayed_amount is 0
-- DROP TRIGGER if exists change_loan_statu;
-- delimiter //
-- CREATE TRIGGER change_loan_statu
-- AFTER UPDATE ON loan
-- FOR EACH ROW
-- BEGIN
--     IF NEW.unrepayed_amount = 0 THEN
--         UPDATE loan
--         SET statu = 'repayed'
--         WHERE loan_id = NEW.loan_id;
--     END IF;
-- END//
-- delimiter ;

-- -- A trigger that informs the customer when his accounts balance are changed
-- DROP TRIGGER if exists balance_change;
-- delimiter //
-- CREATE TRIGGER balance_change
-- AFTER UPDATE ON account
-- FOR EACH ROW
-- BEGIN
--     INSERT INTO message (customer_id, message_content) VALUES (NEW.customer_id, 'Your account balance is changed from ' + OLD.balance + ' to ' + NEW.balance);
-- END//