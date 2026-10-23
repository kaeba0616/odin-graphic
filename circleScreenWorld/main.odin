package main

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"
Circle :: struct {
	center: rl.Vector2,
	radius: f32,
	color:  rl.Vector4,
}

circle_is_inside :: proc(c: Circle, x: rl.Vector2) -> bool {
	return c.radius * c.radius > linalg.dot(x - c.center, x - c.center)

}

transform_screen_to_world :: proc(x: rl.Vector2) -> rl.Vector2 {
	aspect_ratio: f32 = f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)
	x_scale: f32 = 2.0 * aspect_ratio / f32(WINDOW_WIDTH - 1)
	y_scale: f32 = 2.0 / f32(WINDOW_HEIGHT - 1)
	return {x.x * x_scale - aspect_ratio, 1 - x.y * y_scale}
}

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "CircleWorld")
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
		center = {0, 0},
		radius = 0.25,
		color  = {1, 0, 0, 1},
	}

	aspect: f32 = f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)
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
				world_position := transform_screen_to_world({f32(j), f32(i)})
				inside := circle_is_inside(circle, world_position)
				pixels[j + WINDOW_WIDTH * i] = circle.color if inside else {0.8, 0.8, 0.8, 1}
			}
		}
		rl.UpdateTexture(texture, raw_data(pixels))

		mouse := transform_screen_to_world(rl.GetMousePosition())
		mouse_on_gui := false

		for rect in SLIDER_RECTS {
			if rl.CheckCollisionPointRec(mouse, rect) {
				mouse_on_gui = true
				break
			}
		}

		if rl.CheckCollisionPointCircle(mouse, circle.center, circle.radius) &&
		   !mouse_on_gui &&
		   rl.IsMouseButtonPressed(.LEFT) {
			dragging = true
			drag_offset = circle.center - mouse
		}

		if rl.IsMouseButtonReleased(.LEFT) {
			dragging = false
		}

		if dragging {
			circle.center = mouse + drag_offset
			rl.GuiLock()
		} else {
			rl.GuiUnlock()
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexture(texture, 0, 0, rl.WHITE)
		rl.GuiSliderBar(
			SLIDER_RECTS[0],
			"Center X",
			fmt.ctprintf("%.2f", circle.center.x),
			&circle.center.x,
			-aspect,
			aspect,
		)
		rl.GuiSliderBar(
			SLIDER_RECTS[1],
			"Center Y",
			fmt.ctprintf("%.2f", circle.center.y),
			&circle.center.y,
			-1,
			1,
		)
		rl.GuiSliderBar(
			SLIDER_RECTS[2],
			"Radius",
			fmt.ctprintf("%.2f", circle.radius),
			&circle.radius,
			0,
			1,
		)
		rl.GuiSliderBar(
			SLIDER_RECTS[3],
			"R",
			fmt.ctprintf("%.2f", circle.color.r),
			&circle.color.r,
			0,
			1,
		)
		rl.GuiSliderBar(
			SLIDER_RECTS[4],
			"G",
			fmt.ctprintf("%.2f", circle.color.g),
			&circle.color.g,
			0,
			1,
		)
		rl.GuiSliderBar(
			SLIDER_RECTS[5],
			"B",
			fmt.ctprintf("%.2f", circle.color.b),
			&circle.color.b,
			0,
			1,
		)
		rl.EndDrawing()
	}
}
