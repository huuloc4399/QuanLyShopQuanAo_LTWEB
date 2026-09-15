using Microsoft.EntityFrameworkCore;
using QuanLyQuanAoWeb.Models;

namespace QuanLyQuanAoWeb.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public virtual DbSet<Role> Roles { get; set; }
        public virtual DbSet<User> Users { get; set; }
        public virtual DbSet<Category> Categories { get; set; }
        public virtual DbSet<Product> Products { get; set; }
        public virtual DbSet<Size> Sizes { get; set; }
        public virtual DbSet<Color> Colors { get; set; }
        public virtual DbSet<ProductVariant> ProductVariants { get; set; }
        public virtual DbSet<Order> Orders { get; set; }
        public virtual DbSet<OrderDetail> OrderDetails { get; set; }
        public virtual DbSet<Supplier> Suppliers { get; set; }
        public virtual DbSet<ImportReceipt> ImportReceipts { get; set; }
        public virtual DbSet<ImportReceiptDetail> ImportReceiptDetails { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Ràng buộc Unique
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();

            modelBuilder.Entity<Role>()
                .HasIndex(r => r.RoleName)
                .IsUnique();

            modelBuilder.Entity<Size>()
                .HasIndex(s => s.SizeName)
                .IsUnique();

            modelBuilder.Entity<Color>()
                .HasIndex(c => c.ColorName)
                .IsUnique();

            modelBuilder.Entity<ProductVariant>()
                .HasIndex(pv => new { pv.ProductId, pv.SizeId, pv.ColorId })
                .IsUnique();

            modelBuilder.Entity<ProductVariant>()
                .HasIndex(pv => pv.SKU)
                .IsUnique();

            // Computed columns
            modelBuilder.Entity<OrderDetail>()
                .Property(od => od.TotalPrice)
                .HasComputedColumnSql("[Quantity] * [UnitPrice]");

            modelBuilder.Entity<ImportReceiptDetail>()
                .Property(ird => ird.TotalPrice)
                .HasComputedColumnSql("[Quantity] * [ImportPrice]");

            // Quan hệ xóa tầng / Set null
            modelBuilder.Entity<Product>()
                .HasOne(p => p.Category)
                .WithMany(c => c.Products)
                .HasForeignKey(p => p.CategoryId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ProductVariant>()
                .HasOne(pv => pv.Product)
                .WithMany(p => p.Variants)
                .HasForeignKey(pv => pv.ProductId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.User)
                .WithMany(u => u.Orders)
                .HasForeignKey(o => o.UserId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<OrderDetail>()
                .HasOne(od => od.Order)
                .WithMany(o => o.OrderDetails)
                .HasForeignKey(od => od.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ImportReceiptDetail>()
                .HasOne(ird => ird.ImportReceipt)
                .WithMany(ir => ir.Details)
                .HasForeignKey(ird => ird.ImportId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
