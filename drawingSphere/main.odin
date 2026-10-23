package main
import "core:fmt"
import rl "vendor:raylib"


WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

main :: proc() {

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "DrawingSphere")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	rayTracer := MakeTracer(WINDOW_WIDTH, WINDOW_HEIGHT)

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

	dragging := false
	drag_offset: rl.Vector2

	aspect := f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)
	for !rl.WindowShouldClose() {
		Render(rayTracer, pixels)
		rl.UpdateTexture(texture, raw_data(pixels))

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.DrawTexture(texture, 0, 0, rl.WHITE)
		s := &rayTracer.sphere

		mouse := TransformScreenToWorld(rayTracer, rl.GetMousePosition())
		mouse_ray := Ray {
			start = mouse,
			dir   = {0, 0, 1},
		}

		if rl.CheckCollisionPointCircle({mouse.x, mouse.y}, {s.center.x, s.center.y}, s.radius) &&
		   rl.IsMouseButtonPressed(.LEFT) {
			dragging = true
			drag_offset = s.center.xy - mouse.xy
		}

		if rl.IsMouseButtonReleased(.LEFT) {
			dragging = false
		}

		if dragging {
			s.center.x = mouse.x + drag_offset.x
			s.center.y = mouse.y + drag_offset.y
		}

		rl.GuiPanel({10, 10, 330, 250}, "Sphere")
		rl.GuiSliderBar(
			{90, 45, 200, 20},
			"Center X",
			fmt.ctprintf("%.2f", s.center.x),
			&s.center.x,
			-aspect,
			aspect,
		)
		rl.GuiSliderBar(
			{90, 70, 200, 20},
			"Center Y",
			fmt.ctprintf("%.2f", s.center.y),
			&s.center.y,
			-1,
			1,
		)
		rl.GuiSliderBar(
			{90, 95, 200, 20},
			"Center Z",
			fmt.ctprintf("%.2f", s.center.z),
			&s.center.z,
			-1,
			1,
		)
		rl.GuiSliderBar(
			{90, 130, 200, 20},
			"Radius",
			fmt.ctprintf("%.2f", s.radius),
			&s.radius,
			0,
			1,
		)
		rl.GuiSliderBar({90, 165, 200, 20}, "R", fmt.ctprintf("%.2f", s.color.r), &s.color.r, 0, 1)
		rl.GuiSliderBar({90, 190, 200, 20}, "G", fmt.ctprintf("%.2f", s.color.g), &s.color.g, 0, 1)
		rl.GuiSliderBar({90, 215, 200, 20}, "B", fmt.ctprintf("%.2f", s.color.b), &s.color.b, 0, 1)

		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}
