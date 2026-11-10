@echo off
setlocal EnableExtensions

REM Sua SQLSERVER cho dung instance tren may ban, vi du: .\\SQLEXPRESS hoac TENMAY\\SQLEXPRESS.
set "SQLSERVER=.\SQLEXPRESS"
set "DBDIR=%~dp0"

where sqlcmd >nul 2>nul
if errorlevel 1 (
    echo LOI: Khong tim thay sqlcmd. Hay cai SQL Server Command Line Utilities hoac chay tung file bang SSMS.
    exit /b 1
)

echo ============================================================
echo CANH BAO: Qua trinh nay se XOA va tao lai database QuanLyCLBSinhVien.
echo TOAN BO du lieu cu trong database cung ten se bi mat.
echo Hay sao luu database truoc khi tiep tuc.
echo SQL Server instance: %SQLSERVER%
echo ============================================================
set /p "CONFIRM=Nhap TAO LAI de tiep tuc: "
if /I not "%CONFIRM%"=="TAO LAI" (
    echo Da huy. Database khong bi thay doi.
    exit /b 0
)

for %%F in (01_createDB.sql 02_createtable.sql 03_constraints.sql 04_indexes.sql 07_functions.sql 05_views.sql 06_procedures.sql 08_triggers.sql 09_seed_data.sql) do (
    echo.
    echo Dang chay %%F ...
    sqlcmd -S "%SQLSERVER%" -E -b -r 1 -f 65001 -i "%DBDIR%%%F"
    if errorlevel 1 (
        echo LOI tai %%F. Dung lai, khong chay cac file tiep theo.
        exit /b 1
    )
)

echo.
echo Dang kiem tra doi tuong sau khi tao...
sqlcmd -S "%SQLSERVER%" -E -b -r 1 -Q "USE QuanLyCLBSinhVien; IF (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0) <> 19 THROW 51001, N'So luong bang khong dung 19.', 1; IF (SELECT COUNT(*) FROM sys.objects WHERE type IN ('FN','IF','TF') AND is_ms_shipped = 0) <> 7 THROW 51006, N'So luong function khong dung 7.', 1; IF (SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped = 0) <> 10 THROW 51002, N'So luong view khong dung 10.', 1; IF (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0) <> 32 THROW 51003, N'So luong stored procedure khong dung 32.', 1; IF (SELECT COUNT(*) FROM sys.triggers WHERE parent_class = 1 AND is_ms_shipped = 0) <> 5 THROW 51004, N'So luong trigger khong dung 5.', 1; IF (SELECT COUNT(*) FROM TaiKhoan) <> 16 THROW 51005, N'So tai khoan mau khong dung 16.', 1; PRINT N'Kiem tra cau truc va du lieu mau: DAT.'"
if errorlevel 1 (
    echo LOI: Kiem tra sau khi tao that bai.
    exit /b 1
)

echo.
echo HOAN TAT. Tat ca tai khoan mau co mat khau: Demo@123
exit /b 0
