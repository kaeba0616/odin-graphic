package main

import "core:fmt"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
RENDER_SCALE :: 2 // C++의 width/2, height/2
RT_WIDTH :: WINDOW_WIDTH / RENDER_SCALE
RT_HEIGHT :: WINDOW_HEIGHT / RENDER_SCALE

ROW_H :: 22
XYZ :: [3]string{"X", "Y", "Z"}
RGB :: [3]string{"R", "G", "B"}

slider :: proc(y: ^f32, label: cstring, v: ^f32, lo, hi: f32) {
	rl.GuiSliderBar({130, y^, 160, 18}, label, fmt.ctprintf("%.2f", v^), v, lo, hi)
	y^ += ROW_H
}

// ImGui::SliderFloat3 대용
slider3 :: proc(y: ^f32, name: string, v: ^rl.Vector3, lo, hi: f32, suffix := XYZ) {
	for i in 0 ..< 3 {
		slider(y, fmt.ctprintf("%s %s", name, suffix[i]), &v[i], lo, hi)
	}
	y^ += 6
}

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "HongLabGraphics Example")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	rayTracer: Raytracer
	InitRayTracer(&rayTracer, RT_WIDTH, RT_HEIGHT)

	pixels := make([]rl.Vector4, RT_WIDTH * RT_HEIGHT)
	defer delete(pixels)

	image := rl.Image {
		data    = raw_data(pixels),
		width   = RT_WIDTH,
		height  = RT_HEIGHT,
		mipmaps = 1,
		format  = .UNCOMPRESSED_R32G32B32A32,
	}
	texture := rl.LoadTextureFromImage(image)
	defer rl.UnloadTexture(texture)

	dragging := false
	drag_offset: rl.Vector2
	panel := rl.Rectangle{10, 10, 310, 490}

	for !rl.WindowShouldClose() {
		s := &rayTracer.sphere

		// ---- 입력 처리 ----
		mouse_screen := rl.GetMousePosition()
		// 레이트레이서는 절반 해상도 좌표계를 쓰므로 마우스 좌표를 맞춰 줌
		mouse := TransformScreenToWorld(rayTracer, mouse_screen / RENDER_SCALE)
		on_panel := rl.CheckCollisionPointRec(mouse_screen, panel)

		// 정투영이라 구는 화면에서 center.xy, radius인 원과 정확히 일치
		if !on_panel &&
		   rl.IsMouseButtonPressed(.LEFT) &&
		   rl.CheckCollisionPointCircle(mouse.xy, s.center.xy, s.radius) {
			dragging = true
			drag_offset = s.center.xy - mouse.xy
		}
		if rl.IsMouseButtonReleased(.LEFT) do dragging = false

		if dragging {
			s.center.x = mouse.x + drag_offset.x
			s.center.y = mouse.y + drag_offset.y
		}

		// ---- 레이트레이싱 (example->Update) ----
		Render(rayTracer, pixels)
		rl.UpdateTexture(texture, raw_data(pixels))

		// ---- 그리기 (example->Render + Present) ----
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.DrawTexturePro(
			texture,
			{0, 0, RT_WIDTH, RT_HEIGHT},
			{0, 0, WINDOW_WIDTH, WINDOW_HEIGHT},
			{0, 0},
			0,
			rl.WHITE,
		)

		// ---- GUI (ImGui::Begin("Circle") ~ End) ----
		rl.GuiPanel(panel, "Circle")
		y: f32 = 45
		slider3(&y, "Center", &s.center, -1, 1)
		slider(&y, "Radius", &s.radius, 0, 1)
		y += 6
		slider3(&y, "Light", &rayTracer.light.pos, -2, 2)
		slider3(&y, "Ambient", &s.amb, 0, 1, RGB)
		slider3(&y, "Diffuse", &s.dif, 0, 1, RGB)
		slider3(&y, "Specular", &s.spec, 0, 1, RGB)
		slider(&y, "Spec power", &s.alpha, 0, 100)
		slider(&y, "Spec coeff", &s.ks, 0, 1)

		rl.DrawFPS(WINDOW_WIDTH - 100, 10)
		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}
