package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
EYE_POS :: rl.Vector3{0, 0, -1.5} // Render에 있던 상수를 여기로 이동
ROW_H :: 22

XYZ :: [3]string{"X", "Y", "Z"}
RGB :: [3]string{"R", "G", "B"}

slider :: proc(y: ^f32, label: cstring, v: ^f32, lo, hi: f32) {
	rl.GuiSliderBar({110, y^, 180, 18}, label, fmt.ctprintf("%.2f", v^), v, lo, hi)
	y^ += ROW_H
}

slider3 :: proc(y: ^f32, name: string, v: ^rl.Vector3, lo, hi: f32, suffix := XYZ) {
	for i in 0 ..< 3 {
		slider(y, fmt.ctprintf("%s %s", name, suffix[i]), &v[i], lo, hi)
	}
	y^ += 6
}

// 마우스 위치에서 Render와 같은 방식(원근)으로 광선 생성
make_mouse_ray :: proc(rt: Raytracer, screen: rl.Vector2) -> Ray {
	p := TransformScreenToWorld(rt, screen)
	return Ray{start = p, dir = linalg.normalize(p - EYE_POS)}
}

// 광선이 가장 먼저 만나는 구의 인덱스, 없으면 -1
pick_sphere :: proc(rt: Raytracer, ray: Ray) -> int {
	best := -1
	best_t := max(f32)
	for s, idx in rt.objs {
		oc := ray.start - s.center
		b := linalg.dot(ray.dir, oc)
		c := linalg.dot(oc, oc) - s.radius * s.radius
		disc := b * b - c
		if disc < 0 do continue
		t := -b - math.sqrt(disc)
		if t >= 0 && t < best_t {
			best_t = t
			best = idx
		}
	}
	return best
}

// 광선이 z = 상수 평면과 만나는 점
point_on_plane_z :: proc(ray: Ray, z: f32) -> rl.Vector3 {
	t := (z - ray.start.z) / ray.dir.z
	return ray.start + ray.dir * t
}

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

	selected := 0
	dragging := false
	drag_offset: rl.Vector3
	panel := rl.Rectangle{10, 10, 300, 460}
	aspect := f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)

	for !rl.WindowShouldClose() {
		// ---- 입력 처리 ----
		mouse_screen := rl.GetMousePosition()
		ray := make_mouse_ray(rayTracer, mouse_screen)
		on_panel := rl.CheckCollisionPointRec(mouse_screen, panel)

		if rl.IsMouseButtonPressed(.LEFT) && !on_panel {
			if hit := pick_sphere(rayTracer, ray); hit >= 0 {
				selected = hit
				dragging = true
				c := rayTracer.objs[hit].center
				drag_offset = c - point_on_plane_z(ray, c.z)
			}
		}
		if rl.IsMouseButtonReleased(.LEFT) do dragging = false

		s := &rayTracer.objs[selected]
		if dragging {
			// 구의 z 깊이를 유지한 채 마우스를 따라 이동
			p := point_on_plane_z(ray, s.center.z)
			s.center.x = p.x + drag_offset.x
			s.center.y = p.y + drag_offset.y
		}

		// ---- 레이트레이싱 ----
		Render(rayTracer, pixels)
		rl.UpdateTexture(texture, raw_data(pixels))

		// ---- 그리기 ----
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexture(texture, 0, 0, rl.WHITE)

		rl.GuiPanel(panel, fmt.ctprintf("Sphere %d", selected))
		y: f32 = 45
		slider(&y, "Center X", &s.center.x, -aspect, aspect)
		slider(&y, "Center Y", &s.center.y, -1, 1)
		slider(&y, "Center Z", &s.center.z, 0, 3)
		slider(&y, "Radius", &s.radius, 0, 1)
		y += 6
		slider3(&y, "Light", &rayTracer.light.pos, -1, 1)
		slider3(&y, "Amb", &s.amb, 0, 1, RGB)
		slider3(&y, "Diff", &s.diff, 0, 1, RGB)
		slider3(&y, "Spec", &s.spec, 0, 1, RGB)
		slider(&y, "Spec pow", &s.alpha, 0, 100)
		rl.DrawFPS(WINDOW_WIDTH - 100, 10)
		rl.DrawText(
			fmt.ctprintf("hover: %d", pick_sphere(rayTracer, ray)),
			WINDOW_WIDTH - 150,
			40,
			20,
			rl.YELLOW,
		)
		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}
