package main
import "core:fmt"
import "core:image/tga"
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
	raytracer.light = Light{{0.0, 1.0, 0.5}}

	sphere_mat: Material
	sphere_mat.amb = {0.2, 0.0, 0.0}
	sphere_mat.dif = {1.0, 0.1, 0.1}
	sphere_mat.spec = rl.Vector3(1.5)
	sphere_mat.alpha = 50.0

	sphere := Object {
		material = sphere_mat,
		shape = Sphere{center = {0.0, 0.0, 0.6}, radius = 0.4},
	}

	append(&raytracer.objs, sphere)

	textureImage: [4 * 4]rl.Vector3
	for j in 0 ..< 4 {
		for i in 0 ..< 4 {
			if i % 4 == 0 {
				textureImage[i + 4 * j] = rl.Vector3{1.0, 0.0, 0.0} * (1.0 + f32(j)) * 0.25
			}
			if i % 4 == 1 {
				textureImage[i + 4 * j] = rl.Vector3{0.0, 1.0, 0.0} * (1.0 + f32(j)) * 0.25
			}
			if i % 4 == 2 {
				textureImage[i + 4 * j] = rl.Vector3{0.0, 0.0, 1.0} * (1.0 + f32(j)) * 0.25
			}
			if i % 4 == 3 {
				textureImage[i + 4 * j] = rl.Vector3{1.0, 1.0, 1.0} * (1.0 + f32(j)) * 0.25
			}
		}
	}
	imageTexture := new(Texture)
	ok: bool

	//imageTexture^ = MakeTextureFromPixels(4, 4, textureImage[:])
	imageTexture^, ok = MakeTextureFromFile("shadertoy_abstract1.png")

	square_shape := InitSquare(
		rl.Vector3{-2.0, 2.0, 2.0},
		rl.Vector3{2.0, 2.0, 2.0},
		rl.Vector3{2.0, -2.0, 2.0},
		rl.Vector3{-2.0, -2.0, 2.0},
		rl.Vector2{0.0, 0.0},
		rl.Vector2{4.0, 0.0},
		rl.Vector2{4.0, 4.0},
		rl.Vector2{0.0, 4.0},
	)
	square_mat: Material
	square_mat.amb = rl.Vector3(0.0)
	square_mat.dif = rl.Vector3(1.0)
	square_mat.spec = rl.Vector3(0.0)

	square := Object {
		material   = square_mat,
		shape      = square_shape,
		ambTexture = imageTexture,
		difTexture = imageTexture,
	}

	append(&raytracer.objs, square)

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

TraceRay :: proc(raytracer: Raytracer, ray: Ray) -> rl.Vector3 {
	objs := raytracer.objs

	hit := FindClosestCollision(objs, ray)

	if hit.d >= 0.0 {
		color: rl.Vector3

		toLight := raytracer.pos - hit.point
		distToLight := rl.Vector3Length(toLight)
		dirToLight := toLight / distToLight

		shadowRay: Ray = {
			start = hit.point + dirToLight * 1e-4,
			dir   = dirToLight,
		}

		shadowHit := FindClosestCollision(objs, shadowRay)

		if shadowHit.d < 0.0 || shadowHit.d > distToLight {

			// ambient
			if hit.obj.ambTexture != nil {
				color = hit.obj.amb * SampleLinear(hit.obj.ambTexture^, hit.uv)
			} else {
				color = hit.obj.amb
			}
			// diffuse
			diff := max(linalg.dot(hit.normal, dirToLight), 0.0)

			// specular
			dirToReflect := 2.0 * linalg.dot(hit.normal, dirToLight) * hit.normal - dirToLight
			spec := math.pow(max(linalg.dot(-ray.dir, dirToReflect), 0.0), hit.obj.alpha)

			if hit.obj.difTexture != nil {
				color += diff * hit.obj.dif * SampleLinear(hit.obj.difTexture^, hit.uv)
			} else {
				color += diff * hit.obj.dif
			}

			color += hit.obj.spec * spec
		}
		return color
	}
	return rl.Vector3(0)
}


Render :: proc(raytracer: Raytracer, pixels: []rl.Vector4) {
	slice.fill(pixels, rl.Vector4{0.0, 0.0, 0.0, 1.0})

	eyePos := rl.Vector3{0.0, 0.0, -1.5}

	for j in 0 ..< raytracer.height {
		for i in 0 ..< raytracer.width {
			pixelPosWorld: rl.Vector3 = TransformScreenToWorld(raytracer, {f32(i), f32(j)})

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
