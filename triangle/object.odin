package main

import rl "vendor:raylib"

Object :: struct {
	using material: Material,
	shape:          Shape,
}

MakeObject :: proc(color: rl.Vector3) -> Object {
	object: Object = {
		material = MakeMaterial(color),
	}
	return object
}
