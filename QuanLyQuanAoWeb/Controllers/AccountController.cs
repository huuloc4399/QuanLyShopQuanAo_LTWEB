using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyQuanAoWeb.Data;
using QuanLyQuanAoWeb.Models;
using QuanLyQuanAoWeb.Models.ViewModels;
using System.Security.Claims;

namespace QuanLyQuanAoWeb.Controllers
{
    public class AccountController : Controller
    {
        private readonly ApplicationDbContext _context;

        public AccountController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: /Account/Login
        [HttpGet]
        public IActionResult Login(string? returnUrl = null)
        {
            if (User.Identity?.IsAuthenticated == true)
            {
                if (User.IsInRole("Admin") || User.IsInRole("Staff"))
                {
                    return RedirectToAction("Index", "Dashboard", new { area = "Admin" });
                }
                return RedirectToAction("Index", "Home");
            }

            ViewData["ReturnUrl"] = returnUrl;
            return View(new LoginViewModel { ReturnUrl = returnUrl });
        }

        // POST: /Account/Login
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(LoginViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var user = await _context.Users
                .Include(u => u.Role)
                .FirstOrDefaultAsync(u => u.Username == model.Username && u.PasswordHash == model.Password);

            if (user == null)
            {
                ModelState.AddModelError(string.Empty, "Tên đăng nhập hoặc mật khẩu không chính xác!");
                return View(model);
            }

            if (!user.IsActive)
            {
                ModelState.AddModelError(string.Empty, "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên!");
                return View(model);
            }

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim("FullName", user.FullName),
                new Claim(ClaimTypes.Role, user.Role?.RoleName ?? "Customer")
            };

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            var authProperties = new AuthenticationProperties
            {
                IsPersistent = model.RememberMe,
                ExpiresUtc = DateTimeOffset.UtcNow.AddDays(model.RememberMe ? 14 : 1)
            };

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal, authProperties);

            if (!string.IsNullOrEmpty(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
            {
                return Redirect(model.ReturnUrl);
            }

            if (user.Role?.RoleName == "Admin" || user.Role?.RoleName == "Staff")
            {
                return RedirectToAction("Index", "Dashboard", new { area = "Admin" });
            }

            return RedirectToAction("Index", "Home");
        }

        // GET: /Account/Register
        [HttpGet]
        public IActionResult Register()
        {
            if (User.Identity?.IsAuthenticated == true)
            {
                return RedirectToAction("Index", "Home");
            }
            return View(new RegisterViewModel());
        }

        // POST: /Account/Register
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Register(RegisterViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var existingUser = await _context.Users
                .AnyAsync(u => u.Username == model.Username || (model.Email != null && u.Email == model.Email));

            if (existingUser)
            {
                ModelState.AddModelError(string.Empty, "Tên đăng nhập hoặc email đã tồn tại!");
                return View(model);
            }

            var customerRole = await _context.Roles.FirstOrDefaultAsync(r => r.RoleName == "Customer");
            int roleId = customerRole?.RoleId ?? 3;

            var newUser = new User
            {
                Username = model.Username,
                PasswordHash = model.Password, // Lưu đơn giản theo đồ án 2 tuần; có thể nâng cấp băm SHA
                FullName = model.FullName,
                Email = model.Email,
                PhoneNumber = model.PhoneNumber,
                RoleId = roleId,
                IsActive = true,
                CreatedAt = DateTime.Now
            };

            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();

            TempData["SuccessMessage"] = "Đăng ký tài khoản thành công! Vui lòng đăng nhập.";
            return RedirectToAction(nameof(Login));
        }

        // POST: /Account/Logout
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction("Index", "Home");
        }

        // GET: /Account/AccessDenied
        [HttpGet]
        public IActionResult AccessDenied()
        {
            return View();
        }
    }
}
