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
    // TODO: only surfaces for index
    godot::Array arr;
    arr.resize(godot::Mesh::ARRAY_MAX);
    godot::HashMap<identifier_t, size_t> vertex_index_map;
    godot::PackedVector3Array arr_vertices;
    godot::PackedVector3Array arr_normals;
    for (int i = 0; i < m_loop_vertex_id.size(); i ++) {
        vertex_index_map.insert(i, arr_vertices.size());
        arr_vertices.push_back(m_vertex_positions[m_loop_vertex_id[i]]);
        arr_normals.push_back(Vector3(1, 1, 1).normalized());
    }
    godot::PackedInt32Array arr_indices;
    for (int i = 0; i < m_face_loop_start_id.size(); i++) {
        int start = m_face_loop_start_id[i];
        for (int j = 1; j < m_face_loop_count[i] - 1; j++) {
            arr_indices.push_back(vertex_index_map[start]);
            arr_indices.push_back(vertex_index_map[start+j]);
            arr_indices.push_back(vertex_index_map[start+j+1]);
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
