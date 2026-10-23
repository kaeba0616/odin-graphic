package main

import rl "vendor:raylib"

Object :: struct {
	amb:   rl.Vector3,
	diff:  rl.Vector3,
	spec:  rl.Vector3,
	alpha: f32,
}

MakeObject :: proc(color: rl.Vector3) -> Object {
	return {color, color, color, 10.0}
}
