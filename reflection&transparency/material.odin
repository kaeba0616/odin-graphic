package main

import rl "vendor:raylib"

Material :: struct {
	amb, dif, spec: rl.Vector3,
	alpha:          f32,
	ks:             f32,
	reflection:     f32,
	transparency:   f32,
}

MakeMaterial :: proc(color: rl.Vector3) -> Material {
	return {amb = color, dif = color, spec = color, alpha = 10.0, ks = 1.0}
}
