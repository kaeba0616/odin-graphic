package main

import "core:math/linalg"
import rl "vendor:raylib"

Triangle :: struct {
	v0, v1, v2: rl.Vector3,
}

InitTriangle :: proc() -> Triangle {
	return Triangle{v0 = rl.Vector3(0), v1 = rl.Vector3(0), v2 = rl.Vector3(0)}
}

MakeTriangle :: proc(v0: rl.Vector3, v1: rl.Vector3, v2: rl.Vector3) -> Triangle {
	return Triangle{v0 = v0, v1 = v1, v2 = v2}
}

CheckRayCollisionPointTriangle :: proc(triangle: Triangle, ray: Ray) -> Hit {

	hit := Hit {
		d = -1.0,
	}

	isHit, point, faceNormal, t, w0, w1 := IntersectRayTriangle(
		ray.start,
		ray.dir,
		triangle.v0,
		triangle.v1,
		triangle.v2,
	)

	if isHit {
		hit.d = t
		hit.point = point
		hit.normal = faceNormal
		hit.w = rl.Vector2{w0, w1}
	}
	return hit
}

IntersectRayTriangle :: proc(
	orig: rl.Vector3,
	dir: rl.Vector3,
	v0: rl.Vector3,
	v1: rl.Vector3,
	v2: rl.Vector3,
) -> (
	hit: bool,
	point: rl.Vector3,
	faceNormal: rl.Vector3,
	t, w0, w1: f32,
) {
	/*
	 * 기본 전략
	 * - 삼각형이 놓여있는 평면과 광선의 교점을 찾고,
	 * - 그 교점이 삼각형 안에 있는지 밖에 있는지를 판단한다.
	 */
	/* 1. 삼각형이 놓여 있는 평면의 수직 벡터 계산 */
	faceNormal = rl.Vector3Normalize(rl.Vector3CrossProduct(v1 - v0, v2 - v1))

	// 삼각형 뒷면을 그리고 싶지 않은 경우 (Backface culling)
	// 광선의 방향 (dir)이 삼각형 뒷면에서 올때!
	if linalg.dot(-dir, faceNormal) < 0.0 do return

	// 평면과 광선이 수평에 매우 가깝다면 충돌하지 못하는 것으로 판단
	if abs(linalg.dot(dir, faceNormal)) < 1e-2 do return

	/* 2. 광선과 평면의 충돌 위치 계산 */
	t = linalg.dot(v1 - orig, faceNormal) / linalg.dot(dir, faceNormal)

	// 광선의 시작점 이전에 충돌한다면 렌더링할 필요 없음
	if t < 0.0 do return

	point = orig + t * dir

	/* 3. 그 충돌 위치가 삼각형 안에 들어 있는 지 확인 */
	// 작은 삼각형들 3개의 normal 계산

	cross0 := rl.Vector3CrossProduct(v2 - v1, point - v1)
	cross1 := rl.Vector3CrossProduct(point - v0, v2 - v0)
	cross2 := rl.Vector3CrossProduct(point - v1, v0 - v1)

	normal0 := rl.Vector3Normalize(cross0)
	normal1 := rl.Vector3Normalize(cross1)
	normal2 := rl.Vector3Normalize(cross2)


	// 방향만 확인하면 되기 때문에 normalize() 생략 가능
	// 아래에서 cross product의 절대값으로 작은 삼각형들의 넓이 계산
	if linalg.dot(normal0, faceNormal) < 0.0 do return
	if linalg.dot(normal1, faceNormal) < 0.0 do return
	if linalg.dot(normal2, faceNormal) < 0.0 do return


	// Barycentric coordinates 계산
	// 텍스춰링(texturing)에서 사용
	area0: f32 = rl.Vector3Length(cross0) * 0.5
	area1: f32 = rl.Vector3Length(cross1) * 0.5
	area2: f32 = rl.Vector3Length(cross2) * 0.5

	areaSum := area0 + area1 + area2

	w0 = f32(area0) / f32(areaSum)
	w1 = f32(area1) / f32(areaSum)

	hit = true
	return
}
