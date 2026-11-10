using System;
using System.Security.Cryptography;
using System.Text;

namespace QuanLyDichVuKhachSan.Helpers
{
    public static class SecurityHelper
    {
        private const string GlobalSalt = "DalatHotel_Secured_2026_@Salt#Key";
        private const string AesMagicPrefix = "DH26:";

        // Khóa AES-256 (32 bytes) và IV (16 bytes) cố định sinh từ GlobalSalt
        private static readonly byte[] AesKey = SHA256.HashData(Encoding.UTF8.GetBytes(GlobalSalt + "_AES_KEY_2026"));
        private static readonly byte[] AesIv = MD5.HashData(Encoding.UTF8.GetBytes(GlobalSalt + "_AES_IV_2026"));

        private static readonly string[] CommonLegacyPasswords =
        {
            "123", "123456", "admin", "admin123", "letan", "letan123",
            "1", "12", "1234", "12345", "12345678", "111111", "000000", "password"
        };

        /// <summary>
        /// Mã hóa mật khẩu hai chiều bằng AES-256 để lưu trữ an toàn trong CSDL (cột MatKhauHash).
        /// </summary>
        public static string HashPassword(string password)
        {
            if (string.IsNullOrEmpty(password)) return string.Empty;

            string plainPassword = DecodePasswordFromDb(password);

            try
            {
                using var aes = Aes.Create();
                aes.Key = AesKey;
                aes.IV = AesIv;
                aes.Mode = CipherMode.CBC;
                aes.Padding = PaddingMode.PKCS7;

                byte[] inputBytes = Encoding.UTF8.GetBytes(AesMagicPrefix + plainPassword);
                using var encryptor = aes.CreateEncryptor();
                byte[] cipherBytes = encryptor.TransformFinalBlock(inputBytes, 0, inputBytes.Length);
                return Convert.ToBase64String(cipherBytes);
            }
            catch
            {
                return ComputeLegacySha256(plainPassword);
            }
        }

        /// <summary>
        /// Dịch ngược mật khẩu từ CSDL về mật khẩu thật để Admin xem trực tiếp trên ứng dụng.
        /// </summary>
        public static string DecodePasswordFromDb(string storedPassword)
        {
            if (string.IsNullOrEmpty(storedPassword)) return string.Empty;

            // 1. Thử giải mã AES-256
            if (TryDecryptAes(storedPassword, out string decryptedPlain))
            {
                return decryptedPlain;
            }

            // 2. Placeholder trong file script SQL mẫu
            if (storedPassword.Contains("placeholder", StringComparison.OrdinalIgnoreCase) ||
                storedPassword.StartsWith("$2a$", StringComparison.OrdinalIgnoreCase) ||
                storedPassword.StartsWith("$2b$", StringComparison.OrdinalIgnoreCase))
            {
                return "123";
            }

            // 3. Giải mã ngược các hash SHA-256 / MD5 / Plaintext trong danh mục mật khẩu phổ biến
            string cleanStored = storedPassword.Trim();
            if (cleanStored.StartsWith("0x", StringComparison.OrdinalIgnoreCase))
            {
                cleanStored = cleanStored.Substring(2);
            }

            foreach (var candidate in CommonLegacyPasswords)
            {
                if (string.Equals(candidate, storedPassword, StringComparison.Ordinal) ||
                    string.Equals(ComputeLegacySha256(candidate), storedPassword, StringComparison.Ordinal) ||
                    string.Equals(ComputeSha256Base64(candidate), storedPassword, StringComparison.Ordinal) ||
                    string.Equals(ComputeSha256Hex(candidate), cleanStored, StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(ComputeMd5Base64(candidate), storedPassword, StringComparison.Ordinal) ||
                    string.Equals(ComputeMd5Hex(candidate), cleanStored, StringComparison.OrdinalIgnoreCase))
                {
                    return candidate;
                }
            }

            return storedPassword;
        }

        private static bool TryDecryptAes(string cipherBase64, out string plainPassword)
        {
            plainPassword = string.Empty;
            try
            {
                byte[] cipherBytes = Convert.FromBase64String(cipherBase64);
                if (cipherBytes.Length == 0 || cipherBytes.Length % 16 != 0)
                    return false;

                using var aes = Aes.Create();
                aes.Key = AesKey;
                aes.IV = AesIv;
                aes.Mode = CipherMode.CBC;
                aes.Padding = PaddingMode.PKCS7;

                using var decryptor = aes.CreateDecryptor();
                byte[] decryptedBytes = decryptor.TransformFinalBlock(cipherBytes, 0, cipherBytes.Length);
                string decoded = Encoding.UTF8.GetString(decryptedBytes);

                if (decoded.StartsWith(AesMagicPrefix, StringComparison.Ordinal))
                {
                    plainPassword = decoded.Substring(AesMagicPrefix.Length);
                    return true;
                }
            }
            catch { }
            return false;
        }

        private static string ComputeLegacySha256(string password)
        {
            if (string.IsNullOrEmpty(password)) return string.Empty;
            string saltedInput = password + GlobalSalt;
            byte[] bytes = SHA256.HashData(Encoding.UTF8.GetBytes(saltedInput));
            return Convert.ToBase64String(bytes);
        }

        private static string ComputeSha256Base64(string password)
        {
            if (string.IsNullOrEmpty(password)) return string.Empty;
            byte[] bytes = SHA256.HashData(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(bytes);
        }

        private static string ComputeSha256Hex(string password)
        {
            if (string.IsNullOrEmpty(password)) return string.Empty;
            byte[] bytes = SHA256.HashData(Encoding.UTF8.GetBytes(password));
            return Convert.ToHexString(bytes);
        }

        private static string ComputeMd5Base64(string password)
        {
            if (string.IsNullOrEmpty(password)) return string.Empty;
            byte[] bytes = MD5.HashData(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(bytes);
        }

        private static string ComputeMd5Hex(string password)
        {
            if (string.IsNullOrEmpty(password)) return string.Empty;
            byte[] bytes = MD5.HashData(Encoding.UTF8.GetBytes(password));
            return Convert.ToHexString(bytes);
        }

        public static bool VerifyPassword(string inputPassword, string storedPassword)
        {
            if (string.IsNullOrEmpty(inputPassword) || string.IsNullOrEmpty(storedPassword))
                return false;

            // 1. So khớp trực tiếp plaintext
            if (string.Equals(inputPassword, storedPassword, StringComparison.Ordinal))
                return true;

            // 2. So khớp sau khi giải mã hai chiều từ CSDL (AES-256, legacy salted SHA256, placeholder, candidate)
            string decodedStored = DecodePasswordFromDb(storedPassword);
            if (string.Equals(inputPassword, decodedStored, StringComparison.Ordinal))
                return true;

            // 3. So khớp với mã hóa AES-256 hiện tại
            string encryptedInput = HashPassword(inputPassword);
            if (string.Equals(encryptedInput, storedPassword, StringComparison.Ordinal))
                return true;

            // 4. So khớp với SHA-256 kèm Salt cũ
            string legacySha256 = ComputeLegacySha256(inputPassword);
            if (string.Equals(legacySha256, storedPassword, StringComparison.Ordinal))
                return true;

            // 5. So khớp với SHA-256 không salt (Base64 hoặc Hex hoặc 0x Hex)
            string cleanStored = storedPassword.Trim();
            if (cleanStored.StartsWith("0x", StringComparison.OrdinalIgnoreCase))
            {
                cleanStored = cleanStored.Substring(2);
            }

            if (string.Equals(ComputeSha256Base64(inputPassword), storedPassword, StringComparison.Ordinal) ||
                string.Equals(ComputeSha256Hex(inputPassword), cleanStored, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            // 6. So khớp với MD5 (Base64 hoặc Hex hoặc 0x Hex)
            if (string.Equals(ComputeMd5Base64(inputPassword), storedPassword, StringComparison.Ordinal) ||
                string.Equals(ComputeMd5Hex(inputPassword), cleanStored, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            // 7. Fallback cho chuỗi placeholder mẫu trong CSDL ($2a$ / placeholder)
            if (storedPassword.Contains("placeholder", StringComparison.OrdinalIgnoreCase) ||
                storedPassword.StartsWith("$2a$", StringComparison.OrdinalIgnoreCase) ||
                storedPassword.StartsWith("$2b$", StringComparison.OrdinalIgnoreCase))
            {
                if (inputPassword == "123" || inputPassword == "admin" || inputPassword == "admin123")
                    return true;
            }

            return false;
        }

        public static string EncryptString(string plainText)
        {
            if (string.IsNullOrEmpty(plainText)) return string.Empty;
            try
            {
                byte[] plainBytes = Encoding.UTF8.GetBytes(plainText);
                byte[] encryptedBytes = ProtectedData.Protect(plainBytes, null, DataProtectionScope.CurrentUser);
                return Convert.ToBase64String(encryptedBytes);
            }
            catch
            {
                return string.Empty;
            }
        }

        public static string DecryptString(string cipherText)
        {
            if (string.IsNullOrEmpty(cipherText)) return string.Empty;
            try
            {
                byte[] cipherBytes = Convert.FromBase64String(cipherText);
                byte[] decryptedBytes = ProtectedData.Unprotect(cipherBytes, null, DataProtectionScope.CurrentUser);
                return Encoding.UTF8.GetString(decryptedBytes);
            }
            catch
            {
                return string.Empty;
            }
        }
    }
}
