#pragma once

#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/material.hpp>
#include <godot_cpp/variant/builtin_types.hpp>

#include <godot_cpp/templates/hash_map.hpp>

#include <cassert>
#include <type_traits>
#include <iterator>
#include <algorithm>
#include <span>

typedef int32_t identifier_t;

const static identifier_t NIL_ID = -1;

constexpr bool is_valid_identifier(identifier_t i) {
	return i >= 0;
}

class BrushData : public godot::Resource {
	GDCLASS(BrushData, godot::Resource);

public:
	enum BrushComponent {
		BRUSH_COMPONENT_VERTEX = 0,
		BRUSH_COMPONENT_EDGE = 1,
		BRUSH_COMPONENT_FACE = 2,
		BRUSH_COMPONENT_LOOP = 3
	};

private:

	// Actual data

	godot::PackedVector3Array m_vertex_positions;

	godot::PackedInt32Array m_edge_vertex_id1;
	godot::PackedInt32Array m_edge_vertex_id2;

	godot::PackedInt32Array m_loop_edge_id;
	godot::PackedInt32Array m_loop_vertex_id;

	godot::PackedInt32Array m_face_loop_start_id;
	godot::PackedInt32Array m_face_loop_count;
	godot::PackedInt32Array m_face_surface_id;

	godot::TypedArray<godot::Material> m_surface_materials;

protected:
	static void _bind_methods();

public:
	BrushData();
	~BrushData();

	// API

	uint32_t add_surface(godot::Ref<godot::Material> material);
	void set_surface_material(uint32_t i, godot::Ref<godot::Material> material);
	godot::Ref<godot::Material> get_surface_material(uint32_t i);

	godot::PackedVector3Array gd_get_vertex_positions();
	void gd_set_vertex_positions(godot::PackedVector3Array v);
	godot::PackedInt32Array gd_get_edge_vertex_id1();
	void gd_set_edge_vertex_id1(godot::PackedInt32Array v);
	godot::PackedInt32Array gd_get_edge_vertex_id2();
	void gd_set_edge_vertex_id2(godot::PackedInt32Array v);
	godot::PackedInt32Array gd_get_loop_edge_id();
	void gd_set_loop_edge_id(godot::PackedInt32Array v);
	godot::PackedInt32Array gd_get_loop_vertex_id();
	void gd_set_loop_vertex_id(godot::PackedInt32Array v);
	godot::PackedInt32Array gd_get_face_loop_start_id();
	void gd_set_face_loop_start_id(godot::PackedInt32Array v);
	godot::PackedInt32Array gd_get_face_loop_count();
	void gd_set_face_loop_count(godot::PackedInt32Array v);
	godot::PackedInt32Array gd_get_face_surface_id();
	void gd_set_face_surface_id(godot::PackedInt32Array v);

	godot::TypedArray<godot::Material> gd_get_surface_materials();
	void gd_set_surface_materials(godot::TypedArray<godot::Material> v);

	// MESH API

	int32_t gd_get_surface_count() const;
	godot::Array gd_get_array_for_surface(int32_t index) const;
	godot::AABB gd_compute_aabb() const;
};

VARIANT_ENUM_CAST(BrushData::BrushComponent);
