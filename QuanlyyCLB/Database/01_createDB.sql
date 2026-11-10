USE master;
GO

-- Chỉ xóa/tạo lại database QuanLyCLBSinhVien; thao tác này sẽ xóa và tạo lại database cùng tên nếu đã tồn tại.
IF DB_ID(N'QuanLyCLBSinhVien') IS NOT NULL
BEGIN
    ALTER DATABASE QuanLyCLBSinhVien SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyCLBSinhVien;
END;
GO

CREATE DATABASE QuanLyCLBSinhVien COLLATE Vietnamese_CI_AS;
GO

ALTER DATABASE QuanLyCLBSinhVien SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
GO

PRINT N'Đã tạo database QuanLyCLBSinhVien.';
GO
