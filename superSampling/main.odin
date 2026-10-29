package main

import "core:fmt"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Texturing")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	rayTracer: Raytracer
	InitRayTracer(&rayTracer, WINDOW_WIDTH, WINDOW_HEIGHT)
	defer delete(rayTracer.objs)

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

	for !rl.WindowShouldClose() {

		Render(rayTracer, pixels)
		rl.UpdateTexture(texture, raw_data(pixels))

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexture(texture, 0, 0, rl.WHITE)

		l := &rayTracer.light

		rl.GuiPanel({10, 10, 330, 200}, "Scene Control")

		rl.GuiSliderBar(
			{110, 45, 180, 18},
			"Light X",
			fmt.ctprintf("%.2f", l.pos.x),
			&l.pos.x,
			-2,
			2,
		)
		rl.GuiSliderBar(
			{110, 67, 180, 18},
			"Light Y",
			fmt.ctprintf("%.2f", l.pos.y),
			&l.pos.y,
			-2,
			2,
		)
		rl.GuiSliderBar(
			{110, 89, 180, 18},
			"Light Z",
			fmt.ctprintf("%.2f", l.pos.z),
			&l.pos.z,
			-2,
			2,
		)

		// objs[0]이 구일 때만 위치 슬라이더 표시
		if sp, ok := &rayTracer.objs[0].shape.(Sphere); ok {
			rl.GuiSliderBar(
				{110, 121, 180, 18},
				"Sphere X",
				fmt.ctprintf("%.2f", sp.center.x),
				&sp.center.x,
				-1,
				1,
			)
			rl.GuiSliderBar(
				{110, 143, 180, 18},
				"Sphere Y",
				fmt.ctprintf("%.2f", sp.center.y),
				&sp.center.y,
				-1,
				1,
			)
			rl.GuiSliderBar(
				{110, 165, 180, 18},
				"Sphere Z",
				fmt.ctprintf("%.2f", sp.center.z),
				&sp.center.z,
				-1,
				1,
			)
		}

		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}
