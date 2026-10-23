package main

import "core:math/linalg"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

Circle :: struct {
	center: rl.Vector2,
	radius: f32,
	color:  rl.Vector4,
}

circle_is_inside :: proc(c: Circle, x: rl.Vector2) -> bool {

	return c.radius * c.radius >= linalg.dot(x - c.center, x - c.center)
}

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "CircleSpace")

	defer rl.CloseWindow()

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

	circle := Circle {
		center = {WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2},
		radius = WINDOW_HEIGHT / 4,
		color  = {1, 0, 0, 1},
	}

	backgroundColor: rl.Vector4 = {0.8, 0.8, 0.8, 1.0}

	dragging := false
	drag_offset: rl.Vector2


	SLIDER_RECTS :: [6]rl.Rectangle {
		{80, 10, 200, 20}, // Center X
		{80, 40, 200, 20}, // Center Y
		{80, 70, 200, 20}, // Radius
		{80, 100, 200, 20}, // R
		{80, 130, 200, 20}, // G
		{80, 160, 200, 20}, // B
	}

	for !rl.WindowShouldClose() {
		for i in 0 ..< WINDOW_HEIGHT {
			for j in 0 ..< WINDOW_WIDTH {
				inside := circle_is_inside(circle, {f32(j), f32(i)})
				pixels[j + WINDOW_WIDTH * i] = circle.color if inside else backgroundColor
			}
		}

		rl.UpdateTexture(texture, raw_data(pixels))

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexture(texture, 0, 0, rl.WHITE)


		mouse_on_gui := false
		mouse := rl.GetMousePosition()
		for r in SLIDER_RECTS {
			if rl.CheckCollisionPointRec(mouse, r) {
				mouse_on_gui = true
				break

			}
		}
		if rl.IsMouseButtonPressed(.LEFT) &&
		   !mouse_on_gui &&
		   rl.CheckCollisionPointCircle(mouse, circle.center, circle.radius) {
			dragging = true
			drag_offset = circle.center - mouse
		}


		if rl.IsMouseButtonReleased(.LEFT) {
			dragging = false
		}

		if dragging {
			circle.center = mouse + drag_offset
			rl.GuiLock()
		}
		rl.GuiSliderBar({80, 10, 200, 20}, "Center X", nil, &circle.center.x, 0, WINDOW_WIDTH - 1)
		rl.GuiSliderBar({80, 40, 200, 20}, "Center Y", nil, &circle.center.y, 0, WINDOW_HEIGHT - 1)
		rl.GuiSliderBar({80, 70, 200, 20}, "Radius", nil, &circle.radius, 0, WINDOW_HEIGHT - 1)
		rl.GuiSliderBar({80, 100, 200, 20}, "R", nil, &circle.color.r, 0, 1)
		rl.GuiSliderBar({80, 130, 200, 20}, "G", nil, &circle.color.g, 0, 1)
		rl.GuiSliderBar({80, 160, 200, 20}, "B", nil, &circle.color.b, 0, 1)
		rl.GuiUnlock()
		rl.EndDrawing()
	}
}
