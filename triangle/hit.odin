package main

import rl "vendor:raylib"

Hit :: struct {
	d:      f32,
	point:  rl.Vector3,
	normal: rl.Vector3,
	obj:    Object,
}

CheckRayCollision :: proc(obj: Object, ray: Ray) -> Hit {
	hit := Hit {
		d = -1,
	}
	switch s in obj.shape {
	case Sphere:
		hit = CheckRayCollisionPointSphere(s, ray)
	case Triangle:
		hit = CheckRayCollisionPointTriangle(s, ray)
	}

	hit.obj = obj
	return hit
}
