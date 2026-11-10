HUONG DAN CHAY DATABASE QUAN LY CLB SINH VIEN

1. Mo run-db.bat bang tai khoan Windows co quyen ket noi SQL Server.
2. Neu SQL Server khong dung instance .\\SQLEXPRESS, sua bien SQLSERVER o dau file.
3. Chuong trinh se yeu cau nhap dung "TAO LAI" vi file 01_createDB.sql XOA database cu cung ten.
4. Chuong trinh chay theo thu tu:
   01_createDB.sql
   02_createtable.sql
   03_constraints.sql
   04_indexes.sql
   07_functions.sql
   05_views.sql
   06_procedures.sql
   08_triggers.sql
   09_seed_data.sql
5. Cuoi qua trinh, script kiem tra so luong bang, function, view, stored procedure,
   trigger va tai khoan mau.

Tai khoan mau:
- admin
- GV001, GV002, GV003
- 2251120011 den 2251120022

Mat khau tat ca tai khoan mau: Demo@123

LUU Y KIEM THU
- Da kiem tra tinh nhat quan cau truc va sua cac diem co the xac minh truc tiep trong bo script.
- File seed duoc bo sung transaction + rollback neu gap loi, tranh nap du lieu dang do.
- Chi muc duy nhat cho phieu muon duoc doi sang khoa tinh toan duy nhat khong can FILTER tren computed column.
- Bo chay co buoc xac nhan ro rang truoc khi xoa database.
- Moi truong thao tac nay khong co SQL Server/sqlcmd de thuc thi database that. Vi vay khong the cam ket da build/chay SQL thanh cong tren may cua ban.
- Neu run-db.bat dung o file nao, gui lai nguyen van thong bao loi va ten SQL Server instance de xu ly dung loi phat sinh.
