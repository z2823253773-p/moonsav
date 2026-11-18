"""Development-only synthetic fixture conversion from the GNU SAV record layout.

Not imported by MoonSav. Only accepts the known, bounded fixture record types;
does not pretend to convert arbitrary/private SAV files or IBM/VAX floats.
"""
import struct
import zlib


def to_big_endian(source):
    b = bytearray(source)
    if source[:4] not in (b'$FL2', b'$FL3') or struct.unpack_from('<i', source, 64)[0] not in (2, 3):
        raise ValueError('fixture converter expects little-endian FL2/FL3')
    for p in range(64, 84, 4):
        b[p:p + 4] = source[p:p + 4][::-1]
    b[84:92] = source[84:92][::-1]
    slots = []
    pos = 176

    def integer():
        nonlocal pos
        value = struct.unpack_from('<i', source, pos)[0]
        b[pos:pos + 4] = source[pos:pos + 4][::-1]
        pos += 4
        return value

    while True:
        record = integer()
        if record == 2:
            width, flag, missing, _, _ = [integer() for _ in range(5)]
            pos += 8
            slots.append(width == 0)
            if flag:
                n = integer()
                pos += (n + 3) // 4 * 4
            for _ in range(abs(missing)):
                if width == 0:
                    b[pos:pos + 8] = source[pos:pos + 8][::-1]
                pos += 8
        elif record == 3:
            keys = []
            for _ in range(integer()):
                keys.append(pos)
                pos += 8
                n = source[pos]
                pos += (n + 1 + 7) // 8 * 8
            if integer() != 4:
                raise ValueError('bad fixture label association')
            numeric = [slots[integer() - 1] for _ in range(integer())]
            if not numeric or any(x != numeric[0] for x in numeric):
                raise ValueError('mixed fixture label types')
            if numeric[0]:
                for p in keys:
                    b[p:p + 8] = source[p:p + 8][::-1]
        elif record == 6:
            n = integer()
            pos += 80 * n
        elif record == 7:
            subtype, size, count = integer(), integer(), integer()
            end = pos + size * count
            if subtype in (3, 4, 11, 16):
                for p in range(pos, end, size):
                    b[p:p + size] = source[p:p + size][::-1]
                if subtype == 3:
                    struct.pack_into('>i', b, pos + 24, 1)
            elif subtype in (21, 22):
                while pos < end:
                    n = integer()
                    pos += n
                    if subtype == 21:
                        integer()  # string byte width
                        n = integer()
                        for _ in range(n):
                            key_size = integer()
                            pos += key_size
                            label_size = integer()
                            pos += label_size
                    else:
                        n = source[pos]
                        pos += 1
                        width = integer()
                        pos += n * width
                if pos != end:
                    raise ValueError('bad fixture long-string extension')
            elif subtype not in (5, 6, 7, 8, 9, 10, 12, 13, 14, 17, 18, 19, 20, 24) or size != 1:
                raise ValueError(f'fixture conversion not defined for extension{subtype}')
            pos = end
        elif record == 999:
            if integer() != 0:
                raise ValueError('bad fixture terminator')
            break
        else:
            raise ValueError(f'fixture conversion not defined for record{record}')

    def convert_stream(stream, compression):
        out = bytearray(stream)
        if compression == 0:
            for p in range(0, len(stream), 8):
                if slots[(p // 8) % len(slots)]:
                    out[p:p + 8] = stream[p:p + 8][::-1]
            return bytes(out)
        at = slot = 0
        while at < len(stream):
            codes = stream[at:at + 8]
            if len(codes) != 8:
                raise ValueError('incomplete fixture control group')
            at += 8
            for code in codes:
                if code == 0:
                    continue
                if code == 252:
                    return bytes(out)
                if code == 253:
                    if slots[slot % len(slots)]:
                        out[at:at + 8] = stream[at:at + 8][::-1]
                    at += 8
                slot += 1
        return bytes(out)

    compression = struct.unpack_from('<i', source, 72)[0]
    if compression != 2:
        return bytes(b[:pos]) + convert_stream(source[pos:], compression)
    base, trailer, length = struct.unpack_from('<qqq', source, pos)
    if base != pos or trailer + length != len(source):
        raise ValueError('bad fixture ZSAV header')
    bias, zero, block_size, count = struct.unpack_from('<qqii', source, trailer)
    sizes, parts = [], []
    for i in range(count):
        _, offset, raw_size, packed_size = struct.unpack_from('<qqii', source, trailer + 24 + 24 * i)
        part = zlib.decompress(source[offset:offset + packed_size])
        if len(part) != raw_size:
            raise ValueError('bad fixture block size')
        sizes.append(raw_size)
        parts.append(part)
    stream = convert_stream(b''.join(parts), 1)
    packed = []
    at = 0
    for size in sizes:
        packed.append(zlib.compress(stream[at:at + size]))
        at += size
    trailer = base + 24 + sum(map(len, packed))
    desc = []
    cofs, uofs = base + 24, base
    for size, data in zip(sizes, packed):
        desc.append(struct.pack('>qqii', uofs, cofs, size, len(data)))
        cofs += len(data)
        uofs += size
    return (bytes(b[:pos]) + struct.pack('>qqq', base, trailer, 24 + 24 * count)
            + b''.join(packed) + struct.pack('>qqii', bias, zero, block_size, count) + b''.join(desc))
