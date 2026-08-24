# Images and textures

Download once, keep a `MemoryBuffer` or file, then `UI::LoadTexture` and/or
`nvg::LoadTexture`. Both loaders consume the buffer from the current seek.

## Download + cache in memory

```angelscript
class CachedImage {
    string url;
    MemoryBuffer@ buf;
    UI::Texture@ ui;
    nvg::Texture@ nvg;
    bool done, ok;

    CachedImage(const string &in url) {
        this.url = url;
        startnew(CoroutineFunc(Download));
    }

    void Download() {
        auto req = Net::HttpGet(url);
        while (!req.Finished()) yield();
        done = true;
        uint code = req.ResponseCode();
        if (code < 200 || code >= 300) return;
        @buf = req.Buffer();
        ok = buf !is null;
    }

    UI::Texture@ Ui() {
        if (!done || !ok) return null;
        if (ui is null) {
            buf.Seek(0);
            @ui = UI::LoadTexture(buf);
        }
        return ui;
    }

    nvg::Texture@ Nvg() {
        if (!done || !ok) return null;
        if (nvg is null) {
            buf.Seek(0);
            @nvg = nvg::LoadTexture(buf);
        }
        return nvg;
    }
}

dictionary g_images;

CachedImage@ ImageFromUrl(const string &in url) {
    if (g_images.Exists(url)) return cast<CachedImage>(g_images[url]);
    auto img = CachedImage(url);
    @g_images[url] = img;
    return img;
}
```

A `GetSize().x` near 0 means the bytes were not a texture — drop the handle.

## Disk cache

```angelscript
string CachePath(const string &in url) {
    return IO::FromStorageFolder("img/" + Crypto::MD5(url) + ".bin");
}

// after a successful GET:
auto path = CachePath(url);
IO::CreateFolder(IO::FromStorageFolder("img"), true);
IO::File f(path, IO::FileMode::Write);
f.Write(req.Buffer());
f.Close();

// later:
if (IO::FileExists(path)) {
    IO::File r(path, IO::FileMode::Read);
    auto buf = r.Read(r.Size());
    r.Close();
    @tex = UI::LoadTexture(buf);
}
```

Plugin storage (`IO::FromStorageFolder`) survives reloads. Packaged files
load with a relative path: `UI::LoadTexture("img/icon.png")`.

## Draw

```angelscript
auto tex = ImageFromUrl(url).Ui();
if (tex !is null) UI::Image(tex, vec2(64, 64));

// nvg:
auto nt = ImageFromUrl(url).Nvg();
if (nt !is null) {
    nvg::BeginPath();
    nvg::Rect(pos, size);
    nvg::FillPaint(nvg::TexturePattern(pos, size, 0, nt, 1));
    nvg::Fill();
}
```

There is an Openplanet examples repo (openplanet-nl) with a download/cache
sample; prefer that plus this pattern over inventing a third cache.

## Sources

- HTTP GET + `UI::LoadTexture` cache — [tm-better-room-manager](https://github.com/XertroV/tm-better-room-manager) `src/Tabs/CachedImages.as`
- Dual UI + NVG from one buffer — [tm-cgf-library](https://github.com/XertroV/tm-cgf-library) `src/Texture.as`
