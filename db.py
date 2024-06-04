# import pymysql
# from pymysql.err import OperationalError
from mysql.connector import MySQLConnection, Error


def db_login(host='127.0.0.1', port=3306, user=None, passward=None, database='db_lab2', charset='utf8'):
    try:
        conn = MySQLConnection(
            host=host,
            port=port,
            user=user,
            passwd=passward,
            db=database,
            charset=charset
        )
        return conn
    except Error as e:
        print('Error: ', e)
        return None
    
def num_check_trans(num: str) -> tuple:
    flag = -1

    # 检查是否为空
    if num == '':
        flag = -10 # Error code -10: not a number
        return (None,flag)
    # 移除所有的空格
    num = num.replace(' ','')
    # 检查是否为负数
    if num[0] == '-':
        flag = -11 # Error code -11: negative number
        return (None, flag)
    for i in num:
        if not i.isdigit() and i != '.':
            flag = -10  # Error code -10: not a number
            return (None,flag)
    # 检查是否为小数
    if '.' in num:
        num = num.split('.')
        if len(num[1]) > 2:
            flag = -7 # Error code -7: decimal part too long
            return (None,flag)
        if len(num[0] + num[1]) > 20:
            flag = -8 # Error code -8: total length too long
            return (None,flag)
        # 遍历检查是否全为数字
        for i in num[0] + num[1]:
            if not i.isdigit() and i != '.':
                flag = -10 # Error code -10: not a number
                return (None,flag)
    else:
        if len(num) > 20:
            flag = -8 # Error code -8: total length too long
            return (None,flag)
        for i in num:
            if not i.isdigit() and i != '.':
                flag = -10 # Error code -10: not a number
                return (None,flag)
    # 转换为数字
    num = float(num)
    flag = 1
    return (num,flag)
    






# ************** Customer **************
def customer_search(conn: MySQLConnection, search_text: str, search_type: str) -> list:
    cursor = conn.cursor()
    if search_text == '':
        cursor.execute("SELECT * FROM customer")
    else:
        if search_type == 'ID':
            cursor.execute(f"SELECT * FROM customer WHERE id = '{search_text}'")
        elif search_type == 'Name':
            cursor.execute(f"SELECT * FROM customer WHERE customer_name = '{search_text}'")
    res = cursor.fetchall()
    for i in range(len(res)):
        cursor.execute(f"SELECT get_total_balance('{res[i][0]}')")
        res[i] = res[i] + cursor.fetchall()[0]
    cursor.close()
    return res

def customer_add(conn: MySQLConnection, add_id: str, add_name: str) -> int:
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('create_customer', (add_id, add_name, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def customer_delete(conn: MySQLConnection, delete_id: str) -> int:
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('delete_customer', (delete_id, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def customer_update(conn: MySQLConnection, old_id: str, new_id: str, new_name: str) -> int:
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('change_customer', (old_id, new_id, new_name, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    






# ************** Bank **************
def bank_search(conn: MySQLConnection, search_text: str, search_type: str) -> list:
    cursor = conn.cursor()
    if search_text == '':
        cursor.execute("SELECT * FROM bank")
    else: 
        if search_type == 'Name':
            cursor.execute(f"SELECT * FROM bank WHERE bank_name = '{search_text}'")
        elif search_type == 'Address':
            cursor.execute(f"SELECT * FROM bank WHERE bank_addr = '{search_text}'")
    res = cursor.fetchall()
    # 对每个结果中的银行名，调用FUNCTION get_bank_asset(bank_name VARCHAR(50))计算其资产
    for i in range(len(res)):
        cursor.execute(f"SELECT get_bank_asset('{res[i][0]}')")
        res[i] = res[i] + cursor.fetchall()[0]
    cursor.close()
    return res

def bank_add(conn, add_name, add_addr):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('create_bank', (add_name, add_addr, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def bank_delete(conn, delete_name):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('delete_bank', (delete_name, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def bank_update(conn, old_name, new_name, new_addr):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('change_bank', (old_name, new_name, new_addr, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
        






# ************** Employee **************
def employee_search(conn, search_text, search_type):
    cursor = conn.cursor()
    if search_text == '':
        cursor.execute("SELECT * FROM employee")
    else:
        if search_type == 'ID':
            cursor.execute(f"SELECT * FROM employee WHERE id = '{search_text}'")
        elif search_type == 'Name':
            cursor.execute(f"SELECT * FROM employee WHERE employee_name = '{search_text}'")
    res = cursor.fetchall()
    cursor.close()
    return res

def employee_add(conn, add_id, add_name, add_path):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('create_employee', (add_id, add_name, add_path, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1

def employee_delete(conn, delete_id):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('delete_employee', (delete_id, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def employee_update(conn, old_id, new_id, new_name, new_path):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('change_employee', (old_id, new_id, new_name, new_path, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
        






# ************** Department **************
def department_search(conn, search_text, search_type):
    cursor = conn.cursor()
    if search_text == '':
        cursor.execute("SELECT * FROM department")
    else:
        if search_type == 'DepartmentID':
            cursor.execute(f"SELECT * FROM department WHERE department_id = '{search_text}'")
        elif search_type == 'Bank':
            cursor.execute(f"SELECT * FROM department WHERE bank_name = '{search_text}'")
        elif search_type == 'Department':
            cursor.execute(f"SELECT * FROM department WHERE department_name = '{search_text}'")
        elif search_type == 'Leader':
            cursor.execute(f"SELECT * FROM department WHERE leader_id = '{search_text}'")
        elif search_type == 'Bank_Department':
            cursor.execute(f"SELECT * FROM department WHERE bank_name = '{search_text[0]}' AND department_name = '{search_text[1]}'")
        elif search_type == 'Bank_Leader':
            cursor.execute(f"SELECT * FROM department WHERE bank_name = '{search_text[0]}' AND leader_id = '{search_text[1]}'")
        elif search_type == 'Department_Leader':
            cursor.execute(f"SELECT * FROM department WHERE department_name = '{search_text[0]}' AND leader_id = '{search_text[1]}'")
        elif search_type == 'Bank_Department_Leader':
            cursor.execute(f"SELECT * FROM department WHERE bank_name = '{search_text[0]}' AND department_name = '{search_text[1]}' AND leader_id = '{search_text[2]}'")
    res = cursor.fetchall()
    cursor.close()
    return res

def department_add(conn, add_id, add_bank, add_depart, add_leader):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('create_department', (add_id, add_bank, add_depart, add_leader, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def department_delete(conn, delete_id):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('delete_department', (delete_id, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def department_update(conn, old_id, new_id, new_bank, new_department, new_leader):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('change_department', (old_id, new_id, new_bank, new_department, new_leader, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
            











# ************** Employee_Department **************
def employee_department_search(conn, search_text, search_type):
    cursor = conn.cursor()
    if search_text == '':
        cursor.execute("SELECT * FROM employee_department")
    else:
        if search_type == 'Employee':
            cursor.execute(f"SELECT * FROM employee_department WHERE employee_id = '{search_text}'")
        elif search_type == 'Department':
            cursor.execute(f"SELECT * FROM employee_department WHERE department_id = '{search_text}'")  
    res = cursor.fetchall()
    cursor.close()
    return res

def employee_department_add(conn, add_employee_id, add_department_id):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('create_employee_department', (add_employee_id, add_department_id, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def employee_department_delete(conn, delete_employee_id, delete_department_id):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('delete_employee_department', (delete_employee_id, delete_department_id, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def employee_department_update(conn, old_employee_id, old_department_id, new_employee_id, new_department_id):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('change_employee_department', (old_employee_id, old_department_id, new_employee_id, new_department_id, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
                










# ************** Account **************
def account_search(conn, search_text, search_type):
    cursor = conn.cursor()
    if search_text == '':
        cursor.execute("SELECT * FROM account")
    else:
        if search_type == 'AccountID':
            cursor.execute(f"SELECT * FROM account WHERE account_id = '{search_text}'")
        elif search_type == 'CustomerID':
            cursor.execute(f"SELECT * FROM account WHERE customer_id = '{search_text}'")
        elif search_type == 'BankName':
            cursor.execute(f"SELECT * FROM account WHERE bank_name = '{search_text}'")
        elif search_type == 'CustomerID_BankName':
            cursor.execute(f"SELECT * FROM account WHERE customer_id = '{search_text[0]}' AND bank_name = '{search_text[1]}'")
    res = cursor.fetchall()
    cursor.close()
    return res

def account_add(conn, add_account_id, add_customer_id, add_bank_name):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('create_account', (add_account_id, add_customer_id, add_bank_name, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def account_delete(conn, delete_account_id):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('delete_account', (delete_account_id, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def account_update(conn, old_account_id, new_account_id, new_balance, new_customer_id, new_bank_name):
    cursor = conn.cursor()
    sta = -1
    try:
        (new_balance, flag) = num_check_trans(new_balance)
        if flag != 1:
            return flag
        sta = cursor.callproc('change_account', (old_account_id, new_account_id, new_balance, new_customer_id, new_bank_name, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def account_transfer(conn, from_id, to_id, amount):
    cursor = conn.cursor()
    sta = -1
    if from_id == to_id:
        return -12
    try:
        (amount, flag) = num_check_trans(amount)
        if flag != 1:
            return flag
        sta = cursor.callproc('transfer_money', (from_id, to_id, amount, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
                










# ************** Loan **************
def loan_search(conn, search_text, search_type):
    cursor = conn.cursor()
    if search_text == '':
        cursor.execute("SELECT * FROM loan")
    else:
        if search_type == 'LoanID':
            cursor.execute(f"SELECT * FROM loan WHERE loan_id = '{search_text}'")
        elif search_type == 'CustomerID':
            cursor.execute(f"SELECT * FROM loan WHERE customer_id = '{search_text}'")
        elif search_type == 'BankName':
            cursor.execute(f"SELECT * FROM loan WHERE bank_name = '{search_text}'")
        elif search_type == 'CustomerID_BankName':
            cursor.execute(f"SELECT * FROM loan WHERE customer_id = '{search_text[0]}' AND bank_name = '{search_text[1]}'")
    res = cursor.fetchall()
    cursor.close()
    return res

def loan_add(conn, add_loan_id, add_loan_amount, add_customer_id, add_bank_name):
    cursor = conn.cursor()
    sta = -1
    try:
        (add_loan_amount, flag) = num_check_trans(add_loan_amount)
        if flag != 1:
            return flag
        sta = cursor.callproc('create_loan', (add_loan_id, add_loan_amount, add_customer_id, add_bank_name, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def loan_delete(conn, delete_loan_id):
    cursor = conn.cursor()
    sta = -1
    try:
        sta = cursor.callproc('delete_loan', (delete_loan_id, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def loan_update(conn, old_loan_id, new_loan_id, new_loan_amount, new_unrepayed_amount, new_customer_id, new_bank_name):
    cursor = conn.cursor()
    sta = -1
    try:
        (new_loan_amount, flag) = num_check_trans(new_loan_amount)
        if flag != 1:
            return flag
        (new_unrepayed_amount, flag) = num_check_trans(new_unrepayed_amount)
        if flag != 1:
            return flag
        if new_loan_amount <= 0:
            return -12 # Error code -12: loan amount less than or equal to 0
        if new_unrepayed_amount > new_loan_amount:
            return -14 # Error code -14: unrepayed amount exceeds loan amount
        sta = cursor.callproc('change_loan', (old_loan_id, new_loan_id, new_loan_amount, new_unrepayed_amount, new_customer_id, new_bank_name, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
    
def loan_repay(conn, repay_loan_id, repay_account_id, repay_amount):
    cursor = conn.cursor()
    sta = -1
    try:
        (repay_amount, flag) = num_check_trans(repay_amount)
        if flag != 1:
            return flag
        if repay_amount <= 0:
            return -13 # Error code -13: repay amount less than or equal to 0
        sta = cursor.callproc('repay_loan', (repay_loan_id, repay_account_id, repay_amount, sta))[-1]
        conn.commit()
        cursor.close()
        return sta
    except:
        conn.rollback()
        cursor.close()
        return -1
        