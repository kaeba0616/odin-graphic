package main

import rl "vendor:raylib"

Object :: struct {
	amb:   rl.Vector3,
	dif:   rl.Vector3,
	spec:  rl.Vector3,
	alpha: f32,
	ks:    f32,
}

MakeObject :: proc(color: rl.Vector3) -> Object {
	object: Object = {
		amb   = color,
		dif   = color,
		spec  = color,
		alpha = 10.0,
		ks    = 1.0,
	}
	return object
}
