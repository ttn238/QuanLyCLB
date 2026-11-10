using System.Data;
using Microsoft.Data.SqlClient;

namespace QuanlyyCLB.Services;

public class Db
{
    private readonly string _cs;

    // Lấy chuỗi kết nối "DefaultConnection" từ appsettings.json
    public Db(IConfiguration cfg)
    {
        _cs = cfg.GetConnectionString("DefaultConnection")
              ?? throw new InvalidOperationException("Thiếu ConnectionStrings:DefaultConnection trong appsettings.json");
    }

    // Tạo tham số đầu vào; giá trị null được đổi thành NULL của SQL
    public static SqlParameter P(string name, object? value) => new SqlParameter(name, value ?? DBNull.Value);

    // Tạo tham số OUTPUT (dùng với các proc có @MaPhieu OUTPUT, @MaHD OUTPUT...)
    public static SqlParameter Out(string name, SqlDbType type, int size = 0)
    {
        var p = new SqlParameter(name, type) { Direction = ParameterDirection.Output };
        if (size > 0) p.Size = size;
        return p;
    }

    // Chạy câu SQL hoặc proc, trả về DataSet (có thể gồm nhiều bảng kết quả)
    public DataSet Run(string text, bool isProc, params SqlParameter[] ps)
    {
        using var con = new SqlConnection(_cs);
        using var cmd = new SqlCommand(text, con);
        cmd.CommandType = isProc ? CommandType.StoredProcedure : CommandType.Text;
        cmd.Parameters.AddRange(ps);
        var ds = new DataSet();
        using var da = new SqlDataAdapter(cmd);
        da.Fill(ds);
        return ds;
    }

    // Chạy SELECT, lấy bảng kết quả đầu tiên
    public DataTable Table(string sql, params SqlParameter[] ps)
    {
        var ds = Run(sql, false, ps);
        return ds.Tables.Count > 0 ? ds.Tables[0] : new DataTable();
    }

    // Chạy stored procedure, lấy bảng kết quả đầu tiên (nếu proc không trả dữ liệu thì bảng rỗng)
    public DataTable Proc(string name, params SqlParameter[] ps)
    {
        var ds = Run(name, true, ps);
        return ds.Tables.Count > 0 ? ds.Tables[0] : new DataTable();
    }

    // Chạy câu SQL trả về đúng 1 giá trị (COUNT, SCOPE_IDENTITY...)
    public object? Scalar(string sql, params SqlParameter[] ps)
    {
        using var con = new SqlConnection(_cs);
        using var cmd = new SqlCommand(sql, con);
        cmd.Parameters.AddRange(ps);
        con.Open();
        var v = cmd.ExecuteScalar();
        return v is DBNull ? null : v;
    }
}