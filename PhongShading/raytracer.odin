package main
import "core:math"
import "core:math/linalg"
import "core:slice"
import rl "vendor:raylib"

Raytracer :: struct {
	width, height: i32,
	using light:   Light,
	sphere:        Sphere,
}


InitRayTracer :: proc(raytracer: ^Raytracer, width, height: i32) {

	raytracer.width = width
	raytracer.height = height
	raytracer.light = Light{{0.0, 0.0, -1.0}}

	raytracer.sphere = MakeSphere(center = rl.Vector3{0.0, 0.0, 0.5}, radius = 0.5)
	raytracer.sphere.amb = rl.Vector3(0)
	raytracer.sphere.dif = rl.Vector3{0.0, 0.0, 1.0}
	raytracer.sphere.spec = rl.Vector3(1)
	raytracer.sphere.alpha = 9.0
	raytracer.sphere.ks = 0.8
}


TraceRay :: proc(raytracer: Raytracer, ray: Ray) -> rl.Vector3 {

	sphere: Sphere = raytracer.sphere

	hit := IntersectRayCollision(sphere, ray)

	if hit.d >= 0.0 {

		// diffuse
		dirToLight := rl.Vector3Normalize(raytracer.pos - hit.point)
		diff := max(linalg.dot(hit.normal, dirToLight), 0.0)

		// specular
		dirToReflect := 2.0 * linalg.dot(hit.normal, dirToLight) * hit.normal - dirToLight
		spec := math.pow(max(linalg.dot(-ray.dir, dirToReflect), 0.0), sphere.alpha)

		//ambiant
		return sphere.amb + sphere.dif * diff + sphere.spec * spec
	}
	return rl.Vector3(0)
}

Render :: proc(raytracer: Raytracer, pixels: []rl.Vector4) {
	slice.fill(pixels, rl.Vector4{0.0, 0.0, 0.0, 1.0})


	for j in 0 ..< raytracer.height {
		for i in 0 ..< raytracer.width {
			pixelPosWorld: rl.Vector3 = TransformScreenToWorld(raytracer, {f32(i), f32(j)})

			rayDir := rl.Vector3{0.0, 0.0, 1.0}
			pixelRay: Ray = {pixelPosWorld, rayDir}

			clamp := rl.Vector3Clamp(TraceRay(raytracer, pixelRay), {0, 0, 0}, {1.0, 1.0, 1.0})
			pixels[i + raytracer.width * j] = rl.Vector4{clamp.x, clamp.y, clamp.z, 1.0}
		}
	}

}

TransformScreenToWorld :: proc(raytracer: Raytracer, posScreen: rl.Vector2) -> rl.Vector3 {
	aspect := f32(raytracer.width) / f32(raytracer.height)

	xScale := 2.0 * aspect / f32(raytracer.width - 1)
	yScale := 2.0 / f32(raytracer.height - 1)

	return {posScreen.x * xScale - aspect, 1 - posScreen.y * yScale, 0.0}
}
