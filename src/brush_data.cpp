#include "brush_data.hpp"

#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/rendering_server.hpp>

using namespace godot;

BrushData::BrushData()
: Resource()
, m_next_free_vert_id(1)
, m_next_free_edge_id(1)
, m_next_free_loop_id(1)
, m_next_free_face_id(1)
{
    // make a cube
    real_t s = 0.5;
    identifier_t verts[8];
    verts[0] = make_vertex(Vector3(-s, -s, -s));
    verts[1] = make_vertex(Vector3(-s, -s, +s));
    verts[2] = make_vertex(Vector3(-s, +s, -s));
    verts[3] = make_vertex(Vector3(-s, +s, +s));
    verts[4] = make_vertex(Vector3(+s, -s, -s));
    verts[5] = make_vertex(Vector3(+s, -s, +s));
    verts[6] = make_vertex(Vector3(+s, +s, -s));
    verts[7] = make_vertex(Vector3(+s, +s, +s));
    uint32_t surf = add_surface({});
    make_face_from_vertices({{verts[4], verts[5], verts[7], verts[6]}}, surf);
    make_face_from_vertices({{verts[0], verts[2], verts[3], verts[1]}}, surf);
    make_face_from_vertices({{verts[2], verts[6], verts[7], verts[3]}}, surf);
    make_face_from_vertices({{verts[0], verts[1], verts[5], verts[4]}}, surf);
    make_face_from_vertices({{verts[1], verts[3], verts[7], verts[5]}}, surf);
    make_face_from_vertices({{verts[0], verts[4], verts[6], verts[2]}}, surf);
}

BrushData::~BrushData() { }

void BrushData::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("get_vertex_ids"), &BrushData::gd_get_vertex_ids);
    ClassDB::bind_method(D_METHOD("get_vertex_position", "id"), &BrushData::gd_get_vertex_position);
    ClassDB::bind_method(D_METHOD("set_vertex_position", "id", "position"), &BrushData::gd_set_vertex_position);
    ClassDB::bind_method(D_METHOD("make_vertex", "position"), &BrushData::gd_make_vertex);
    ClassDB::bind_method(D_METHOD("get_surface_material", "surface"), &BrushData::get_surface_material );
    ClassDB::bind_method(D_METHOD("set_surface_material", "surface", "material"), &BrushData::set_surface_material );
    ClassDB::bind_method(D_METHOD("add_surface", "material"), &BrushData::add_surface );
    ClassDB::bind_method(D_METHOD("get_surface_count"), &BrushData::gd_get_surface_count );
    ClassDB::bind_method(D_METHOD("compute_array_for_surface", "surface"), &BrushData::gd_get_array_for_surface );
    ClassDB::bind_method(D_METHOD("compute_aabb"), &BrushData::gd_compute_aabb);

    ADD_SIGNAL(MethodInfo("vertex_updated", PropertyInfo(Variant::INT, "vertex")));
}

identifier_t BrushData::make_vertex(const Vector3 point) {
    identifier_t i = m_next_free_vert_id;
    ++m_next_free_vert_id;
    m_vertices.insert(i, {.position = point});
    m_vertexcache.insert(i, {});
    return i;
}

identifier_t BrushData::make_edge(identifier_t vertex1, identifier_t vertex2) {
    identifier_t i = m_next_free_edge_id;
    ++m_next_free_edge_id;
    m_edges.insert(i, {.vertices = {vertex1, vertex2}});
    m_edgecache.insert(i, {});
    m_vertexcache[vertex1].edges.push_back(i);
    m_vertexcache[vertex2].edges.push_back(i);
    return i;
}

identifier_t BrushData::make_loop(identifier_t vertex, identifier_t edge) {
    identifier_t i = m_next_free_loop_id;
    ++m_next_free_loop_id;
    m_loops.insert(i, {.vertex = vertex, .edge = edge});
    m_loopcache.insert(i, {});
    m_edgecache[edge].loops.push_back(i);
    return i;
}

identifier_t BrushData::make_face(std::vector<identifier_t>&& loops, uint32_t surface) {
    identifier_t i = m_next_free_face_id;
    ++m_next_free_face_id;
    m_faces.insert(i, {.loops = loops, .surface = surface});
    m_surfacecache[surface].faces.push_back(i);
    for (const auto& loop : loops) {
        m_loopcache[loop].faces.push_back(i);
    }
    return i;
}

identifier_t BrushData::get_edge_between(identifier_t vertex1, identifier_t vertex2) const {
    for (identifier_t edge : m_vertexcache[vertex1].edges) {
        if (m_edges[edge].has_vertex(vertex2)) return edge;
    }
    return NIL_ID;
}

identifier_t BrushData::make_face_from_vertices(std::span<const identifier_t> vertices, uint32_t surface)
{
    if (vertices.size() < 3) return NIL_ID;
    std::vector<identifier_t> loops;
    identifier_t prev_id = vertices.back();
    for (int i = 0; i < vertices.size(); i++) {
        identifier_t cur_id = vertices[i];
        identifier_t edge = get_edge_between(prev_id, cur_id);
        if (!is_valid_identifier(edge)) {
            edge = make_edge(prev_id, cur_id);
        }
        loops.push_back(make_loop(prev_id, edge));
        prev_id = cur_id;
    }
    return make_face(std::move(loops), surface);
}

std::array<identifier_t, 2> BrushData::get_edge_vertices(identifier_t edge) const {
    return m_edges[edge].vertices;
}

void BrushData::set_face_surface(identifier_t face, uint32_t surface)
{
    m_faces[face].surface = surface;
}

uint32_t BrushData::get_face_surface(identifier_t face) const
{
    return m_faces[face].surface;
}

uint32_t BrushData::add_surface(godot::Ref<godot::Material> material)
{
    m_surfaces.push_back({.material = material});
    m_surfacecache.push_back({});
    return m_surfaces.size() - 1;
}

void BrushData::set_surface_material(uint32_t i, godot::Ref<godot::Material> material)
{
    m_surfaces[i].material = material;
}

godot::Ref<godot::Material> BrushData::get_surface_material(uint32_t i)
{
    return m_surfaces[i].material;
}

/* GDSCRIPT API */

godot::PackedInt32Array BrushData::gd_get_vertex_ids() const
{
    godot::PackedInt32Array vec;
    for (const auto& pair : m_vertices) {
        vec.append(pair.key);
    }
    return vec;
}

int64_t BrushData::gd_make_vertex(godot::Vector3 position)
{
    return make_vertex(position);
}

godot::Vector3 BrushData::gd_get_vertex_position(int64_t id) const
{
    assert_vertex_id(id);
    return m_vertices[id].position;
}

void BrushData::gd_set_vertex_position(int64_t id, godot::Vector3 position)
{
    std::cout << "UPD " << id << std::endl;
    assert_vertex_id(id);
    std::cout << "A" << std::endl;
    m_vertices[id].position = position;

    emit_signal("vertex_updated", id);
}

int32_t BrushData::gd_get_surface_count() const
{
    return m_surfaces.size();
}

Array BrushData::gd_get_array_for_surface(int32_t index) const
{
    ERR_FAIL_INDEX_V(index, m_surfaces.size(), {});
    // TODO: only surfaces for index
    godot::Array arr;
    arr.resize(godot::Mesh::ARRAY_MAX);
    godot::HashMap<identifier_t, size_t> vertex_index_map;
    godot::PackedVector3Array arr_vertices;
    godot::PackedVector3Array arr_normals;
    for (const auto& vert : m_loops) {
        vertex_index_map.insert(vert.key, arr_vertices.size());
        arr_vertices.push_back(m_vertices[vert.value.vertex].position);
        arr_normals.push_back(Vector3(1, 1, 1).normalized());
    }
    godot::PackedInt32Array arr_indices;
    for (const auto& face : m_faces) {
        for (int i = 1; i < face.value.loops.size() - 1; i++) {
            arr_indices.push_back(vertex_index_map[face.value.loops[0]]);
            arr_indices.push_back(vertex_index_map[face.value.loops[i]]);
            arr_indices.push_back(vertex_index_map[face.value.loops[i+1]]);
        }
    }
    arr[Mesh::ARRAY_VERTEX] = arr_vertices;
    arr[Mesh::ARRAY_INDEX] = arr_indices;
    arr[Mesh::ARRAY_NORMAL] = arr_normals;
    return arr;
}

godot::AABB BrushData::gd_compute_aabb() const
{
    godot::Vector3 a;
    godot::Vector3 b;
    if (m_vertices.size() > 0) {
        bool first = true;
        for (const auto& vert : m_vertices) {
            if (first) {
                a = vert.value.position;
                b = vert.value.position;
            } else {
                a = a.min(vert.value.position);
                b = b.max(vert.value.position);
            }
        }
    }
    return AABB(a, b-a);
}
