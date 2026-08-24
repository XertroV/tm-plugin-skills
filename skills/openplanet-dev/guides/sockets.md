# Sockets

Openplanet exposes `Net::Socket` (and `Net::SecureSocket`; they share no
base class). Use them for a local TCP server or a client. Yield in accept
and read loops.

## Listen / accept

```angelscript
Net::Socket@ listen;

void StartServer(const string &in host, uint16 port) {
    @listen = Net::Socket();
    if (!listen.Listen(host, port)) {
        warn("listen failed");
        return;
    }
    startnew(AcceptLoop);
}

void AcceptLoop() {
    while (listen !is null) {
        yield();
        auto client = listen.Accept();
        if (client is null) continue;
        startnew(CoroutineFuncUserdata(HandleClient), client);
    }
}

void HandleClient(ref@ r) {
    auto c = cast<Net::Socket>(r);
    // read / write, then:
    c.Close();
}

void StopServer() {
    if (listen is null) return;
    listen.Close();
    @listen = null;
}
```

Bind `127.0.0.1` for agent/control bridges. Close on `OnDisabled` /
`OnDestroyed`.

## Connect (client)

```angelscript
auto s = Net::Socket();
if (!s.Connect("127.0.0.1", 30006)) {
    warn("connect failed");
    return;
}
s.WriteRaw("hello\n"); // Write(string) length-prefixes; line peers will not parse it
while (s.Available() == 0) yield();
string line;
if (!s.ReadLine(line)) {
    warn("read failed");
    s.Close();
    return;
}
s.Close();
```

`Connect` / `Accept` / `Available` are non-blocking enough to pair with
`yield()`. Do not `Dev::Sleep` on this path.

TLS: `Net::Socket` `Connect(..., secure=true)` on Openplanet 1.29.10+.
`Net::SecureSocket` is the older class (no shared base with `Socket`).

For HTTP to Nadeo, use `NadeoServices::` / `Net::HttpRequest` instead of
rolling a socket.

## Sources

- Listen / accept / `Write` vs `WriteRaw` — [tm-ghosts-plus-plus](https://github.com/XertroV/tm-ghosts-plus-plus) `src/HttpServer.as`; [tm-http-server](https://github.com/XertroV/tm-http-server) `src/HttpServer.as`
- `ReadLine(string&out)` / `WriteRaw` — Openplanet `Net::Socket` (`OpenplanetCore.json`)
