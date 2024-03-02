#pragma once

#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/material.hpp>
#include <godot_cpp/variant/builtin_types.hpp>

#include <godot_cpp/templates/hash_map.hpp>

#include <cassert>

typedef uint64_t identifier_t;

/// @brief Position in 3D space
struct VertexData {
	godot::Vector3 position;
};

/// @brief Connection between two vertices
struct EdgeData {
	identifier_t vertices[2];
};

/// @brief Connection of a vertex to an edge within the context of a face
struct LoopData {
	identifier_t vertex;
	identifier_t edge;
};

/// @brief Connection of multiple loops into a single face
struct FaceData {
	std::vector<identifier_t> loops;
};

class BrushMesh : public godot::Mesh {
	GDCLASS(BrushMesh, godot::Mesh);

	inline void assert_vertex_id(identifier_t i) {
		assert(m_vertices.has(i));
	}

	inline void assert_edge_id(identifier_t i) {
		assert(m_edges.has(i));
	}

	inline void assert_loop_id(identifier_t i) {
		assert(m_loops.has(i));
	}

	inline void assert_face_id(identifier_t i) {
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

	// Indices

	struct VertexCache {
		std::vector<identifier_t> edges;
	};
	struct EdgeCache {
		std::vector<identifier_t> loops;
	};
	struct LoopCache {
		identifier_t opposing_loop;
		std::vector<identifier_t> faces;
	};
	godot::HashMap<identifier_t, VertexCache> m_vertexcache;
	godot::HashMap<identifier_t, EdgeCache> m_edgecache;
	godot::HashMap<identifier_t, LoopCache> m_loopcache;
	void rebuild_complete_cache();

protected:
	static void _bind_methods();

public:
	BrushMesh();
	~BrushMesh();

	// API

	identifier_t make_vertex(const godot::Vector3 point);
	identifier_t make_edge(identifier_t vertex1, identifier_t vertex2);
	identifier_t make_loop(identifier_t vertex, identifier_t edge);
	identifier_t make_face();

	void get_edge_vertices(identifier_t edge);

	// VIRTUAL METHOD IMPLEMENTATIONS

	int32_t _get_surface_count() const override;
	int32_t _surface_get_array_len(int32_t index) const override;
	int32_t _surface_get_array_index_len(int32_t index) const override;
	godot::Array _surface_get_arrays(int32_t index) const override;
	godot::TypedArray<godot::Array> _surface_get_blend_shape_arrays(int32_t index) const override;
	godot::Dictionary _surface_get_lods(int32_t index) const override;
	uint32_t _surface_get_format(int32_t index) const override;
	uint32_t _surface_get_primitive_type(int32_t index) const override;
	void _surface_set_material(int32_t index, const godot::Ref<godot::Material> &material) override;
	godot::Ref<godot::Material> _surface_get_material(int32_t index) const override;
	int32_t _get_blend_shape_count() const override;
	godot::StringName _get_blend_shape_name(int32_t index) const override;
	void _set_blend_shape_name(int32_t index, const godot::StringName &name) override;
	godot::AABB _get_aabb() const override;
};