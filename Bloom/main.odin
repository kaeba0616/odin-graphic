package main

import "core:fmt"
import "core:slice"
import "core:time"
import rl "vendor:raylib"
import stbi "vendor:stb/image"

import "vendor:x11/xlib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

Image :: struct {
	width, height: int,
	pixels:        []rl.Vector4,
}

image_read_from_file :: proc(img: ^Image, filename: cstring) -> bool {
	w, h, channels: i32

	data := stbi.load(filename, &w, &h, &channels, 4)
	if data == nil {
		fmt.eprintln("can't read the image : ", filename, stbi.failure_reason())
		return false
	}
	defer stbi.image_free(data)

	img.width, img.height = int(w), int(h)
	img.pixels = make([]rl.Vector4, img.width * img.height)

	for i in 0 ..< len(img.pixels) {
		img.pixels[i] = {
			f32(data[i * 4]) / 255,
			f32(data[i * 4 + 1]) / 255,
			f32(data[i * 4 + 2]) / 255,
			1,
		}
	}
	return true
}

image_write_png :: proc(img: ^Image, filename: cstring) {
	buf := make([]u8, img.width * img.height * 4)
	defer delete(buf)

	for p, i in img.pixels {
		for c in 0 ..< 4 {
			buf[i * 4 + c] = u8(clamp(p[c], 0, 1) * 255)
		}
	}
	stbi.write_png(filename, i32(img.width), i32(img.height), 4, raw_data(buf), i32(img.width * 4))
}

image_get_pixel :: proc(img: ^Image, i, j: int) -> ^rl.Vector4 {
	i := clamp(i, 0, img.width - 1)
	j := clamp(j, 0, img.height - 1)
	return &img.pixels[i + img.width * j]
}

image_box_blur5 :: proc(img: ^Image) {
	// TODO
}

image_gaussian_blur5 :: proc(img: ^Image) {
	weights: [5]f32 = {0.0545, 0.2442, 0.4026, 0.2442, 0.0545}
	for i := 0; i < img.width; i += 1 {
		for j := 0; j < img.height; j += 1 {
			sum: rl.Vector3 = {0.0, 0.0, 0.0}

			for wc := 0; wc < 5; wc += 1 {
				cur := image_get_pixel(img, i + wc - 2, j)
				sum[0] += cur[0] * weights[wc]
				sum[1] += cur[1] * weights[wc]
				sum[2] += cur[2] * weights[wc]
			}
			img.pixels[i + img.width * j][0] = sum[0]
			img.pixels[i + img.width * j][1] = sum[1]
			img.pixels[i + img.width * j][2] = sum[2]
		}
	}
	for i := 0; i < img.width; i += 1 {
		for j := 0; j < img.height; j += 1 {
			sum: rl.Vector3 = {0.0, 0.0, 0.0}

			for wc := 0; wc < 5; wc += 1 {
				cur := image_get_pixel(img, i, j + wc - 2)
				sum[0] += cur[0] * weights[wc]
				sum[1] += cur[1] * weights[wc]
				sum[2] += cur[2] * weights[wc]
			}
			img.pixels[i + img.width * j][0] = sum[0]
			img.pixels[i + img.width * j][1] = sum[1]
			img.pixels[i + img.width * j][2] = sum[2]
		}
	}

}

// relative luminance Y= 0.2126 * R + 0.7152 * G + 0.0722 * B
image_bloom :: proc(img: ^Image, th: f32, num_repeat: int, weight: f32 = 1) {
	img_backup := slice.clone(img.pixels)
	defer delete(img_backup)

	for i := 0; i < img.width; i += 1 {
		for j := 0; j < img.height; j += 1 {
			pixel := &img.pixels[i + img.width * j]
			RL := pixel[0] * 0.2126 + pixel[1] * 0.7152 + pixel[2] * 0.0722
			if th > RL {
				pixel^[0] = 0.0
				pixel^[1] = 0.0
				pixel^[2] = 0.0
			}
		}
	}
	for i in 0 ..< num_repeat {
		image_gaussian_blur5(img)
	}


	for i in 0 ..< len(img_backup) {
		img.pixels[i][0] = clamp(img.pixels[i][0] * weight + img_backup[i][0], 0, 1)
		img.pixels[i][1] = clamp(img.pixels[i][1] * weight + img_backup[i][1], 0, 1)
		img.pixels[i][2] = clamp(img.pixels[i][2] * weight + img_backup[i][2], 0, 1)

	}
}


main :: proc() {
	img: Image
	if !image_read_from_file(&img, "scorpion.png") do return

	defer delete(img.pixels)
	start := time.now()


	image_bloom(&img, 0.3, 100, 1.0)

	fmt.printf("%.3f sec\n", time.duration_seconds(time.since(start)))

	image_write_png(&img, "result.png")

	rl.InitWindow(i32(img.width / 2), i32(img.height / 2), "Bloom")
	defer rl.CloseWindow()

	rl_image := rl.Image {
		data    = raw_data(img.pixels),
		width   = i32(img.width),
		height  = i32(img.height),
		mipmaps = 1,
		format  = .UNCOMPRESSED_R32G32B32A32,
	}

	texture := rl.LoadTextureFromImage(rl_image)
	defer (rl.UnloadTexture(texture))

	src := rl.Rectangle{0, 0, f32(img.width), f32(img.height)}
	dst := rl.Rectangle{0, 0, f32(img.width / 2), f32(img.height / 2)}

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexturePro(texture, src, dst, {0, 0}, 0, rl.WHITE)
		rl.EndDrawing()
	}
}
