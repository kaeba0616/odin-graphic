package main

import rl "vendor:raylib"

Hit :: struct {
	d:         f32,
	point:     rl.Vector3,
	normal:    rl.Vector3,
	using obj: Object,
}
