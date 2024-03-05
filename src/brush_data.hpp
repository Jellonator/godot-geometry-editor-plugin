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

const identifier_t NIL_ID = -1;

constexpr bool is_valid_identifier(identifier_t i) {
	return i >= 0;
}

/// @brief Position in 3D space
struct VertexData {
	godot::Vector3 position;
};

/// @brief Connection between two vertices
struct EdgeData {
	std::array<identifier_t, 2> vertices;

	inline bool has_vertex(identifier_t v) const {
		return vertices[0] == v || vertices[1] == v;
	}
};

/// @brief Connection of a vertex to an edge within the context of a face
struct LoopData {
	identifier_t vertex;
	identifier_t edge;
};

/// @brief Connection of multiple loops into a single face
struct FaceData {
	std::vector<identifier_t> loops;
	uint32_t surface;
};

/// @brief Collection of faces under one material
struct SurfaceData {
	godot::Ref<godot::Material> material;
};

class BrushData : public godot::Resource {
	GDCLASS(BrushData, godot::Resource);

	inline void assert_vertex_id(identifier_t i) const {
		assert(m_vertices.has(i));
	}

	inline void assert_edge_id(identifier_t i) const {
		assert(m_edges.has(i));
	}

	inline void assert_loop_id(identifier_t i) const {
		assert(m_loops.has(i));
	}

	inline void assert_face_id(identifier_t i) const {
		assert(m_faces.has(i));
	}

	identifier_t m_next_free_vert_id;
	identifier_t m_next_free_face_id;
	identifier_t m_next_free_loop_id;
	identifier_t m_next_free_edge_id;

	// Actual data

	godot::HashMap<identifier_t, VertexData> m_vertices;
	godot::HashMap<identifier_t, LoopData> m_loops;
	godot::HashMap<identifier_t, EdgeData> m_edges;
	godot::HashMap<identifier_t, FaceData> m_faces;
	std::vector<SurfaceData> m_surfaces;

	// Indices

	struct VertexCache {
		std::vector<identifier_t> edges;
	};
	struct EdgeCache {
		std::vector<identifier_t> loops;
	};
	struct LoopCache {
		std::vector<identifier_t> faces;
	};
	struct SurfaceCache {
		std::vector<identifier_t> faces;
	};
	godot::HashMap<identifier_t, VertexCache> m_vertexcache;
	godot::HashMap<identifier_t, EdgeCache> m_edgecache;
	godot::HashMap<identifier_t, LoopCache> m_loopcache;
	std::vector<SurfaceCache> m_surfacecache;

protected:
	static void _bind_methods();

public:
	BrushData();
	~BrushData();

	// API

	identifier_t make_vertex(const godot::Vector3 point);
	identifier_t make_edge(identifier_t vertex1, identifier_t vertex2);
	identifier_t make_loop(identifier_t vertex, identifier_t edge);
	identifier_t make_face(std::vector<identifier_t>&& loops, uint32_t surface);

	identifier_t get_edge_between(identifier_t vertex1, identifier_t vertex2) const;
	inline bool has_edge(identifier_t vertex1, identifier_t vertex2) const {
		return is_valid_identifier(get_edge_between(vertex1, vertex2));
	}
	std::array<identifier_t, 2> get_edge_vertices(identifier_t edge) const;

	identifier_t make_face_from_vertices(std::span<const identifier_t> vertices, uint32_t surface);
	void set_face_surface(identifier_t face, uint32_t surface);
	uint32_t get_face_surface(identifier_t face) const;

	uint32_t add_surface(godot::Ref<godot::Material> material);
	void set_surface_material(uint32_t i, godot::Ref<godot::Material> material);
	godot::Ref<godot::Material> get_surface_material(uint32_t i);

	// EDITOR API

	godot::PackedInt32Array gd_get_vertex_ids() const;
	int64_t gd_make_vertex(godot::Vector3 position);
	godot::Vector3 gd_get_vertex_position(int64_t id) const;
	void gd_set_vertex_position(int64_t id, godot::Vector3 position);

	// MESH API

	int32_t gd_get_surface_count() const;
	godot::Array gd_get_array_for_surface(int32_t index) const;
	godot::AABB gd_compute_aabb() const;
};