"""Patch archive writer. Boot Mod Loader MIT code and texture support from Extended Pickup Icons Range. See THIRD-PARTY-NOTICES.md."""
import os
import struct

LUA_SOURCE_FLAG = 2


SCAFFOLD = bytes.fromhex(
    "110000f0010000000100000000000000ce09f5f4000000006e0b41bab993fecf0040170300000000"
    "00cc5600000000000000000000000000000000000000000000000000000000000000000000000000"
    "e217d12cfa8d4ea101000000000000001000000040000000b1d0e27de00d175ce217d12cfa8d4ea1"
    "b8000000000000000000000000000000000000000000000000b000000000000000c1070000000000"
    "f3af00000000000000000000100000004000000001000000")


def murmur64(data, seed=0):
    """MurmurHash64A, as the engine names resources."""
    m, r, mask = 0xc6a4a7935bd1e995, 47, 0xFFFFFFFFFFFFFFFF
    h = (seed ^ (len(data) * m)) & mask
    whole = len(data) - len(data) % 8
    for at in range(0, whole, 8):
        k = int.from_bytes(data[at:at + 8], "little")
        k = (k * m) & mask
        k ^= k >> r
        k = (k * m) & mask
        h = ((h ^ k) * m) & mask
    tail = data[whole:]
    if tail:
        h ^= int.from_bytes(tail, "little")
        h = (h * m) & mask
    h ^= h >> r
    h = (h * m) & mask
    h ^= h >> r
    return h


LUA_TYPE = murmur64(b"lua")


TEXTURE_TYPE = murmur64(b"texture")


def texture_part(width, height):
    """A texture resource's main part for width x height RGBA8 pixels, one mip, the pixels in .gpu_resources: the
    engine's 192-byte texture header (no streaming), then a DDS header with the DX10 extension (R8G8B8A8_UNORM, 2D)."""
    engine = struct.pack("<III", 0, 0, 0xFFFFFFFF) + bytes(180)
    flags = 0x1 | 0x2 | 0x4 | 0x8 | 0x1000          # caps, height, width, pitch, pixel format
    dds = b"DDS " + struct.pack("<7I", 124, flags, height, width, width * 4, 0, 1) + bytes(44)
    dds += struct.pack("<2I4s5I", 32, 0x4, b"DX10", 0, 0, 0, 0, 0)   # pixel format: FourCC DX10
    dds += struct.pack("<5I", 0x1000, 0, 0, 0, 0)                   # caps: texture
    dds += struct.pack("<5I", 28, 3, 0, 1, 0)                       # DXGI R8G8B8A8_UNORM, a 2D texture, one of it
    return engine + dds


def write_module(out_dir, resource_name, source, flag=LUA_SOURCE_FLAG, archive="9ba626afa44a3aa3.patch_0",
                 textures=()):
    """One Lua resource as a patch archive (plus its .gpu_resources and .stream); textures: (resource name, width,
    height, RGBA8 pixels) after it (write_with_textures). Without textures, the Lua-only archive."""
    encoded = source if isinstance(source, bytes) else source.encode("utf-8")
    payload = struct.pack("<2I", len(encoded), flag) + encoded
    if textures:
        return write_with_textures(out_dir, resource_name, payload, textures, archive)
    out = bytearray(SCAFFOLD)
    row = 0x48 + 32
    struct.pack_into("<3Q", out, row, murmur64(resource_name.encode("utf-8")), LUA_TYPE, len(SCAFFOLD))
    struct.pack_into("<I", out, row + 56, len(payload))
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, archive)
    with open(path, "wb") as f:
        f.write(bytes(out) + payload)
    open(path + ".gpu_resources", "wb").close()
    open(path + ".stream", "wb").close()
    return path


def write_with_textures(out_dir, resource_name, payload, textures, archive):
    """The Lua row as in SCAFFOLD (its header bytes 12..72 too), then a texture type row and a row per texture, their
    pixels in .gpu_resources (64-byte aligned)."""
    n = 1 + len(textures)
    head = struct.pack("<III", 0xF0000011, 2, n) + SCAFFOLD[12:72]
    head += struct.pack("<QQQII", 0, LUA_TYPE, 1, 16, 64)
    head += struct.pack("<QQQII", 0, TEXTURE_TYPE, len(textures), 16, 64)
    cursor = len(head) + 80 * n
    rows, body, gpu = b"", b"", bytearray()
    rows += struct.pack("<7Q6I", murmur64(resource_name.encode("utf-8")), LUA_TYPE, cursor, 0, 0, 0, 0,
                        len(payload), 0, 0, 16, 64, 1)
    body += payload
    cursor += len(payload)
    for k, (name, width, height, pixels) in enumerate(textures, 2):
        pad = -cursor % 16
        body += bytes(pad)
        cursor += pad
        part = texture_part(width, height)
        gpu += bytes(-len(gpu) % 64)
        rows += struct.pack("<7Q6I", murmur64(name.encode("utf-8")), TEXTURE_TYPE, cursor, 0, len(gpu), 0, 0,
                            len(part), 0, len(pixels), 16, 64, k)
        gpu += pixels
        body += part
        cursor += len(part)
    out = head + rows + body
    out += bytes(-len(out) % 16)
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, archive)
    with open(path, "wb") as f:
        f.write(out)
    with open(path + ".gpu_resources", "wb") as f:
        f.write(bytes(gpu))
    open(path + ".stream", "wb").close()
    return path
