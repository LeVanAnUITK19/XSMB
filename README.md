# XSMB

Ứng dụng Flutter xổ số miền Bắc, backend Node.js + MongoDB Atlas và crawler từ Hội đồng XSKT miền Bắc. Logo sử dụng đúng ảnh người dùng cung cấp. Phiên bản khởi tạo **1.0.0+1**, Android applicationId **com.myapp.kqxs.xsmb**.

## Cấu trúc

- `frontend/`: xem kết quả theo ngày, bộ lọc 2/3 số, chia sẻ ảnh, dò vé 5 chữ số và ký hiệu, lịch sử/thống kê lưu trên thiết bị, lịch mở thưởng, cơ cấu giải, cấu hình URL backend.
- `backend/`: REST API, MongoDB, cache ngắn, xác thực POST/PUT, crawler HTML chính thức không cần Chrome, Dockerfile.
- `.github/workflows/`: CI và hai lịch POST/PUT. Backend không có cron hay background worker chạy liên tục.

## Chạy backend

Yêu cầu Node.js 22 trở lên.

```bash
cd backend
npm ci
# .env cục bộ đã được tạo từ URI người dùng cung cấp; file này không được Git theo dõi.
# Trên máy mới: cp .env.example .env và điền giá trị thật.
npm run check:db
npm test
npm start
```

Database mặc định: **xsmb**, collection: **results**. Có thể đổi bằng `MONGODB_DB` và `MONGODB_COLLECTION`. Việc kiểm tra kết nối và kiểm thử trong quá trình xây dựng không ghi dữ liệu kết quả mẫu vào Atlas. Server tạo unique index `(date, region)` khi khởi động; dữ liệu được upsert khi crawler gửi POST/PUT.

Biến môi trường:

| Biến | Ý nghĩa |
| --- | --- |
| `MONGODB_URI` | URI Atlas, chỉ dùng ở backend |
| `MONGODB_DB` | `xsmb` |
| `MONGODB_COLLECTION` | `results` |
| `CRAWLER_API_TOKEN` | Token bảo vệ API ghi; đã tạo ngẫu nhiên trong `.env` cục bộ |
| `CORS_ORIGINS` | `*` cho API công khai; có thể nhập các web origin cách nhau dấu phẩy |
| `PORT` | Cổng máy chủ, mặc định 3000 |
| `API_URL` | URL đầy đủ của endpoint ghi, ví dụ `https://your-api.example/api/results`; chỉ dùng bởi crawler |

Không đặt URI MongoDB hoặc token ghi vào frontend, README hay GitHub Variables công khai.

## API

| Method | Endpoint | Công dụng |
| --- | --- | --- |
| GET | `/healthz`, `/api/results/health` | Kiểm tra API và MongoDB |
| GET | `/api/results?page=1&limit=20` | Kết quả mới nhất, có phân trang |
| GET | `/api/results/filter?date=2026-11-26&region=mien-bac` | Kết quả đúng ngày |
| GET | `/api/results/filter-province?province=Miền%20Bắc` | Giữ tương thích API cũ |
| POST, PUT | `/api/results` | Upsert theo ngày; bắt buộc `Authorization: Bearer <CRAWLER_API_TOKEN>` |

GET trả `{data: [...], pagination: {...}}`. Mỗi bản ghi có `date`, `region: mien-bac`, `provinces[0].full` từ DB đến G7, `provinces[0].specialSymbols`, `status`, `source`, `createdAt`, `updatedAt`.

Cơ cấu kết quả: DB 1×5 số, G1 1×5, G2 2×5, G3 6×5, G4 4×4, G5 6×4, G6 3×3, G7 4×2 — **27 số**. Dữ liệu được giữ dưới dạng chuỗi để không mất số 0 đầu. Bản crawl thiếu không được xóa kết quả đầy đủ đã lưu. Cache API tối đa 15 giây cho kết quả mới và 5 phút cho truy vấn ngày cũ; POST/PUT xóa cache ngay.

## Deploy backend

Có thể deploy thư mục `backend/` bằng Dockerfile hoặc dịch vụ hỗ trợ Node.js:

- Root directory: `backend`
- Build: `npm ci --omit=dev`
- Start: `npm start`
- Health path: `/healthz`
- Cấu hình các biến môi trường trong bảng ở trên. Khi deploy Docker, không đưa `.env` vào image; truyền biến môi trường từ nền tảng hosting.
- Trên Atlas, cho phép IP của nơi chạy backend và giữ đúng user/password do bạn cấu hình.

Chạy Docker cục bộ từ gốc dự án:

```bash
docker compose up --build -d
```

## Crawl và GitHub Actions

Nguồn chính thức: https://xosomb.com.vn/xo-so-truyen-thong . Crawler đọc cả bảng số và các ký hiệu ĐB, đối chiếu chính xác ngày. Không có kết quả ngày yêu cầu thì PUT không ghi đè dữ liệu cũ. POST có thể tạo bản ghi chờ với mảng kết quả rỗng.

Sau khi backend được deploy, đặt hai **GitHub Actions repository secrets**:

- `API_URL`: `https://your-api.example/api/results`
- `CRAWLER_API_TOKEN`: trùng với token trong môi trường backend.

Lịch giờ Việt Nam:

- POST: 14:00, 14:15, 14:30, 14:45.
- PUT: mỗi 5 phút từ 18:05 đến 19:30.
- Cả hai workflow có nút chạy thủ công. GitHub có thể chạy cron trễ.

Chạy thủ công cục bộ:

```bash
cd backend
npm run crawl:post
npm run crawl:put
node scripts/crawl.js PUT --date=2026-11-26
```

Để bắt đầu có dữ liệu, chạy backend rồi gọi `crawl:put`, hoặc chạy workflow sau khi đã thêm secrets. Chỉ đẩy mã lên GitHub khi bạn sẵn sàng; `.env` và khóa ký Android đã được bỏ qua bởi Git.

## Frontend

```bash
cd frontend
flutter pub get
flutter test
flutter analyze
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/
```

Có thể cấu hình email hỗ trợ riêng bằng `--dart-define=SUPPORT_EMAIL=your-email@example.com`. Không mặc định dùng thông tin liên hệ của ứng dụng nguồn.

Không có URL build sẵn, app sẽ mở màn hình chào với logo và nút **Cấu hình máy chủ**. Sau khi bạn deploy backend, nhập `https://your-api.example/api/` tại màn hình này. Địa chỉ được lưu trên thiết bị, không cần build lại chỉ để đổi endpoint.

Trên Android emulator dùng `http://10.0.2.2:3000/api/`. Với điện thoại cắm USB có thể dùng `adb reverse tcp:3000 tcp:3000` và nhập `http://127.0.0.1:3000/api/`. Kết nối production dùng HTTPS; HTTP chỉ được cho phép với các địa chỉ phát triển cục bộ này.

```bash
flutter build apk --debug
flutter build web --release
# Khi đã có URL backend cố định:
flutter build apk --debug --dart-define=API_BASE_URL=https://your-api.example/api/
```

Đây là ứng dụng mới, không dùng keystore của XSMT/XSMN. Trước khi build AAB để phát hành CH Play, tạo upload keystore riêng cho XSMB, điền `android/key.properties` theo `key.properties.example`, rồi chạy `flutter build appbundle --release`. `versionCode` và `versionName` lấy từ `pubspec.yaml`.

## Quy tắc dò vé

- Chỉ hỗ trợ vé truyền thống miền Bắc 5 chữ số, cơ cấu vé 10.000đ; mệnh giá/đợt phát hành khác cần thể lệ riêng.
- Đủ đúng 27 kết quả hợp lệ mới kết luận. Thiếu dữ liệu không lưu thành vé thua.
- Các giải G1–G7 so đúng các chữ số cuối; một vé trúng nhiều hạng/lần quay được cộng đủ.
- Trùng 5 số ĐB cần đúng ký hiệu. Vé trùng số nhưng khác ký hiệu hợp lệ nhận phụ ĐB. Thiếu ký hiệu hoặc thiếu danh sách công bố sẽ yêu cầu bổ sung, không tự suy ra phụ ĐB.
- Bộ 15 ký hiệu có 6 ký hiệu trúng ĐB, bộ 20 có 8. Nhập đúng loại bộ vé.
- Khuyến khích 40.000đ: trùng 2 số cuối ĐB; không áp dụng quy tắc “sai một chữ số” của miền Nam/Trung.
- Mức ĐB/phụ mặc định tham chiếu công bố XSKT Quảng Ninh: 500 triệu / 25 triệu. Nếu vé/đợt phát hành có mức khác, nhập đúng mức in trên vé ở phần **Mức ĐB/phụ ĐB**. Không coi một mức thưởng là mặc định cho mọi đơn vị và mọi đợt phát hành.
- Thuế tính trên tổng giải của một vé theo ngày thực tế nhận thưởng: trước 01/07/2026 ngưỡng 10 triệu, từ ngày đó ngưỡng 20 triệu; thuế 10% phần vượt ngưỡng. Thực nhận trên app là ước tính.

Nguồn kiểm chứng:

- Hội đồng XSKT miền Bắc: https://xosomb.com.vn/xo-so-truyen-thong
- XSKT Quảng Ninh, loại hình và cơ cấu: https://www.xosoquangninh.com.vn/xskt/loai-hinh-xo-so/xo-so-truyen-thong
- Luật Thuế TNCN 109/2025/QH15: https://congbao.chinhphu.vn/van-ban/luat-so-109-2025-qh15-468671.htm

## File build sẵn

- `dist/XSMB-1.0.0-debug.apk`: APK cài thử Android, applicationId `com.myapp.kqxs.xsmb`, version `1.0.0` (code `1`).
- `dist/xsmb-web-1.0.0.zip`: nội dung web release, giải nén để deploy lên static hosting.
- `dist/xsmb-backend-1.0.0.zip`: backend deploy package, không chứa `.env` hoặc thông tin đăng nhập. Nhập biến môi trường riêng trên hosting.

Các bản frontend trên chưa cố định URL backend; nhập URL trong **Cấu hình máy chủ** sau khi backend được deploy. Thư mục `dist/` được bỏ qua bởi Git.