package main
import "core:math/linalg"
import rl "vendor:raylib"


Sphere :: struct {
	center: rl.Vector3,
	radius: f32,
	amb:    rl.Vector3,
	dif:    rl.Vector3,
	spec:   rl.Vector3,
	ks:     f32,
	alpha:  f32,
}

MakeSphere :: proc(center: rl.Vector3, radius: f32) -> Sphere {
	sphere: Sphere = {
		center = center,
		radius = radius,
		amb    = rl.Vector3(0),
		dif    = rl.Vector3(0),
		spec   = rl.Vector3(0),
		ks     = 0.0,
		alpha  = 0.0,
	}

	return sphere
}

IntersectRayCollision :: proc(sphere: Sphere, ray: Ray) -> Hit {
	hit: Hit = {-1.0, rl.Vector3(0), rl.Vector3(0)}

	oc := ray.start - sphere.center
	uoc := linalg.dot(ray.dir, oc)
	oc2 := linalg.dot(oc, oc)
	radiusSpuare := sphere.radius * sphere.radius
	det := uoc * uoc - (oc2 - radiusSpuare)

	if det >= 0 {
		d1 := -uoc + det
		d2 := -uoc - det

		hit.d = min(d1, d2)
		hit.point = ray.start + ray.dir * hit.d
		hit.normal = rl.Vector3Normalize(hit.point - sphere.center)
	}
	return hit
}
