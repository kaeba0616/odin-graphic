package main
import "core:fmt"
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
	raytracer.light = Light{{0.0, 0.3, -0.5}}

	sphere_mat1: Material
	sphere_mat1.amb = rl.Vector3(0.2)
	sphere_mat1.dif = {0, 0, 1}
	sphere_mat1.spec = rl.Vector3(0.0)
	sphere_mat1.alpha = 50.0
	sphere_mat1.reflection = 0.0
	sphere_mat1.transparency = 1.0

	sphere1 := Object {
		material = sphere_mat1,
		shape = Sphere{center = {0.0, -0.1, 1.5}, radius = 1},
	}

	append(&raytracer.objs, sphere1)


	groundTexture := new(Texture)
	ok: bool

	groundTexture^, ok = MakeTextureFromFile("shadertoy_abstract1.png")

	ground_shape := InitSquare(
		rl.Vector3{-10, -1.5, 0},
		rl.Vector3{-10, -1.5, 10},
		rl.Vector3{10, -1.5, 10},
		rl.Vector3{10, -1.5, 0},
		rl.Vector2{0.0, 0.0},
		rl.Vector2{1.0, 0.0},
		rl.Vector2{1.0, 1.0},
		rl.Vector2{0.0, 1.0},
	)
	ground_mat: Material
	ground_mat.amb = rl.Vector3(1.0)
	ground_mat.dif = rl.Vector3(1.0)
	ground_mat.spec = rl.Vector3(1.0)
	ground_mat.alpha = 10.0
	ground_mat.reflection = 0.0


	ground := Object {
		material   = ground_mat,
		shape      = ground_shape,
		ambTexture = groundTexture,
		difTexture = groundTexture,
	}

	append(&raytracer.objs, ground)

	backTexture := new(Texture)

	backTexture^, ok = MakeTextureFromFile("back.png")

	back_shape := InitSquare(
		rl.Vector3{-10, 10, 10},
		rl.Vector3{10, 10, 10},
		rl.Vector3{10, -10, 10},
		rl.Vector3{-10, -10, 10},
		rl.Vector2{0.0, 0.0},
		rl.Vector2{1.0, 0.0},
		rl.Vector2{1.0, 1.0},
		rl.Vector2{0.0, 1.0},
	)
	back_mat: Material
	back_mat.amb = rl.Vector3(1.0)
	back_mat.dif = rl.Vector3(0.0)
	back_mat.spec = rl.Vector3(0.0)
	back_mat.alpha = 10.0
	back_mat.reflection = 0.0


	back := Object {
		material   = back_mat,
		shape      = back_shape,
		ambTexture = backTexture,
		difTexture = backTexture,
	}

	append(&raytracer.objs, back)
}

FindClosestCollision :: proc(objs: [dynamic]Object, ray: Ray) -> Hit {
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
				closestHit.uv = hit.uv
			}
		}
	}
	return closestHit

}

TraceRay :: proc(raytracer: Raytracer, ray: Ray, recursive: i32) -> rl.Vector3 {
	objs := raytracer.objs

	hit := FindClosestCollision(objs, ray)

	if hit.d >= 0.0 {
		phongcolor: rl.Vector3
		color: rl.Vector3

		toLight := raytracer.pos - hit.point
		distToLight := rl.Vector3Length(toLight)
		dirToLight := toLight / distToLight

		shadowRay: Ray = {
			start = hit.point + dirToLight * 1e-4,
			dir   = dirToLight,
		}

		shadowHit := FindClosestCollision(objs, shadowRay)

		// if shadowHit.d < 0.0 {
		if true {

			// ambient
			if hit.obj.ambTexture != nil {
				phongcolor = hit.obj.amb * SampleLinear(hit.obj.ambTexture^, hit.uv)
			} else {
				phongcolor = hit.obj.amb
			}
			// diffuse
			diff := max(linalg.dot(hit.normal, dirToLight), 0.0)

			// specular
			dirToReflect := 2.0 * linalg.dot(hit.normal, dirToLight) * hit.normal - dirToLight
			spec := math.pow(max(linalg.dot(-ray.dir, dirToReflect), 0.0), hit.obj.alpha)

			if hit.obj.difTexture != nil {
				phongcolor += diff * hit.obj.dif * SampleLinear(hit.obj.difTexture^, hit.uv)
			} else {
				phongcolor += diff * hit.obj.dif
			}

			phongcolor += hit.obj.spec * spec

			color += phongcolor * (1.0 - hit.obj.reflection - hit.obj.transparency)

			if hit.obj.reflection > 0 {
				reflectedDirection := rl.Vector3Normalize(
					hit.normal * 2.0 * rl.Vector3DotProduct(-ray.dir, hit.normal) + ray.dir,
				)
				reflectionRay: Ray = {hit.point + reflectedDirection * 1e-4, reflectedDirection}
				color += TraceRay(raytracer, reflectionRay, recursive - 1) * hit.obj.reflection
			}

			if hit.obj.transparency > 0 {
				ior := f32(1.5)
				eta: f32
				normal: rl.Vector3

				if rl.Vector3DotProduct(ray.dir, hit.normal) < 0.0 {
					// 밖 -> 안

					eta = ior
					normal = hit.normal
				} else {
					// 안 -> 밖

					eta = 1.0 / ior
					normal = -hit.normal
				}
				cosTheta1 := rl.Vector3DotProduct(-ray.dir, normal)
				sinthetaSquare := 1 - cosTheta1 * cosTheta1
				sinTheta1 := linalg.sqrt(sinthetaSquare)
				sinTheta2 := sinTheta1 / eta
				cosTheta2Square := 1 - sinTheta2 * sinTheta2
				cosTheta2 := linalg.sqrt(cosTheta2Square)

				a, b, m, t: rl.Vector3
				m = rl.Vector3Normalize(rl.Vector3DotProduct(-ray.dir, normal) * normal + ray.dir)
				a = m * sinTheta2
				b = -normal * cosTheta2

				t = rl.Vector3Normalize(a + b)
				refactionRay: Ray = {hit.point + t * 1e-4, t}

				color += TraceRay(raytracer, refactionRay, recursive - 1) * hit.obj.transparency
			}
		}
		return color
	}
	return rl.Vector3(0)
}


Render :: proc(raytracer: Raytracer, pixels: []rl.Vector4) {
	slice.fill(pixels, rl.Vector4{0.0, 0.0, 0.0, 1.0})

	eyePos := rl.Vector3{0.0, 0.0, -1.5}

	dx: f32 = 2.0 / f32(raytracer.height)

	for j in 0 ..< raytracer.height {
		for i in 0 ..< raytracer.width {
			pixelPosWorld: rl.Vector3 = TransformScreenToWorld(raytracer, {f32(i), f32(j)})

			pixelRay: Ray = {pixelPosWorld, rl.Vector3Normalize(pixelPosWorld - eyePos)}

			clamp := rl.Vector3Clamp(TraceRay(raytracer, pixelRay, 5), 0, 1)
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
