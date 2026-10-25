package main

import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720


main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Triangle")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	raytracer: Raytracer
	InitRayTracer(&raytracer, WINDOW_WIDTH, WINDOW_HEIGHT)
	defer delete(raytracer.objs)

	pixels := make([]rl.Vector4, WINDOW_WIDTH * WINDOW_HEIGHT)
	defer delete(pixels)

	image := rl.Image {
		data    = raw_data(pixels),
		width   = WINDOW_WIDTH,
		height  = WINDOW_HEIGHT,
		mipmaps = 1,
		format  = .UNCOMPRESSED_R32G32B32A32,
	}

	texture := rl.LoadTextureFromImage(image)
	defer rl.UnloadTexture(texture)

	Render(raytracer, pixels)
	rl.UpdateTexture(texture, raw_data(pixels))

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexture(texture, 0, 0, rl.WHITE)
		rl.EndDrawing()
	}

}
