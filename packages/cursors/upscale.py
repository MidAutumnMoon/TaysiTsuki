# Sources are pixel art, so generated sizes use copy-only scalers: scale2x
# for power-of-two factors, nearest otherwise.
import os
import struct
import sys
from collections import namedtuple

FILE_MAGIC = b"Xcur"
FILE_HEADER = struct.Struct("<4sIII")
CHUNK_TABLE_ENTRY = struct.Struct("<III")
IMAGE_CHUNK_TYPE = 0xFFFD0002
IMAGE_CHUNK_VERSION = 1
IMAGE_HEADER = struct.Struct("<9I")

Image = namedtuple(
    "Image", "nominal_size width height hotspot_x hotspot_y delay_ms pixels"
)


def parse_image(chunk):
    header_size, _, nominal_size, _, width, height, hotspot_x, hotspot_y, delay_ms = (
        IMAGE_HEADER.unpack_from(chunk)
    )
    assert header_size == IMAGE_HEADER.size
    pixels = list(struct.unpack_from(f"<{width * height}I", chunk, IMAGE_HEADER.size))
    return Image(nominal_size, width, height, hotspot_x, hotspot_y, delay_ms, pixels)


def serialize_image(image):
    header = IMAGE_HEADER.pack(
        IMAGE_HEADER.size,
        IMAGE_CHUNK_TYPE,
        image.nominal_size,
        IMAGE_CHUNK_VERSION,
        image.width,
        image.height,
        image.hotspot_x,
        image.hotspot_y,
        image.delay_ms,
    )
    pixel_bytes = struct.pack(f"<{image.width * image.height}I", *image.pixels)
    return header + pixel_bytes


def parse(contents):
    magic, header_size, version, chunk_count = FILE_HEADER.unpack_from(contents)
    assert magic == FILE_MAGIC, "not an Xcursor file"
    assert header_size == FILE_HEADER.size
    chunk_table = [
        CHUNK_TABLE_ENTRY.unpack_from(
            contents, FILE_HEADER.size + CHUNK_TABLE_ENTRY.size * index
        )
        for index in range(chunk_count)
    ]
    boundaries = [offset for _, _, offset in chunk_table] + [len(contents)]
    chunks = []
    for (chunk_type, subtype, offset), end in zip(chunk_table, boundaries[1:]):
        chunks.append((chunk_type, subtype, contents[offset:end]))
    return version, chunks


def compose(version, chunks):
    offset = FILE_HEADER.size + CHUNK_TABLE_ENTRY.size * len(chunks)
    table_bytes = bytearray()
    chunk_data = bytearray()
    for chunk_type, subtype, payload in chunks:
        table_bytes += CHUNK_TABLE_ENTRY.pack(chunk_type, subtype, offset)
        chunk_data += payload
        offset += len(payload)
    header = FILE_HEADER.pack(FILE_MAGIC, FILE_HEADER.size, version, len(chunks))
    return header + table_bytes + chunk_data


def scale2x(pixels, width, height):
    # Border neighbors must never compare equal, so pad with
    # pairwise-distinct out-of-range values.
    sentinel_base = 1 << 32
    padded_width = width + 2
    padded_pixels = [
        sentinel_base + index for index in range(padded_width * (height + 2))
    ]
    for source_row in range(height):
        padded_start = (source_row + 1) * padded_width + 1
        padded_pixels[padded_start : padded_start + width] = pixels[
            source_row * width : (source_row + 1) * width
        ]

    scaled_width = width * 2
    scaled_height = height * 2
    output = [0] * (scaled_width * scaled_height)
    for row in range(1, height + 1):
        row_start = row * padded_width
        for column in range(1, width + 1):
            north = padded_pixels[row_start - padded_width + column]
            west = padded_pixels[row_start + column - 1]
            center = padded_pixels[row_start + column]
            east = padded_pixels[row_start + column + 1]
            south = padded_pixels[row_start + padded_width + column]

            output_offset = (row - 1) * 2 * scaled_width + (column - 1) * 2
            output[output_offset] = (
                west if west == north and north != east and west != south else center
            )
            output[output_offset + 1] = (
                east if north == east and north != west and east != south else center
            )
            output[output_offset + scaled_width] = (
                west if west == south and west != north and south != east else center
            )
            output[output_offset + scaled_width + 1] = (
                south if south == east and south != west and east != north else center
            )
    return output, scaled_width, scaled_height


def nearest(pixels, width, height, target_width, target_height):
    source_columns = [column * width // target_width for column in range(target_width)]
    source_rows = [row * height // target_height for row in range(target_height)]
    return [
        pixels[source_row * width + source_column]
        for source_row in source_rows
        for source_column in source_columns
    ]


def scale_coordinate(coordinate, source_length, target_length):
    scaled_coordinate = (
        coordinate * target_length + source_length // 2
    ) // source_length
    return min(scaled_coordinate, target_length - 1)


def is_power_of_two(number):
    return (number & (number - 1)) == 0


def pick_source_size(available_sizes, target_size):
    candidates = [size for size in available_sizes if size < target_size]
    divisors = [size for size in candidates if target_size % size == 0]
    # Power-of-two ratios keep scale2x available; integer ratios scale evenly.
    power_of_two_sources = [
        size for size in divisors if is_power_of_two(target_size // size)
    ]
    return max(power_of_two_sources or divisors or candidates, default=None)


def resize(image, target_size):
    scale_factor, remainder = divmod(target_size, image.nominal_size)
    pixels = image.pixels
    target_width, target_height = image.width, image.height
    if remainder == 0 and is_power_of_two(scale_factor):
        while scale_factor > 1:
            pixels, target_width, target_height = scale2x(
                pixels, target_width, target_height
            )
            scale_factor //= 2
    else:
        target_width = image.width * target_size // image.nominal_size
        target_height = image.height * target_size // image.nominal_size
        pixels = nearest(
            image.pixels, image.width, image.height, target_width, target_height
        )
    return Image(
        nominal_size=target_size,
        width=target_width,
        height=target_height,
        hotspot_x=scale_coordinate(image.hotspot_x, image.width, target_width),
        hotspot_y=scale_coordinate(image.hotspot_y, image.height, target_height),
        delay_ms=image.delay_ms,
        pixels=pixels,
    )


def add_missing_sizes(chunks, target_sizes):
    frames_by_size = {}
    for chunk_type, _, chunk in chunks:
        if chunk_type == IMAGE_CHUNK_TYPE:
            image = parse_image(chunk)
            frames_by_size.setdefault(image.nominal_size, []).append(image)

    available_sizes = frames_by_size.keys()
    generated_chunks = []
    for target_size in target_sizes:
        if target_size in available_sizes:
            continue
        source_size = pick_source_size(available_sizes, target_size)
        if source_size is None:
            continue
        for image in frames_by_size[source_size]:
            generated_chunks.append(
                (
                    IMAGE_CHUNK_TYPE,
                    target_size,
                    serialize_image(resize(image, target_size)),
                )
            )
    return chunks + generated_chunks


def main():
    input_dir, output_dir = sys.argv[1], sys.argv[2]
    target_sizes = sorted({int(size) for size in sys.argv[3:]})
    os.makedirs(output_dir, exist_ok=True)
    for filename in sorted(os.listdir(input_dir)):
        input_path = os.path.join(input_dir, filename)
        if not os.path.isfile(input_path):
            continue
        with open(input_path, "rb") as input_file:
            contents = input_file.read()
        if contents[:4] == FILE_MAGIC:
            version, chunks = parse(contents)
            contents = compose(version, add_missing_sizes(chunks, target_sizes))
        with open(os.path.join(output_dir, filename), "wb") as output_file:
            output_file.write(contents)


if __name__ == "__main__":
    main()
