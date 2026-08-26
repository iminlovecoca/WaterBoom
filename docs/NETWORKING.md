# Networking Status

`NetworkManager` uses `WebSocketMultiplayerPeer` (TCP) for both server and client.

## Kiến trúc

```
Client → WebSocket (TCP) → Playit tunnel → Server tại nhà (port 7777)
```

- **Transport**: WebSocket over TCP (thay vì ENet/UDP)
- **Tunnel**: Playit.gg forward traffic từ public endpoint → localhost:7777
- **Authority**: Server-authoritative (room state, auth, purchases)
- **Movement**: Client-side prediction + server relay

## Tại sao chuyển từ ENet sang WebSocket?

| | ENet (UDP) | WebSocket (TCP) |
|---|---|---|
| Playit stability | Hay disconnect | Ổn định hơn |
| Firewall | Bị block | Luôn mở |
| Packet loss | Mất update | TCP retry |
| Godot support | Built-in | Built-in, drop-in replacement |

## Flow kết nối

1. Client mở game → LoginScreen
2. Client connect `ws://reminded-uncut.tun.ply.gg:38709`
3. Playit tunnel forward về `localhost:7777`
4. Godot server nhận WebSocket connection
5. Auth → Lobby → Match
