#include "brush_data.hpp"

#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/rendering_server.hpp>

using namespace godot;

template<class T, class U>
constexpr T make_packed_array(std::initializer_list<U> ls) {
    T out;
    for (auto& x : ls) {
        out.push_back(x);
    }
    return out;
}

BrushData::BrushData()
: Resource()
{
    Ref<StandardMaterial3D> mat;
    mat.instantiate();
    add_surface(mat);
}

BrushData::~BrushData() { }

void BrushData::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("get_surface_material", "surface"), &BrushData::get_surface_material);
    ClassDB::bind_method(D_METHOD("set_surface_material", "surface", "material"), &BrushData::set_surface_material);
    ClassDB::bind_method(D_METHOD("add_surface", "material"), &BrushData::add_surface);

    ClassDB::bind_method(D_METHOD("get_surface_count"), &BrushData::gd_get_surface_count);
    ClassDB::bind_method(D_METHOD("compute_array_for_surface", "surface"), &BrushData::gd_get_array_for_surface);
    ClassDB::bind_method(D_METHOD("compute_aabb"), &BrushData::gd_compute_aabb);
    ClassDB::bind_method(D_METHOD("get_vertex_positions"), &BrushData::gd_get_vertex_positions);
    ClassDB::bind_method(D_METHOD("set_vertex_positions", "array"), &BrushData::gd_set_vertex_positions);
    ClassDB::add_property("BrushData", PropertyInfo(Variant::PACKED_VECTOR3_ARRAY, "vertex_positions"), "set_vertex_positions", "get_vertex_positions");
    ClassDB::bind_method(D_METHOD("get_edge_vertex_id1"), &BrushData::gd_get_edge_vertex_id1);
    ClassDB::bind_method(D_METHOD("set_edge_vertex_id1", "array"), &BrushData::gd_set_edge_vertex_id1);
    ClassDB::add_property("BrushData", PropertyInfo(Variant::PACKED_INT32_ARRAY, "edge_vertex_id1"), "set_edge_vertex_id1", "get_edge_vertex_id1");
    ClassDB::bind_method(D_METHOD("get_edge_vertex_id2"), &BrushData::gd_get_edge_vertex_id2);
    ClassDB::bind_method(D_METHOD("set_edge_vertex_id2", "array"), &BrushData::gd_set_edge_vertex_id2);
    ClassDB::add_property("BrushData", PropertyInfo(Variant::PACKED_INT32_ARRAY, "edge_vertex_id2"), "set_edge_vertex_id2", "get_edge_vertex_id2");
    ClassDB::bind_method(D_METHOD("get_loop_edge_id"), &BrushData::gd_get_loop_edge_id);
    ClassDB::bind_method(D_METHOD("set_loop_edge_id", "array"), &BrushData::gd_set_loop_edge_id);
    ClassDB::add_property("BrushData", PropertyInfo(Variant::PACKED_INT32_ARRAY, "loop_edge_id"), "set_loop_edge_id", "get_loop_edge_id");
    ClassDB::bind_method(D_METHOD("get_loop_vertex_id"), &BrushData::gd_get_loop_vertex_id);
    ClassDB::bind_method(D_METHOD("set_loop_vertex_id", "array"), &BrushData::gd_set_loop_vertex_id);
    ClassDB::add_property("BrushData", PropertyInfo(Variant::PACKED_INT32_ARRAY, "loop_vertex_id"), "set_loop_vertex_id", "get_loop_vertex_id");
    ClassDB::bind_method(D_METHOD("get_face_loop_start_id"), &BrushData::gd_get_face_loop_start_id);
    ClassDB::bind_method(D_METHOD("set_face_loop_start_id", "array"), &BrushData::gd_set_face_loop_start_id);
    ClassDB::add_property("BrushData", PropertyInfo(Variant::PACKED_INT32_ARRAY, "face_loop_start_id"), "set_face_loop_start_id", "get_face_loop_start_id");
    ClassDB::bind_method(D_METHOD("get_face_loop_count"), &BrushData::gd_get_face_loop_count);
    ClassDB::bind_method(D_METHOD("set_face_loop_count", "array"), &BrushData::gd_set_face_loop_count);
    ClassDB::add_property("BrushData", PropertyInfo(Variant::PACKED_INT32_ARRAY, "face_loop_count"), "set_face_loop_count", "get_face_loop_count");
    ClassDB::bind_method(D_METHOD("get_face_surface_id"), &BrushData::gd_get_face_surface_id);
    ClassDB::bind_method(D_METHOD("set_face_surface_id", "array"), &BrushData::gd_set_face_surface_id);
    ClassDB::add_property("BrushData", PropertyInfo(Variant::PACKED_INT32_ARRAY, "face_surface_id"), "set_face_surface_id", "get_face_surface_id");
    ClassDB::bind_method(D_METHOD("get_surface_materials"), &BrushData::gd_get_surface_materials);
    ClassDB::bind_method(D_METHOD("set_surface_materials", "array"), &BrushData::gd_set_surface_materials);
    ClassDB::add_property("BrushData", PropertyInfo(Variant::ARRAY, "surface_materials", PROPERTY_HINT_ARRAY_TYPE, "Material"), "set_surface_materials", "get_surface_materials");

    ADD_SIGNAL(MethodInfo("vertex_updated", PropertyInfo(Variant::INT, "vertex")));

    BIND_ENUM_CONSTANT(BRUSH_COMPONENT_VERTEX);
    BIND_ENUM_CONSTANT(BRUSH_COMPONENT_EDGE);
    BIND_ENUM_CONSTANT(BRUSH_COMPONENT_FACE);
    BIND_ENUM_CONSTANT(BRUSH_COMPONENT_LOOP);
}

godot::PackedVector3Array BrushData::gd_get_vertex_positions()
{
    return m_vertex_positions;
}

void BrushData::gd_set_vertex_positions(godot::PackedVector3Array v)
{
    m_vertex_positions = v;
}

godot::PackedInt32Array BrushData::gd_get_edge_vertex_id1()
{
    return m_edge_vertex_id1;
}

void BrushData::gd_set_edge_vertex_id1(godot::PackedInt32Array v)
{
    m_edge_vertex_id1 = v;
}

godot::PackedInt32Array BrushData::gd_get_edge_vertex_id2()
{
    return m_edge_vertex_id2;
}

void BrushData::gd_set_edge_vertex_id2(godot::PackedInt32Array v)
{
    m_edge_vertex_id2 = v;
}

godot::PackedInt32Array BrushData::gd_get_loop_edge_id()
{
    return m_loop_edge_id;
}

void BrushData::gd_set_loop_edge_id(godot::PackedInt32Array v)
{
    m_loop_edge_id = v;
}

godot::PackedInt32Array BrushData::gd_get_loop_vertex_id()
{
    return m_loop_vertex_id;
}

void BrushData::gd_set_loop_vertex_id(godot::PackedInt32Array v)
{
    m_loop_vertex_id = v;
}

godot::PackedInt32Array BrushData::gd_get_face_loop_start_id()
{
    return m_face_loop_start_id;
}

void BrushData::gd_set_face_loop_start_id(godot::PackedInt32Array v)
{
    m_face_loop_start_id = v;
}

godot::PackedInt32Array BrushData::gd_get_face_loop_count()
{
    return m_face_loop_count;
}

void BrushData::gd_set_face_loop_count(godot::PackedInt32Array v)
{
    m_face_loop_count = v;
}

godot::PackedInt32Array BrushData::gd_get_face_surface_id()
{
    return m_face_surface_id;
}

void BrushData::gd_set_face_surface_id(godot::PackedInt32Array v)
{
    m_face_surface_id = v;
}

godot::TypedArray<godot::Material> BrushData::gd_get_surface_materials()
{
    return m_surface_materials;
}

void BrushData::gd_set_surface_materials(godot::TypedArray<godot::Material> v)
{
    m_surface_materials = v;
}

uint32_t BrushData::add_surface(godot::Ref<godot::Material> material)
{
    m_surface_materials.push_back(material);
    // m_surfacecache.push_back({});
    return m_surface_materials.size() - 1;
}

void BrushData::set_surface_material(uint32_t i, godot::Ref<godot::Material> material)
{
    m_surface_materials[i] = material;
}

godot::Ref<godot::Material> BrushData::get_surface_material(uint32_t i)
{
    return m_surface_materials[i];
}

/* GDSCRIPT API */

int32_t BrushData::gd_get_surface_count() const
{
    return m_surface_materials.size();
}

Array BrushData::gd_get_array_for_surface(int32_t index) const
{
    ERR_FAIL_INDEX_V(index, m_surface_materials.size(), {});
    godot::Array arr;
    arr.resize(godot::Mesh::ARRAY_MAX);
    godot::PackedVector3Array arr_vertices;
    godot::PackedVector3Array arr_normals;
    godot::PackedInt32Array arr_indices;
    for (int i = 0; i < m_face_loop_start_id.size(); i++) {
        if (m_face_surface_id[i] != index) continue;
        int start = m_face_loop_start_id[i];
        godot::Vector3 normal = calculate_normal_for_face(i);
        int out_loop_index_start = arr_vertices.size();
        for (int j = 0; j < m_face_loop_count[i]; j++) {
            // godot::Vector3 normal = calculate_normal_for_vertex(m_loop_vertex_id[start+j]);
            arr_vertices.push_back(m_vertex_positions[m_loop_vertex_id[start + j]]);
            arr_normals.push_back(normal);
        }
        for (int j = 1; j < m_face_loop_count[i] - 1; j++) {
            arr_indices.push_back(out_loop_index_start);
            arr_indices.push_back(out_loop_index_start + j);
            arr_indices.push_back(out_loop_index_start + j + 1);
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
    if (m_vertex_positions.size() > 0) {
        bool first = true;
        for (const auto& vert : m_vertex_positions) {
            if (first) {
                a = vert;
                b = vert;
            } else {
                a = a.min(vert);
                b = b.max(vert);
            }
            first = false;
        }
    }
    return AABB(a, b-a);
}

godot::Vector3 BrushData::calculate_normal_for_vertex(identifier_t id) const
{
    godot::Vector3 normal;
    // TODO: maybe just move normal handling elsewhere...
    for (int i = 0; i < m_edge_vertex_id1.size(); i++) {
        if (m_edge_vertex_id1[i] == id) {
            normal += (m_vertex_positions[id] - m_vertex_positions[m_edge_vertex_id2[i]]).normalized();
        } else if (m_edge_vertex_id2[i] == id) {
            normal += (m_vertex_positions[id] - m_vertex_positions[m_edge_vertex_id1[i]]).normalized();
        }
    }
    return normal.normalized();
}

godot::Vector3 BrushData::calculate_normal_for_face(identifier_t id) const
{
    // normal = sum(f => cross(f.v1, f.v2))
    godot::Vector3 normal;
    int count = m_face_loop_count[id];
    for (int i = 0; i < count; i++) {
        int loop1 = m_face_loop_start_id[id] + i;
        int loop2 = m_face_loop_start_id[id] + ((i + 1) % count);
        int edge1 = m_loop_edge_id[loop1];
        int edge2 = m_loop_edge_id[loop2];
        int vert1_1 = m_loop_vertex_id[loop1];
        int vert1_2 = (vert1_1 == m_edge_vertex_id1[edge1]) ? m_edge_vertex_id2[edge1] : m_edge_vertex_id1[edge1];
        int vert2_1 = m_loop_vertex_id[loop2];
        int vert2_2 = (vert2_1 == m_edge_vertex_id1[edge2]) ? m_edge_vertex_id2[edge2] : m_edge_vertex_id1[edge2];
        godot::Vector3 edge1_dir = m_vertex_positions[vert1_2] - m_vertex_positions[vert1_1];
        godot::Vector3 edge2_dir = m_vertex_positions[vert2_2] - m_vertex_positions[vert1_1];
        if (edge1_dir == Vector3(0, 0, 0) || edge2_dir == Vector3(0, 0, 0)) continue;
        normal += edge2_dir.normalized().cross(edge1_dir.normalized());
    }
    return normal.normalized();
}
