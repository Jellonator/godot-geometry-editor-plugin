#include "brush_data.hpp"

using namespace godot;

BrushMesh::BrushMesh()
: m_next_free_vert_id(1)
, m_next_free_edge_id(1)
, m_next_free_loop_id(1)
, m_next_free_face_id(1)
{ }

void BrushMesh::rebuild_complete_cache()
{
    // TODO
}

void BrushMesh::_bind_methods()
{
    // TODO
}

BrushMesh::~BrushMesh() { }

identifier_t BrushMesh::make_vertex(const Vector3 point) {
    identifier_t i = m_next_free_vert_id;
    ++m_next_free_vert_id;
    m_vertices.insert(i, {.position = point});
    return i;
}

identifier_t BrushMesh::make_edge(identifier_t vertex1, identifier_t vertex2) {
    identifier_t i = m_next_free_edge_id;
    ++m_next_free_vert_id;
    m_edges.insert(i, {.vertices = {vertex1, vertex2}});
    return i;
}

identifier_t BrushMesh::make_loop(identifier_t vertex, identifier_t edge) {
    identifier_t i = m_next_free_edge_id;
    ++m_next_free_vert_id;
    m_loops.insert(i, {.vertex = vertex, .edge = edge});
    return i;
}

identifier_t BrushMesh::make_face() {
    identifier_t i = m_next_free_edge_id;
    ++m_next_free_vert_id;
    m_faces.insert(i, {});
    return i;
}

void BrushMesh::get_edge_vertices(identifier_t edge) {
    // TODO
}

int32_t BrushMesh::_get_surface_count() const
{
    return 0;
}

int32_t BrushMesh::_surface_get_array_len(int32_t index) const
{
    return 0;
}

int32_t BrushMesh::_surface_get_array_index_len(int32_t index) const
{
    return 0;
}

Array BrushMesh::_surface_get_arrays(int32_t index) const
{
    godot::Array arr;
    return arr;
}

TypedArray<Array> BrushMesh::_surface_get_blend_shape_arrays(int32_t index) const
{
    TypedArray<Array>  arr;
    return arr;
}

Dictionary BrushMesh::_surface_get_lods(int32_t index) const
{
    Dictionary d;
    return d;
}

uint32_t BrushMesh::_surface_get_format(int32_t index) const
{
    return ARRAY_FORMAT_VERTEX | ARRAY_FORMAT_INDEX;
}

uint32_t BrushMesh::_surface_get_primitive_type(int32_t index) const
{
    return PRIMITIVE_TRIANGLES;
}

void BrushMesh::_surface_set_material(int32_t index, const Ref<Material> &material)
{

}

Ref<Material> BrushMesh::_surface_get_material(int32_t index) const
{
    return nullptr;
}

int32_t BrushMesh::_get_blend_shape_count() const
{
    return 0;
}

StringName BrushMesh::_get_blend_shape_name(int32_t index) const
{
    return "";
}

void BrushMesh::_set_blend_shape_name(int32_t index, const StringName &name)
{

}

AABB BrushMesh::_get_aabb() const
{
    return AABB();
}
