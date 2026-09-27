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

        // 19 bảng hiện hữu
        public virtual DbSet<Role> Roles { get; set; }
        public virtual DbSet<Permission> Permissions { get; set; }
        public virtual DbSet<RolePermission> RolePermissions { get; set; }
        public virtual DbSet<User> Users { get; set; }
        public virtual DbSet<CustomerAddress> CustomerAddresses { get; set; }
        public virtual DbSet<Category> Categories { get; set; }
        public virtual DbSet<Product> Products { get; set; }
        public virtual DbSet<Size> Sizes { get; set; }
        public virtual DbSet<Color> Colors { get; set; }
        public virtual DbSet<ProductVariant> ProductVariants { get; set; }
        public virtual DbSet<Coupon> Coupons { get; set; }
        public virtual DbSet<Order> Orders { get; set; }
        public virtual DbSet<OrderDetail> OrderDetails { get; set; }
        public virtual DbSet<Cart> Carts { get; set; }
        public virtual DbSet<CartItem> CartItems { get; set; }
        public virtual DbSet<ProductReview> ProductReviews { get; set; }
        public virtual DbSet<Supplier> Suppliers { get; set; }
        public virtual DbSet<ImportReceipt> ImportReceipts { get; set; }
        public virtual DbSet<ImportReceiptDetail> ImportReceiptDetails { get; set; }

        // 10 bảng bổ sung theo bosung.md
        public virtual DbSet<UserRole> UserRoles { get; set; }
        public virtual DbSet<ProductImage> ProductImages { get; set; }
        public virtual DbSet<InventoryTransaction> InventoryTransactions { get; set; }
        public virtual DbSet<InventoryReservation> InventoryReservations { get; set; }
        public virtual DbSet<CouponUsage> CouponUsages { get; set; }
        public virtual DbSet<Payment> Payments { get; set; }
        public virtual DbSet<OrderStatusHistory> OrderStatusHistories { get; set; }
        public virtual DbSet<Return> Returns { get; set; }
        public virtual DbSet<ReturnItem> ReturnItems { get; set; }
        public virtual DbSet<Shipment> Shipments { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // ================= 1. KHÓA CHÍNH GHÉP (COMPOSITE KEYS) =================
            modelBuilder.Entity<RolePermission>()
                .HasIndex(rp => new { rp.RoleId, rp.PermissionId })
                .IsUnique();

            modelBuilder.Entity<UserRole>()
                .HasKey(ur => new { ur.UserId, ur.RoleId });

            // ================= 2. RÀNG BUỘC UNIQUE & FILTERED INDEXES =================
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique()
                .HasFilter("[Email] IS NOT NULL");

            modelBuilder.Entity<Role>()
                .HasIndex(r => r.RoleName)
                .IsUnique();

            modelBuilder.Entity<Permission>()
                .HasIndex(p => p.PermissionCode)
                .IsUnique();

            modelBuilder.Entity<Category>()
                .HasIndex(c => c.Slug)
                .IsUnique()
                .HasFilter("[Slug] IS NOT NULL");

            modelBuilder.Entity<Product>()
                .HasIndex(p => p.ProductCode)
                .IsUnique()
                .HasFilter("[ProductCode] IS NOT NULL");

            modelBuilder.Entity<Size>()
                .HasIndex(s => s.SizeName)
                .IsUnique();

            modelBuilder.Entity<Color>()
                .HasIndex(c => c.ColorName)
                .IsUnique();

            modelBuilder.Entity<Coupon>()
                .HasIndex(cp => cp.CouponCode)
                .IsUnique();

            modelBuilder.Entity<ProductVariant>()
                .HasIndex(pv => new { pv.ProductId, pv.SizeId, pv.ColorId })
                .IsUnique();

            modelBuilder.Entity<ProductVariant>()
                .HasIndex(pv => pv.SKU)
                .IsUnique()
                .HasFilter("[SKU] IS NOT NULL");

            modelBuilder.Entity<CartItem>()
                .HasIndex(ci => new { ci.CartId, ci.VariantId })
                .IsUnique();

            modelBuilder.Entity<CustomerAddress>()
                .HasIndex(ca => ca.UserId)
                .IsUnique()
                .HasFilter("[IsDefault] = 1");

            modelBuilder.Entity<Order>()
                .HasIndex(o => o.OrderCode)
                .IsUnique();

            modelBuilder.Entity<OrderDetail>()
                .HasIndex(od => new { od.OrderId, od.VariantId })
                .IsUnique();

            modelBuilder.Entity<ImportReceipt>()
                .HasIndex(ir => ir.ImportCode)
                .IsUnique()
                .HasFilter("[ImportCode] IS NOT NULL");

            modelBuilder.Entity<ImportReceiptDetail>()
                .HasIndex(ird => new { ird.ImportId, ird.VariantId })
                .IsUnique();

            modelBuilder.Entity<InventoryReservation>()
                .HasIndex(ir => new { ir.OrderId, ir.VariantId })
                .IsUnique();

            modelBuilder.Entity<CouponUsage>()
                .HasIndex(cu => cu.OrderId)
                .IsUnique();

            modelBuilder.Entity<Payment>()
                .HasIndex(p => p.IdempotencyKey)
                .IsUnique();

            modelBuilder.Entity<InventoryTransaction>()
                .HasIndex(it => it.IdempotencyKey)
                .IsUnique();

            modelBuilder.Entity<Return>()
                .HasIndex(r => r.ReturnCode)
                .IsUnique();

            modelBuilder.Entity<Supplier>()
                .HasIndex(s => s.SupplierCode)
                .IsUnique()
                .HasFilter("[SupplierCode] IS NOT NULL");

            // ================= 3. COMPUTED COLUMNS =================
            modelBuilder.Entity<OrderDetail>()
                .Property(od => od.TotalPrice)
                .HasComputedColumnSql("[Quantity] * [UnitPrice]");

            modelBuilder.Entity<ImportReceiptDetail>()
                .Property(ird => ird.TotalPrice)
                .HasComputedColumnSql("[Quantity] * [ImportPrice]");

            // ================= 4. QUAN HỆ KHÓA NGOẠI & CASCADE/RESTRICT =================
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

            // User & Addresses
            modelBuilder.Entity<CustomerAddress>()
                .HasOne(ca => ca.User)
                .WithMany(u => u.Addresses)
                .HasForeignKey(ca => ca.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // User & Carts
            modelBuilder.Entity<Cart>()
                .HasOne(c => c.User)
                .WithMany(u => u.Carts)
                .HasForeignKey(c => c.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<CartItem>()
                .HasOne(ci => ci.Cart)
                .WithMany(c => c.CartItems)
                .HasForeignKey(ci => ci.CartId)
                .OnDelete(DeleteBehavior.Cascade);

            // Orders relationships
            modelBuilder.Entity<Order>()
                .HasOne(o => o.User)
                .WithMany(u => u.Orders)
                .HasForeignKey(o => o.UserId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.ApprovedByUser)
                .WithMany()
                .HasForeignKey(o => o.ApprovedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.CancelledByUser)
                .WithMany()
                .HasForeignKey(o => o.CancelledByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.Coupon)
                .WithMany(cp => cp.Orders)
                .HasForeignKey(o => o.CouponId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<OrderDetail>()
                .HasOne(od => od.Order)
                .WithMany(o => o.OrderDetails)
                .HasForeignKey(od => od.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            // Import Receipts
            modelBuilder.Entity<ImportReceipt>()
                .HasOne(ir => ir.User)
                .WithMany()
                .HasForeignKey(ir => ir.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ImportReceipt>()
                .HasOne(ir => ir.PostedByUser)
                .WithMany()
                .HasForeignKey(ir => ir.PostedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ImportReceiptDetail>()
                .HasOne(ird => ird.ImportReceipt)
                .WithMany(ir => ir.Details)
                .HasForeignKey(ird => ird.ImportId)
                .OnDelete(DeleteBehavior.Cascade);

            // User Roles
            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.User)
                .WithMany(u => u.UserRoles)
                .HasForeignKey(ur => ur.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.AssignedByUser)
                .WithMany()
                .HasForeignKey(ur => ur.AssignedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.Role)
                .WithMany(r => r.UserRoles)
                .HasForeignKey(ur => ur.RoleId)
                .OnDelete(DeleteBehavior.Cascade);

            // Product Reviews
            modelBuilder.Entity<ProductReview>()
                .HasOne(pr => pr.User)
                .WithMany(u => u.Reviews)
                .HasForeignKey(pr => pr.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ProductReview>()
                .HasOne(pr => pr.ApprovedByUser)
                .WithMany()
                .HasForeignKey(pr => pr.ApprovedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            // Returns
            modelBuilder.Entity<Return>()
                .HasOne(r => r.User)
                .WithMany(u => u.Returns)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<Return>()
                .HasOne(r => r.ApprovedByUser)
                .WithMany()
                .HasForeignKey(r => r.ApprovedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ReturnItem>()
                .HasOne(ri => ri.Return)
                .WithMany(r => r.ReturnItems)
                .HasForeignKey(ri => ri.ReturnId)
                .OnDelete(DeleteBehavior.Cascade);

            // Payments, Reservations, Histories, Shipments
            modelBuilder.Entity<Payment>()
                .HasOne(p => p.Order)
                .WithMany(o => o.Payments)
                .HasForeignKey(p => p.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<InventoryReservation>()
                .HasOne(ir => ir.Order)
                .WithMany(o => o.Reservations)
                .HasForeignKey(ir => ir.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<OrderStatusHistory>()
                .HasOne(osh => osh.Order)
                .WithMany(o => o.StatusHistories)
                .HasForeignKey(osh => osh.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<OrderStatusHistory>()
                .HasOne(osh => osh.ChangedByUser)
                .WithMany()
                .HasForeignKey(osh => osh.ChangedByUserId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<InventoryTransaction>()
                .HasOne(it => it.CreatedByUser)
                .WithMany()
                .HasForeignKey(it => it.CreatedByUserId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<CouponUsage>()
                .HasOne(cu => cu.User)
                .WithMany(u => u.CouponUsages)
                .HasForeignKey(cu => cu.UserId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<Shipment>()
                .HasOne(s => s.Order)
                .WithMany(o => o.Shipments)
                .HasForeignKey(s => s.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ProductImage>()
                .HasOne(pi => pi.Product)
                .WithMany(p => p.Images)
                .HasForeignKey(pi => pi.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
