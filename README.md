# Quản lý CLB sinh viên (ASP.NET Core MVC + SQL Server)

## Cài đặt
1. Chạy lần lượt trong SQL Server (SSMS): `QuanlyyCLB/Database/01_createDB.sql` đến `09_seed_data.sql`.
2. Sửa chuỗi kết nối `DefaultConnection` trong `QuanlyyCLB/appsettings.json` (không đưa file này lên GitHub nếu có mật khẩu thật).
3. Chạy: `dotnet run` trong thư mục `QuanlyyCLB/QuanlyyCLB`.

Mật khẩu mọi tài khoản mẫu: `Demo@123` (tên đăng nhập là MSSV, ví dụ 2251120001 = Chủ nhiệm; gv001 = giảng viên).

## Chức năng
Đăng nhập và phân quyền, thành viên, hoạt động (đề xuất, duyệt, đăng ký, điểm danh bằng mã, tổng kết/kết thúc),
lịch sử tham gia, tuyển thành viên, thu chi và quyền xem chi tiết, ngân sách (duyệt, xin nhà trường, ghi kết quả),
tài sản (mượn, duyệt, giao, trả, trễ hạn), thông báo, báo cáo cuối kỳ.
Mọi form POST đều có chống CSRF (AutoValidateAntiforgeryToken).
