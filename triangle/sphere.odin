package main
import "core:math/linalg"
import rl "vendor:raylib"


Sphere :: struct {
	center: rl.Vector3,
	radius: f32,
}

MakeSphere :: proc(center: rl.Vector3, radius: f32, color: rl.Vector3) -> Sphere {
	object := MakeObject(color = color)
	sphere: Sphere = {
		center = center,
		radius = radius,
	}
	return sphere
}

CheckRayCollisionPointSphere :: proc(sphere: Sphere, ray: Ray) -> Hit {
	hit: Hit = {
		d = -1.0,
	}

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
