package main
import "core:math"
import "core:math/linalg"
import "core:slice"
import rl "vendor:raylib"

Raytracer :: struct {
	width, height: i32,
	using light:   Light,
	objs:          [dynamic]Sphere,
}


InitRayTracer :: proc(raytracer: ^Raytracer, width, height: i32) {

	raytracer.width = width
	raytracer.height = height
	raytracer.light = Light{{0.0, 0.0, -1.0}}

	sphere1 := MakeSphere(
		center = rl.Vector3{0.5, 0.0, 0.5},
		radius = 0.4,
		color = rl.Vector3{0.5, 0.5, 0.5},
	)

	//	sphere2 := MakeSphere(
	//		center = rl.Vector3{0.0, 0.0, 1.0},
	//		radius = 0.4,
	//		color = rl.Vector3{0.5, 0.5, 0.5},
	//	)
	//	sphere3 := MakeSphere(
	//		center = rl.Vector3{-0.5, 0.0, 1.5},
	//		radius = 0.4,
	//		color = rl.Vector3{0.5, 0.5, 0.5},
	//	)

	sphere1.amb = rl.Vector3(0.2)
	sphere1.diff = rl.Vector3{1.0, 0.2, 0.2}
	sphere1.spec = rl.Vector3(0.5)
	sphere1.alpha = 10.0

	//	sphere2.amb = rl.Vector3(0.2)
	//	sphere2.diff = rl.Vector3{0.2, 1.0, 0.2}
	//	sphere2.spec = rl.Vector3(0.5)
	//	sphere2.alpha = 10.0
	//
	//	sphere3.amb = rl.Vector3(0.2)
	//	sphere3.diff = rl.Vector3{0.2, 0.2, 1.0}
	//	sphere3.spec = rl.Vector3(0.5)
	//	sphere3.alpha = 10.0

	append(&raytracer.objs, sphere1)

}

FindClosestCollision :: proc(raytracer: Raytracer, ray: Ray) -> Hit {
	closestD: f32 = 1000.0
	closestHit: Hit = {-1.0, rl.Vector3(0.0), rl.Vector3(0.0), Sphere{}}

	for obj in raytracer.objs {
		hit := CheckRayCollisionSpherePoint(obj, ray)

		if hit.d >= 0 {
			if hit.d < closestD {
				closestD = hit.d
				closestHit = hit
				closestHit.obj = obj
			}
		}

	}
	return closestHit
}

TraceRay :: proc(raytracer: Raytracer, ray: Ray) -> rl.Vector3 {

	hit := FindClosestCollision(raytracer, ray)

	if hit.d >= 0.0 {

		// diffuse
		dirToLight := rl.Vector3Normalize(raytracer.pos - hit.point)
		diff := max(linalg.dot(hit.normal, dirToLight), 0.0)

		// specular
		dirToReflect := 2.0 * linalg.dot(hit.normal, dirToLight) * hit.normal - dirToLight
		spec := math.pow(max(linalg.dot(-ray.dir, dirToLight), 0.0), hit.obj.alpha)

		//ambiant
		return hit.amb + hit.diff * diff + hit.spec * spec
	}
	return rl.Vector3(0)
}

Render :: proc(raytracer: Raytracer, pixels: []rl.Vector4) {
	slice.fill(pixels, rl.Vector4{0.0, 0.0, 0.0, 1.0})

	eyePos := rl.Vector3{0.0, 0.0, -1.5}

	for j in 0 ..< raytracer.height {
		for i in 0 ..< raytracer.width {
			pixelPosWorld: rl.Vector3 = TransformScreenToWorld(raytracer, {f32(i), f32(j)})

			rayDir := rl.Vector3{0.0, 0.0, 1.0}
			pixelRay: Ray = {pixelPosWorld, rl.Vector3Normalize(pixelPosWorld - eyePos)}

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
