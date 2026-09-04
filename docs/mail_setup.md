# Kết nối hộp thư trường (Microsoft Graph)

Tài liệu này mô tả cách bật tính năng **Cài đặt → Kết nối → Email trường**.
Chỉ cần làm một lần; sau đó mỗi sinh viên tự đăng nhập một lần trên máy họ.

## 0. Bối cảnh

`tlu.edu.vn` là một tenant Microsoft 365 (tên hiển thị "Thuyloi University"),
kiểu *Managed* — đăng nhập trực tiếp tại `login.microsoftonline.com`, không
qua ADFS. Vì vậy hộp thư `mail.tlu.edu.vn` đọc được bằng **Microsoft Graph**.

| Thông tin | Giá trị |
|---|---|
| Tenant ID | `bbf9aad6-5f58-4387-927e-02f0b07a72fa` |
| Authority | `https://login.microsoftonline.com/bbf9aad6-.../oauth2/v2.0` |
| Graph | `https://graph.microsoft.com/v1.0` |

## 1. Đăng ký ứng dụng trên Azure Portal

1. Vào <https://portal.azure.com> → **Microsoft Entra ID** → **App registrations**
   → **New registration**.
2. **Name**: `TLU Study Planner`.
3. **Supported account types**: chọn
   *Accounts in this organizational directory only (Thuyloi University only - Single tenant)*.
4. **Redirect URI**: chọn nền tảng **Public client/native (mobile & desktop)**
   và nhập chính xác:

   ```
   com.tlu.studyplanner://oauth2redirect
   ```

5. Bấm **Register**.

> Nếu tài khoản của bạn không có quyền tạo App registration, cần nhờ quản trị
> viên CNTT của trường. Ứng dụng chỉ xin quyền **đọc thư của chính người dùng**
> (delegated), không phải quyền toàn tổ chức.

## 2. Bật luồng public client

Trong app vừa tạo → **Authentication**:

- Mục **Advanced settings** → **Allow public client flows** → đặt **Yes**.
- Kiểm tra lại Redirect URI ở trên đã nằm trong mục *Mobile and desktop
  applications*.

Ứng dụng di động không giữ được client secret, nên luồng dùng là
**Authorization Code + PKCE**; không cần và không được tạo client secret.

## 3. Cấp quyền API

Trong app → **API permissions** → **Add a permission** →
**Microsoft Graph** → **Delegated permissions**, thêm:

| Quyền | Dùng để |
|---|---|
| `openid`, `profile` | đọc email và tên người đăng nhập |
| `offline_access` | nhận refresh token (đăng nhập **một lần duy nhất**) |
| `User.Read` | hồ sơ cơ bản |
| `Mail.Read` | đọc thư trong Hộp thư đến |

Bấm **Grant admin consent for Thuyloi University** nếu tenant yêu cầu
(thường có, để sinh viên không phải bấm đồng ý thủ công).

> Muốn khi mở thư trong app thì server cũng đánh dấu đã đọc: đổi `Mail.Read`
> thành `Mail.ReadWrite` ở đây **và** trong `lib/config/mail_config.dart`
> (`scopes` + `markReadOnServer = true`).

## 4. Điền client ID vào ứng dụng

Copy **Application (client) ID** ở trang *Overview* của app, rồi chọn một
trong hai cách:

**Cách A — sửa file** (`lib/config/mail_config.dart`):

```dart
static const String clientId = String.fromEnvironment(
  'TLU_MAIL_CLIENT_ID',
  defaultValue: '00000000-1111-2222-3333-444444444444', // ← dán vào đây
);
```

**Cách B — truyền lúc build** (không để ID trong git):

```bash
flutter build apk --dart-define=TLU_MAIL_CLIENT_ID=00000000-1111-2222-3333-444444444444
```

Chưa điền thì thẻ trong Cài đặt hiện "Bản cài đặt này chưa được cấu hình kết
nối email" và nút liên kết bị khoá — không có lỗi khó hiểu nào bật ra.

## 5. Cấu hình nền tảng (đã làm sẵn)

Không phải sửa gì thêm, chỉ để biết chỗ nếu sau này đổi scheme:

- `android/app/build.gradle.kts` → `manifestPlaceholders["appAuthRedirectScheme"]`
- `ios/Runner/Info.plist` → `CFBundleURLTypes` → `CFBundleURLSchemes`
- `lib/config/mail_config.dart` → `redirectScheme`

Cả ba phải giống nhau và **viết thường toàn bộ** (AppAuth trên Android xử lý
sai nếu có chữ hoa).

Sau khi sửa `pubspec.yaml`, chạy:

```bash
flutter pub get
```

## 6. Kiểm tra

1. Mở app → **Cài đặt → Kết nối → Liên kết email trường**.
2. Trình duyệt hệ thống mở trang đăng nhập Microsoft → đăng nhập bằng
   `@tlu.edu.vn` → đồng ý cấp quyền.
3. Quay lại app, thẻ hiển thị địa chỉ email.
4. Trang chủ → biểu tượng chuông → pill **Mail** → danh sách thư hiện ra;
   thư chưa đọc có chấm xanh và tiêu đề đậm.

## Bảo mật

- **Refresh token** là thứ duy nhất được ghi xuống đĩa, nằm trong Android
  KeyStore / iOS Keychain (`flutter_secure_storage`), không phải
  SharedPreferences. Access token chỉ sống trong RAM.
- Đăng nhập diễn ra trong **Custom Tab / ASWebAuthenticationSession** của hệ
  thống, không phải WebView nhúng — mật khẩu trường không đi qua tay ứng dụng,
  và Microsoft chặn đăng nhập trong WebView.
- Thân thư HTML được dựng trong WebView **tắt JavaScript**, và mọi liên kết
  trong thư đều bị chặn điều hướng.
- **Huỷ liên kết** trong Cài đặt xoá sạch token khỏi keystore.

## Giới hạn đã biết

Thông báo thư mới được kiểm tra khi ứng dụng đang mở (mỗi 15 phút, và mỗi lần
mở lại app) — xem `lib/widgets/mail_poller.dart`. Muốn thông báo tức thời cả
khi app đóng thì phải dựng một máy chủ nhận
[Graph change notification](https://learn.microsoft.com/graph/webhooks) rồi
đẩy qua FCM/APNs; đó là hạ tầng nằm ngoài ứng dụng này.
