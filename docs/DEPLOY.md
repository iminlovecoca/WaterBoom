# Deploy Server Tại Nhà

## Kiến Trúc

```
Player → Playit tunnel → Server nhà bạn (port 7777)
```

- Server nhà bạn chạy Godot headless trên port 7777
- Playit tunnel forward traffic từ `reminded-uncut.tun.ply.gg:38709` → `localhost:7777`
- Client kết nối qua WebSocket (TCP) — ổn định hơn ENet (UDP) qua tunnel

## Cách 1: Chạy trực tiếp trên Windows

```bash
# double-click start_server.bat
# hoặc chạy manual:
"C:\path\to\Godot_v4.7.1-stable_win64.exe" --headless --path "C:\Users\khang\Documents\Build\Boom" -- --server --port=7777
```

Đảm bảo Playit agent đang chạy:
```bash
playit status
# Phải thấy: service running, secret configured
```

## Cách 2: Docker trên Windows/Linux

```bash
cd docker
docker compose build
docker compose up -d
```

Port host 7777 được map vào container.

## Cấu hình client

Trong `server_config.json` trên máy client:

```json
{
  "client": {
    "default_host": "reminded-uncut.tun.ply.gg",
    "default_port": 38709
  }
}
```

Nếu Playit tạo tunnel mới (hostname thay đổi), cập nhật `default_host` và `default_port`.

## Tại sao WebSocket ổn định hơn qua Playit?

| | ENet (UDP) | WebSocket (TCP) |
|---|---|---|
| Playit reliability | Hay disconnect, API error | Ổn định hơn nhiều |
| Firewall | Bị block | Luôn mở (port 80/443) |
| Retry | Mất packet = mất update | TCP tự retry |
| Delay | Thấp hơn ~5ms | Thấp hơn ~5ms |

## Nếu Playit vẫn不稳定

Thử alternatives miễn phí:

### localhost.run (SSH tunnel, miễn phí)
```bash
ssh -R 80:localhost:7777 localhost.run
# Cho URL dạng: xxx.localhost.run → forward về localhost:7777
```

### serveo.net (SSH tunnel, miễn phí)
```bash
ssh -R 80:localhost:7777 serveo.net
```

Cả hai đều free, không cần cài gì thêm. Chỉ cần SSH client.

## Troubleshooting

**Playit không kết nối được:**
```bash
playit status
playit reset  # Nếu cần claim lại agent
```

**Server khởi động nhưng player không vào được:**
- Kiểm tra Playit tunnel đang active
- Kiểm tra port 7777 server đang lắng nghe
- Test locally: `curl http://localhost:7777`
