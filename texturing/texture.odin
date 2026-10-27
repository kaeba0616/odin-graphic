package main

import "core:math/linalg"
import "core:strings"
import rl "vendor:raylib"
import stbi "vendor:stb/image"

Texture :: struct {
	width, height, channels: i32,
	image:                   []u8,
}

MakeTextureFromFile :: proc(filename: string) -> (tex: Texture, ok: bool) {
	cname := strings.clone_to_cstring(filename, context.temp_allocator)

	img := stbi.load(cname, &tex.width, &tex.height, &tex.channels, 0)
	if img == nil do return
	defer stbi.image_free(img)

	size := int(tex.width * tex.height * tex.channels)
	tex.image = make([]u8, size)
	copy(tex.image, img[:size])

	return tex, true
}

MakeTextureFromPixels :: proc(width, height: i32, pixels: []rl.Vector3) -> Texture {
	tex := Texture {
		width    = width,
		height   = height,
		channels = 3,
	}
	tex.image = make([]u8, width * height * tex.channels)

	for j in 0 ..< height {
		for i in 0 ..< width {
			color := pixels[i + j * width]
			idx := (i + width * j) * tex.channels

			tex.image[idx + 0] = u8(clamp(color.r, 0, 1) * 255)
			tex.image[idx + 1] = u8(clamp(color.g, 0, 1) * 255)
			tex.image[idx + 2] = u8(clamp(color.b, 0, 1) * 255)

		}
	}
	return tex
}

GetClamped :: proc(texture: Texture, i, j: i32) -> rl.Vector3 {

	i := rl.Clamp(f32(i), 0, f32(texture.width - 1))
	j := rl.Clamp(f32(j), 0, f32(texture.height - 1))

	r := f32(texture.image[(i32(i) + texture.width * i32(j)) * texture.channels + 0]) / 255.0
	g := f32(texture.image[(i32(i) + texture.width * i32(j)) * texture.channels + 1]) / 255.0
	b := f32(texture.image[(i32(i) + texture.width * i32(j)) * texture.channels + 2]) / 255.0

	return {r, g, b}
}

GetWrapped :: proc(texture: Texture, i, j: i32) -> rl.Vector3 {

	i := i % texture.width
	j := j % texture.height

	if i < 0 {
		i += texture.width
	}
	if j < 0 {
		j += texture.height
	}

	r := f32(texture.image[(i32(i) + texture.width * i32(j)) * texture.channels + 0]) / 255.0
	g := f32(texture.image[(i32(i) + texture.width * i32(j)) * texture.channels + 1]) / 255.0
	b := f32(texture.image[(i32(i) + texture.width * i32(j)) * texture.channels + 2]) / 255.0

	return {r, g, b}
}

InterpolateBilinear :: proc(dx, dy: f32, c00, c10, c01, c11: rl.Vector3) -> rl.Vector3 {

	a := (1 - dx) * c00 + dx * c10
	b := (1 - dx) * c01 + dx * c11

	return (1 - dy) * a + dy * b
}

SamplePoint :: proc(texture: Texture, uv: rl.Vector2) -> rl.Vector3 {

	xy: rl.Vector2 = uv * rl.Vector2{f32(texture.width), f32(texture.height)} - rl.Vector2(0.5)
	i := i32(linalg.round(xy.x))
	j := i32(linalg.round(xy.y))

	return GetClamped(texture, i, j)
}

SampleLinear :: proc(texture: Texture, uv: rl.Vector2) -> rl.Vector3 {

	xy: rl.Vector2 = uv * rl.Vector2{f32(texture.width), f32(texture.height)} - rl.Vector2(0.5)
	i := i32(xy.x)
	j := i32(xy.y)

	dx := xy.x - f32(i)
	dy := xy.y - f32(j)

	return InterpolateBilinear(
		dx,
		dy,
		GetWrapped(texture, i, j),
		GetWrapped(texture, i + 1, j),
		GetWrapped(texture, i, j + 1),
		GetWrapped(texture, i + 1, j + 1),
	)
}
