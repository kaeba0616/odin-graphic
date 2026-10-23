package main
import "core:slice"
import rl "vendor:raylib"

Raytracer :: struct {
	width, height: int,
	sphere:        Sphere,
}

MakeTracer :: proc(width, height: int) -> Raytracer {
	sphere: Sphere = {{0.0, 0.0, 0.5}, 0.4, {1.0, 1.0, 1.0}}
	return Raytracer{width = width, height = height, sphere = sphere}
}

TransformScreenToWorld :: proc(raytracer: Raytracer, pos: rl.Vector2) -> rl.Vector3 {
	aspect: f32 = f32(raytracer.width) / f32(raytracer.height)

	xScale := 2.0 * aspect / f32(raytracer.width)
	yScale := 2.0 / f32(raytracer.height)

	return {pos.x * xScale - aspect, 1 - pos.y * yScale, 0.0}

}

TraceRay :: proc(raytracer: Raytracer, ray: Ray) -> rl.Vector3 {
	hit: Hit = Intersect_ray_collision(raytracer.sphere, ray)

	if hit.d < 0.0 {
		return rl.Vector3(0)
	} else {
		return raytracer.sphere.color * hit.d
	}
}

Render :: proc(raytracer: Raytracer, pixels: []rl.Vector4) {

	slice.fill(pixels, rl.Vector4{0, 0, 0, 1})

	for j in 0 ..< raytracer.height {
		for i in 0 ..< raytracer.width {
			pixelPosWorld := TransformScreenToWorld(raytracer, {f32(i), f32(j)})

			rayDir: rl.Vector3 = {0.0, 0.0, 1.0}

			pixelRay: Ray = {pixelPosWorld, rayDir}

			traceRay := TraceRay(raytracer, pixelRay)

			pixels[i + raytracer.width * j] = {traceRay[0], traceRay[1], traceRay[2], 1.0}
		}
	}
}
