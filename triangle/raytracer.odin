package main
import "core:math"
import "core:math/linalg"
import "core:slice"
import rl "vendor:raylib"

Raytracer :: struct {
	width, height: i32,
	using light:   Light,
	objs:          [dynamic]Object,
}


InitRayTracer :: proc(raytracer: ^Raytracer, width, height: i32) {

	raytracer.width = width
	raytracer.height = height
	raytracer.light = Light{{0.0, 0.0, -1.0}}

	sphere_mat: Material
	sphere_mat.amb = rl.Vector3(0.1)
	sphere_mat.dif = {1.0, 0.1, 0.1}
	sphere_mat.spec = rl.Vector3(1.0)
	sphere_mat.alpha = 50.0

	sphere := Object {
		material = sphere_mat,
		shape = Sphere{center = {0.6, 0.0, 0.5}, radius = 0.4},
	}

	append(&raytracer.objs, sphere)

	triangle_mat1: Material
	triangle_mat1.amb = rl.Vector3(0.2)
	triangle_mat1.dif = rl.Vector3(0.5)
	triangle_mat1.spec = rl.Vector3(0.5)
	triangle_mat1.alpha = 5.0

	triangle1 := Object {
		material = triangle_mat1,
		shape = Triangle{v0 = {-2.0, -2.0, 2.0}, v1 = {-2.0, 2.0, 2.0}, v2 = {2.0, 2.0, 2.0}},
	}

	append(&raytracer.objs, triangle1)


	//	triangle_mat2: Material
	//	triangle_mat2.amb = rl.Vector3(0.2)
	//	triangle_mat2.dif = rl.Vector3(0.5)
	//	triangle_mat2.spec = rl.Vector3(0.5)
	//	triangle_mat2.alpha = 5.0
	//
	//	triangle2 := Object {
	//		material = triangle_mat2,
	//		shape = Triangle{v0 = {-2.0, -2.0, 2.0}, v1 = {1.0, 1.0, 2.0}, v2 = {2.0, -2.0, 2.0}},
	//	}
	//
	//	append(&raytracer.objs, triangle2)
}

FindClosestCollisionPointSphere :: proc(objs: [dynamic]Object, ray: Ray) -> Hit {
	closestD := 1000.0
	closestHit := Hit {
		d = -1.0,
	}

	for obj in objs {
		hit := CheckRayCollision(obj, ray)

		if hit.d >= 0 {
			if f64(hit.d) < closestD {
				closestD = f64(hit.d)
				closestHit = hit
			}
		}
	}
	return closestHit

}

TraceRay :: proc(raytracer: Raytracer, ray: Ray) -> rl.Vector3 {
	objs := raytracer.objs

	hit := FindClosestCollisionPointSphere(objs, ray)

	if hit.d >= 0.0 {

		// diffuse
		dirToLight := rl.Vector3Normalize(raytracer.pos - hit.point)
		diff := max(linalg.dot(hit.normal, dirToLight), 0.0)

		// specular
		dirToReflect := 2.0 * linalg.dot(hit.normal, dirToLight) * hit.normal - dirToLight
		spec := math.pow(max(linalg.dot(-ray.dir, dirToReflect), 0.0), hit.obj.alpha)

		//ambiant
		return hit.obj.amb + hit.obj.dif * diff + hit.obj.spec * spec
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
