package main
import rl "vendor:raylib"

Square :: struct {
	triangle1: Triangle,
	triangle2: Triangle,
}

InitSquare :: proc(v0: rl.Vector3, v1: rl.Vector3, v2: rl.Vector3, v3: rl.Vector3) -> Square {
	triangle1 := MakeTriangle(v0, v1, v2)
	triangle2 := MakeTriangle(v0, v2, v3)
	return {triangle1, triangle2}
}

CheckRayCollisionPointSquare :: proc(square: Square, ray: Ray) -> Hit {
	hit1 := CheckRayCollisionPointTriangle(square.triangle1, ray)
	hit2 := CheckRayCollisionPointTriangle(square.triangle2, ray)

	if hit1.d >= 0.0 && hit2.d >= 0.0 {
		return hit1.d < hit2.d ? hit1 : hit2
	} else if hit1.d >= 0.0 {
		return hit1
	} else {
		return hit2
	}
}
