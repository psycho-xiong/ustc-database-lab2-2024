# A bank organazation system
from flask import Flask, session, request, redirect, url_for, render_template
from werkzeug.utils import secure_filename
import os

from db import *

app = Flask(__name__)
app.secret_key = 'any random string'

# 设置上传文件的存储路径
UPLOAD_FOLDER = '/Users/psycho/Documents/Database/lab2/static/photos'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


# 主页跳转到登录页面
@app.route('/', methods=['GET', 'POST'])
def login():
    """Log in a registered user by adding the user id to the session."""
    if request.method == 'GET':
        return render_template('login.html')
    else:
        # 连接数据库。如果连接成功，跳转到主页。否则，显示错误信息，停留在登录页面。
        user = request.form['username']
        password = request.form['password']
        conn = db_login(user=user, passward=password)
        if (conn == None) or (user != 'root'):
            return render_template("login.html",status=-1)
        else:
            session['username'] = user
            session['password'] = password
            return redirect(url_for('homepage'))
            
# 主页
@app.route('/homepage', methods=['GET', 'POST'])
def homepage():
    """Display the homepage."""
    if request.method == 'GET':
        return render_template('homepage.html')
    else:
        if 'Customer' in request.form:
            return redirect(url_for('customer'))
        if 'Bank' in request.form:
            return redirect(url_for('bank'))
        if 'Account' in request.form:
            return redirect(url_for('account'))
        if 'Loan' in request.form:
            return redirect(url_for('loan'))
        if 'Employee' in request.form:
            return redirect(url_for('employee'))
        if 'Department' in request.form:
            return redirect(url_for('department'))
        if 'Employee_Department' in request.form:
            return redirect(url_for('employee_department'))
        


@app.route("/homepage/costumer", methods = (["GET", "POST"]))
def customer():
    if request.method == 'GET':
        return render_template('customer.html')
    else:
        # 如果 session 中没有连接，返回登录页面
        if 'username' not in session:
            return redirect(url_for('login'))
        # 如果 session 中有连接，从 session 中获取连接，然后执行后续操作
        username = session['username']
        password = session['password']
        conn = db_login(user=username, passward=password)
        if 'SEARCH' in request.form:
            search_text = request.form['search_text']
            search_type = request.form['search_type'] # [ID, Name]
            res = customer_search(conn, search_text, search_type)
            return render_template('customer.html', search_res=res)
        elif 'ADD' in request.form:
            new_id = request.form['new_id']
            new_name = request.form['new_name']
            res = customer_add(conn, new_id, new_name)
            return render_template('customer.html', add_res=res)
        elif 'DELETE' in request.form:
            delete_id = request.form['delete_id']
            res = customer_delete(conn, delete_id)
            return render_template('customer.html', delete_res=res)
        elif 'UPDATE' in request.form:
            old_id = request.form['old_id']
            new_id = request.form['new_id']
            new_name = request.form['new_name']
            res = customer_update(conn, old_id, new_id, new_name)
            return render_template('customer.html', update_res=res)


@app.route("/homepage/bank", methods = (["GET", "POST"]))
def bank():
    if request.method == 'GET':
        return render_template('bank.html')
    else:
        # 如果 session 中没有连接，返回登录页面
        if 'username' not in session:
            return redirect(url_for('login'))
        # 如果 session 中有连接，从 session 中获取连接，然后执行后续操作
        username = session['username']
        password = session['password']
        conn = db_login(user=username, passward=password)
        if 'SEARCH' in request.form:
            search_text = request.form['search_text']
            search_type = request.form['search_type']
            res = bank_search(conn, search_text, search_type)
            return render_template('bank.html', search_res=res)
        elif 'ADD' in request.form:
            new_name = request.form['new_name']
            new_addr = request.form['new_addr']
            res = bank_add(conn, new_name, new_addr)
            return render_template('bank.html', add_res=res)
        elif 'DELETE' in request.form:
            delete_name = request.form['delete_name']
            res = bank_delete(conn, delete_name)
            return render_template('bank.html', delete_res=res)
        elif 'UPDATE' in request.form:
            old_name = request.form['old_name']
            new_name = request.form['new_name']
            new_addr = request.form['new_addr']
            res = bank_update(conn, old_name, new_name, new_addr)
            return render_template('bank.html', update_res=res)
        
@app.route('/homepage/employee', methods=['GET', 'POST'])
def employee():
    if request.method == 'GET':
        return render_template('employee.html')
    else:
        # 如果 session 中没有连接，返回登录页面
        if 'username' not in session:
            return redirect(url_for('login'))
        # 如果 session 中有连接，从 session 中获取连接，然后执行后续操作
        username = session['username']
        password = session['password']
        conn = db_login(user=username, passward=password)
        if 'SEARCH' in request.form:
            search_text = request.form['search_text']
            search_type = request.form['search_type']
            res = employee_search(conn, search_text, search_type)
            return render_template('employee.html', search_res=res)
        elif 'ADD' in request.form:
            save_flag = True
            add_id = request.form['add_id']
            add_name = request.form['add_name']
            # 检查是否有文件在POST请求中
            if 'add_photo' not in request.files:
                save_flag = False
            file = request.files['add_photo']
            # 如果用户没有选择文件，浏览器也会提交一个没有文件名的空部分
            if file.filename == '':
                save_flag = False
            suffix = file.filename.split('.')[-1]
            add_photo_name = add_id + '.' + suffix
            res = employee_add(conn, add_id, add_name, add_photo_name)
            # 保存文件到指定位置
            if res == 1 and save_flag:
                filename = secure_filename(add_photo_name)
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
            return render_template('employee.html', add_res=res)
            
        elif 'DELETE' in request.form:
            delete_id = request.form['delete_id']
            res = employee_delete(conn, delete_id)
            # 删除文件
            if res == 1:
                # 删除.前是delete_id的文件
                for file in os.listdir(UPLOAD_FOLDER):
                    if file.split('.')[0] == delete_id:
                        os.remove(os.path.join(UPLOAD_FOLDER, file))

            return render_template('employee.html', delete_res=res)
        
        elif 'UPDATE' in request.form:
            save_flag = True
            old_id = request.form['old_id']
            new_id = request.form['new_id']
            new_name = request.form['new_name']
            # 检查是否有文件在POST请求中
            if 'new_photo' not in request.files:
                save_flag = False
                new_photo_name = 'special_token_original'
            file = request.files['new_photo']
            # 如果用户没有选择文件，浏览器也会提交一个没有文件名的空部分
            if file.filename == '':
                save_flag = False
                new_photo_name = 'special_token_original'
            else:
                suffix = file.filename.split('.')[-1]
                new_photo_name = new_id + '.' + suffix
            res = employee_update(conn, old_id, new_id, new_name, new_photo_name)
            # 如果成功，保存文件到指定位置，删除旧的
            if res == 1 and save_flag:
                # 删除旧的文件
                for tmp_file in os.listdir(UPLOAD_FOLDER):
                    if tmp_file.split('.')[0] == old_id:
                        os.remove(os.path.join(UPLOAD_FOLDER, tmp_file))
                # 保存新的文件
                filename = secure_filename(new_photo_name)
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))

            return render_template('employee.html', update_res=res)
        

@app.route('/homepage/department', methods=['GET', 'POST'])
def department():
    if request.method == 'GET':
        return render_template('department.html')
    else:
        # 如果 session 中没有连接，返回登录页面
        if 'username' not in session:
            return redirect(url_for('login'))
        # 如果 session 中有连接，从 session 中获取连接，然后执行后续操作
        username = session['username']
        password = session['password']
        conn = db_login(user=username, passward=password)
        if 'SEARCH' in request.form:
            search_type = request.form['search_type']
            if search_type == 'ID':
                search_DepartmentID = request.form['DepartmentID']
                if search_DepartmentID == '':
                    search_text = ''
                    search_type = ''
                else:
                    search_text = search_DepartmentID
                    search_type = 'DepartmentID'
            else:
                search_Bank = request.form['Bank']
                search_Department = request.form['Department']
                search_LeaderID = request.form['LeaderID']
                if search_Bank=='' and search_Department=='' and search_LeaderID=='':
                    search_text = ''
                    search_type = ''
                elif search_Bank!='' and search_Department=='' and search_LeaderID=='':
                    search_text = search_Bank
                    search_type = 'Bank'
                elif search_Bank=='' and search_Department!='' and search_LeaderID=='':
                    search_text = search_Department
                    search_type = 'Department'
                elif search_Bank=='' and search_Department=='' and search_LeaderID!='':
                    search_text = search_LeaderID
                    search_type = 'Leader'
                elif search_Bank!='' and search_Department!='' and search_LeaderID=='':
                    search_text = [search_Bank, search_Department]
                    search_type = 'Bank_Department'
                elif search_Bank!='' and search_Department=='' and search_LeaderID!='':
                    search_text = [search_Bank, search_LeaderID]
                    search_type = 'Bank_Leader'
                elif search_Bank=='' and search_Department!='' and search_LeaderID!='':
                    search_text = [search_Department, search_LeaderID]
                    search_type = 'Department_Leader'
                elif search_Bank!='' and search_Department!='' and search_LeaderID!='':
                    search_text = [search_Bank, search_Department, search_LeaderID]
                    search_type = 'Bank_Department_Leader'
            res = department_search(conn, search_text, search_type)
            return render_template('department.html', search_res=res)
        elif 'ADD' in request.form:
            add_id = request.form['add_id']
            add_bank = request.form['add_bank']
            add_depart = request.form['add_depart']
            add_leader = request.form['add_leader']
            res = department_add(conn, add_id, add_bank, add_depart, add_leader)
            return render_template('department.html', add_res=res)
        elif 'DELETE' in request.form:
            delete_id = request.form['delete_id']
            res = department_delete(conn, delete_id)
            return render_template('department.html', delete_res=res)
        elif 'UPDATE' in request.form:
            old_id = request.form['old_id']
            new_id = request.form['new_id']
            new_bank = request.form['new_bank']
            new_depart = request.form['new_depart']
            new_leader = request.form['new_leader']
            res = department_update(conn, old_id, new_id, new_bank, new_depart, new_leader)
            return render_template('department.html', update_res=res)
        

@app.route('/homepage/employee_department', methods=['GET', 'POST'])
def employee_department():
    if request.method == 'GET':
        return render_template('employee_department.html')
    else:
        # 如果 session 中没有连接，返回登录页面
        if 'username' not in session:
            return redirect(url_for('login'))
        # 如果 session 中有连接，从 session 中获取连接，然后执行后续操作
        username = session['username']
        password = session['password']
        conn = db_login(user=username, passward=password)
        if 'SEARCH' in request.form:
            search_type = request.form['search_type']
            search_text = request.form['search_text']
            res = employee_department_search(conn, search_text, search_type)
            return render_template('employee_department.html', search_res=res)
        elif 'ADD' in request.form:
            add_employee_id = request.form['add_employee_id']
            add_department_id = request.form['add_department_id']
            res = employee_department_add(conn, add_employee_id, add_department_id)
            return render_template('employee_department.html', add_res=res)
        elif 'DELETE' in request.form:
            delete_employee_id = request.form['delete_employee_id']
            delete_department_id = request.form['delete_department_id']
            res = employee_department_delete(conn, delete_employee_id, delete_department_id)
            return render_template('employee_department.html', delete_res=res)
        elif 'UPDATE' in request.form:
            old_employee_id = request.form['old_employee_id']
            old_department_id = request.form['old_department_id']
            new_employee_id = request.form['new_employee_id']
            new_department_id = request.form['new_department_id']
            res = employee_department_update(conn, old_employee_id, old_department_id, new_employee_id, new_department_id)
            return render_template('employee_department.html', update_res=res)
            

@app.route('/homepage/account', methods=['GET', 'POST'])
def account():
    if request.method == 'GET':
        return render_template('account.html')
    else:
        # 如果 session 中没有连接，返回登录页面
        if 'username' not in session:
            return redirect(url_for('login'))
        # 如果 session 中有连接，从 session 中获取连接，然后执行后续操作
        username = session['username']
        password = session['password']
        conn = db_login(user=username, passward=password)
        if 'SEARCH' in request.form:
            search_type = request.form['search_type']
            if search_type == 'ID':
                search_AccountID = request.form['AccountID']
                if search_AccountID == '':
                    search_text = ''
                    search_type = ''
                else:
                    search_text = search_AccountID
                    search_type = 'AccountID'
            else:
                search_CustomerID = request.form['CustomerID']
                search_BankName = request.form['BankName']
                if search_CustomerID=='' and search_BankName=='':
                    search_text = ''
                    search_type = ''
                elif search_CustomerID!='' and search_BankName=='':
                    search_text = search_CustomerID
                    search_type = 'CustomerID'
                elif search_CustomerID=='' and search_BankName!='':
                    search_text = search_BankName
                    search_type = 'BankName'
                elif search_CustomerID!='' and search_BankName!='':
                    search_text = [search_CustomerID, search_BankName]
                    search_type = 'CustomerID_BankName'
            res = account_search(conn, search_text, search_type)
            return render_template('account.html', search_res=res)
        elif 'ADD' in request.form:
            add_account_id = request.form['add_account_id']
            add_customer_id = request.form['add_customer_id']
            add_bank_name = request.form['add_bank_name']
            res = account_add(conn, add_account_id, add_customer_id, add_bank_name)
            return render_template('account.html', add_res=res)
        elif 'DELETE' in request.form:
            delete_account_id = request.form['delete_account_id']
            res = account_delete(conn, delete_account_id)
            return render_template('account.html', delete_res=res)
        elif 'UPDATE' in request.form:
            old_account_id = request.form['old_account_id']
            new_account_id = request.form['new_account_id']
            new_balance = request.form['new_balance']
            new_customer_id = request.form['new_customer_id']
            new_bank_name = request.form['new_bank_name']
            res = account_update(conn, old_account_id, new_account_id, new_balance, new_customer_id, new_bank_name)
            return render_template('account.html', update_res=res)
        elif 'TRANSFER' in request.form:
            from_id = request.form['from_id']
            to_id = request.form['to_id']
            amount = request.form['amount']
            res = account_transfer(conn, from_id, to_id, amount)
            return render_template('account.html', transfer_res=res)
        

@app.route('/homepage/loan', methods=['GET', 'POST'])
def loan():
    if request.method == 'GET':
        return render_template('loan.html')
    else:
        # 如果 session 中没有连接，返回登录页面
        if 'username' not in session:
            return redirect(url_for('login'))
        # 如果 session 中有连接，从 session 中获取连接，然后执行后续操作
        username = session['username']
        password = session['password']
        conn = db_login(user=username, passward=password)
        if 'SEARCH' in request.form:
            search_type = request.form['search_type']
            if search_type == 'ID':
                search_LoanID = request.form['LoanID']
                if search_LoanID == '':
                    search_text = ''
                    search_type = ''
                else:
                    search_text = search_LoanID
                    search_type = 'LoanID'
            else:
                search_CustomerID = request.form['CustomerID']
                search_BankName = request.form['BankName']
                if search_CustomerID=='' and search_BankName=='':
                    search_text = ''
                    search_type = ''
                elif search_CustomerID!='' and search_BankName=='':
                    search_text = search_CustomerID
                    search_type = 'CustomerID'
                elif search_CustomerID=='' and search_BankName!='':
                    search_text = search_BankName
                    search_type = 'BankName'
                elif search_CustomerID!='' and search_BankName!='':
                    search_text = [search_CustomerID, search_BankName]
                    search_type = 'CustomerID_BankName'
            res = loan_search(conn, search_text, search_type)
            return render_template('loan.html', search_res=res)
        elif 'ADD' in request.form:
            add_loan_id = request.form['add_loan_id']
            add_loan_amount = request.form['add_loan_amount']
            add_customer_id = request.form['add_customer_id']
            add_bank_name = request.form['add_bank_name']
            res = loan_add(conn, add_loan_id, add_loan_amount, add_customer_id, add_bank_name)
            return render_template('loan.html', add_res=res)
        elif 'DELETE' in request.form:
            delete_loan_id = request.form['delete_loan_id']
            res = loan_delete(conn, delete_loan_id)
            return render_template('loan.html', delete_res=res)
        elif 'UPDATE' in request.form:
            old_loan_id = request.form['old_loan_id']
            new_loan_id = request.form['new_loan_id']
            new_loan_amount = request.form['new_loan_amount']
            new_unrepayed_amount = request.form['new_unrepayed_amount']
            new_customer_id = request.form['new_customer_id']
            new_bank_name = request.form['new_bank_name']
            res = loan_update(conn, old_loan_id, new_loan_id, new_loan_amount, new_unrepayed_amount, new_customer_id, new_bank_name)
            return render_template('loan.html', update_res=res)
        elif 'REPAY' in request.form:
            repay_loan_id = request.form['repay_loan_id']
            repay_account_id = request.form['repay_account_id']
            repay_amount = request.form['repay_amount']
            res = loan_repay(conn, repay_loan_id, repay_account_id, repay_amount)
            return render_template('loan.html', repay_res=res)




if __name__ == "__main__":
    app.run(host = "127.0.0.1", debug=True)


    