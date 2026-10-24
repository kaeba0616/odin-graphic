package main

import "core:fmt"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
ASPECT :: f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "DrawingSphere")
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

	selected: i32 = 0

	for !rl.WindowShouldClose() {
		Render(rayTracer, pixels)
		rl.UpdateTexture(texture, raw_data(pixels))

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexture(texture, 0, 0, rl.WHITE)

		s := &rayTracer.objs[selected]
		l := &rayTracer.light

		rl.GuiPanel({10, 10, 330, 500}, "Circle")
		rl.GuiToggleGroup({100, 40, 58, 20}, "0;1;2", &selected)

		rl.GuiSliderBar(
			{100, 70, 180, 18},
			"Center X",
			fmt.ctprintf("%.2f", s.center.x),
			&s.center.x,
			-ASPECT,
			ASPECT,
		)
		rl.GuiSliderBar(
			{100, 92, 180, 18},
			"Center Y",
			fmt.ctprintf("%.2f", s.center.y),
			&s.center.y,
			-1,
			1,
		)
		rl.GuiSliderBar(
			{100, 114, 180, 18},
			"Center Z",
			fmt.ctprintf("%.2f", s.center.z),
			&s.center.z,
			0,
			2,
		)
		rl.GuiSliderBar(
			{100, 140, 180, 18},
			"Radius",
			fmt.ctprintf("%.2f", s.radius),
			&s.radius,
			0,
			1,
		)

		rl.GuiSliderBar(
			{100, 166, 180, 18},
			"Light X",
			fmt.ctprintf("%.2f", l.pos.x),
			&l.pos.x,
			-2,
			2,
		)
		rl.GuiSliderBar(
			{100, 188, 180, 18},
			"Light Y",
			fmt.ctprintf("%.2f", l.pos.y),
			&l.pos.y,
			-2,
			2,
		)
		rl.GuiSliderBar(
			{100, 210, 180, 18},
			"Light Z",
			fmt.ctprintf("%.2f", l.pos.z),
			&l.pos.z,
			-2,
			2,
		)

		rl.GuiSliderBar(
			{100, 236, 180, 18},
			"Amb R",
			fmt.ctprintf("%.2f", s.amb.r),
			&s.amb.r,
			0,
			1,
		)
		rl.GuiSliderBar(
			{100, 258, 180, 18},
			"Amb G",
			fmt.ctprintf("%.2f", s.amb.g),
			&s.amb.g,
			0,
			1,
		)
		rl.GuiSliderBar(
			{100, 280, 180, 18},
			"Amb B",
			fmt.ctprintf("%.2f", s.amb.b),
			&s.amb.b,
			0,
			1,
		)

		rl.GuiSliderBar(
			{100, 306, 180, 18},
			"Diff R",
			fmt.ctprintf("%.2f", s.dif.r),
			&s.dif.r,
			0,
			1,
		)
		rl.GuiSliderBar(
			{100, 328, 180, 18},
			"Diff G",
			fmt.ctprintf("%.2f", s.dif.g),
			&s.dif.g,
			0,
			1,
		)
		rl.GuiSliderBar(
			{100, 350, 180, 18},
			"Diff B",
			fmt.ctprintf("%.2f", s.dif.b),
			&s.dif.b,
			0,
			1,
		)

		rl.GuiSliderBar(
			{100, 376, 180, 18},
			"Spec R",
			fmt.ctprintf("%.2f", s.spec.r),
			&s.spec.r,
			0,
			1,
		)
		rl.GuiSliderBar(
			{100, 398, 180, 18},
			"Spec G",
			fmt.ctprintf("%.2f", s.spec.g),
			&s.spec.g,
			0,
			1,
		)
		rl.GuiSliderBar(
			{100, 420, 180, 18},
			"Spec B",
			fmt.ctprintf("%.2f", s.spec.b),
			&s.spec.b,
			0,
			1,
		)

		rl.GuiSliderBar(
			{100, 446, 180, 18},
			"Spec pow",
			fmt.ctprintf("%.2f", s.alpha),
			&s.alpha,
			0,
			100,
		)
		rl.GuiSliderBar({100, 468, 180, 18}, "Spec coeff", fmt.ctprintf("%.2f", s.ks), &s.ks, 0, 1)

		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}
