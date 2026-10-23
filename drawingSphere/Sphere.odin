package main
import "core:math/linalg"
import rl "vendor:raylib"

Sphere :: struct {
	center: rl.Vector3,
	radius: f32,
	color:  rl.Vector3,
}


Intersect_ray_collision :: proc(sphere: Sphere, ray: Ray) -> Hit {
	hit: Hit = {
		d      = -1.0,
		point  = {0.0, 0.0, 0.0},
		normal = {0.0, 0.0, 0.0},
	}

	uoc := linalg.dot(ray.dir, ray.start - sphere.center)
	oc2 := linalg.dot(ray.start - sphere.center, ray.start - sphere.center)
	nebular := uoc * uoc - (oc2 - sphere.radius * sphere.radius)
	if nebular >= 0 {
		d1 := -uoc + linalg.sqrt(nebular)
		d2 := -uoc - linalg.sqrt(nebular)
		hit.d = min(d1, d2)
		hit.point = ray.start + hit.d * ray.dir
		hit.normal = linalg.normalize(hit.point - sphere.center)
	}
	return hit
}
