#include <future>

#include "loader.h"
#include "vertex.h"

Loader::Loader(QObject* parent, const QString& filename, bool is_reload)
    : QThread(parent), filename(filename), is_reload(is_reload)
{
    // Nothing to do here
}

void Loader::run()
{
    QFileInfo fileInfo(filename);
    QString extension = fileInfo.suffix().toLower();
    Mesh* mesh = nullptr;
    
    if (extension == "stl") {
        mesh = load_stl();
    } else if (extension == "obj") {
        mesh = load_obj();
    } else {
        return;
    }
    
    if (mesh)
    {
        if (mesh->empty())
        {
            emit error_empty_mesh();
            delete mesh;
        }
        else
        {
            emit got_mesh(mesh, is_reload);
            emit loaded_file(filename);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////

void parallel_sort(Vertex* begin, Vertex* end, int threads)
{
    if (threads < 2 || end - begin < 2)
    {
        std::sort(begin, end);
    }
    else
    {
        const auto mid = begin + (end - begin) / 2;
        if (threads == 2)
        {
            auto future = std::async(parallel_sort, begin, mid, threads / 2);
            std::sort(mid, end);
            future.wait();
        }
        else
        {
            auto a = std::async(std::launch::async, parallel_sort, begin, mid, threads / 2);
            auto b = std::async(std::launch::async, parallel_sort, mid, end, threads / 2);
            a.wait();
            b.wait();
        }
        std::inplace_merge(begin, mid, end);
    }
}

Mesh* mesh_from_verts(uint32_t tri_count, QVector<Vertex>& verts)
{
    // Save indicies as the second element in the array
    // (so that we can reconstruct triangle order after sorting)
    for (size_t i=0; i < tri_count*3; ++i)
    {
        verts[i].i = i;
    }

    // Check how many threads the hardware can safely support. This may return
    // 0 if the property can't be read so we shoud check for that too.
    auto threads = std::thread::hardware_concurrency();
    if (threads == 0)
    {
        threads = 8;
    }

    // Sort the set of vertices (to deduplicate)
    parallel_sort(verts.begin(), verts.end(), threads);

    // This vector will store triangles as sets of 3 indices
    std::vector<GLuint> indices(tri_count*3);

    // Go through the sorted vertex list, deduplicating and creating
    // an indexed geometry representation for the triangles.
    // Unique vertices are moved so that they occupy the first vertex_count
    // positions in the verts array.
    size_t vertex_count = 0;
    for (auto v : verts)
    {
        if (!vertex_count || v != verts[vertex_count-1])
        {
            verts[vertex_count++] = v;
        }
        indices[v.i] = vertex_count - 1;
    }
    verts.resize(vertex_count);

    std::vector<GLfloat> flat_verts;
    flat_verts.reserve(vertex_count*3);
    for (auto v : verts)
    {
        flat_verts.push_back(v.x);
        flat_verts.push_back(v.y);
        flat_verts.push_back(v.z);
    }

    return new Mesh(std::move(flat_verts), std::move(indices));
}

////////////////////////////////////////////////////////////////////////////////




Mesh* Loader::load_obj()
{
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly))
    {
        emit error_missing_file();
        return NULL;
    }

    QVector<Vertex> verts;
    QVector<GLuint> indices;

    while (!file.atEnd())
    {
        QByteArray line = file.readLine();
        QList<QByteArray> parts = line.split(' ');

        if (parts[0] == "mtllib" || parts[0] == "usemtl")
        {
            qDebug() << "Warning: Material data found in obj file but is not being used.";
        }
        else if (parts[0] == "v")
        {
            // OBJ vertices are 1-indexed, so we add a dummy vertex at the start
            if (verts.empty())
            {
                verts.push_back(Vertex(0, 0, 0));
            }

            float x = parts[1].toFloat();
            float y = parts[2].toFloat();
            float z = parts[3].toFloat();
            verts.push_back(Vertex(x, y, z));
        }
        else if (parts[0] == "f")
        {
            // OBJ faces are defined by indices into the vertex array
            for (int i = 1; i <= 3; ++i)
            {
                GLuint index = parts[i].toUInt();
                indices.push_back(index);
            }
        }
    }

    std::vector<GLfloat> flat_verts;
    flat_verts.reserve(verts.size()*3);
    for (auto v : verts)
    {
        flat_verts.push_back(v.x);
        flat_verts.push_back(v.y);
        flat_verts.push_back(v.z);
    }

    std::vector<GLuint> flat_indices(indices.begin(), indices.end());

    qDebug() << "🔺 Number of triangles: " << flat_indices.size() / 3;
    qDebug() << "🔹 Number of vertices: " << flat_verts.size() / 3;
    return new Mesh(std::move(flat_verts), std::move(flat_indices));
}

Mesh* Loader::load_stl()
{
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly))
    {
        emit error_missing_file();
        return NULL;
    }

    qint64 file_size, file_size_old;
    file_size = file.size();
    do {
        file_size_old = file_size;
        QThread::usleep(100000);
        file_size = file.size();
    }
    while(file_size != file_size_old);

    // First, try to read the stl as an ASCII file
    if (file.read(5) == "solid")
    {
        file.readLine(); // skip solid name
        const auto line = file.readLine().trimmed();
        if (line.startsWith("facet") ||
            line.startsWith("endsolid"))
        {
            file.seek(0);
            return read_stl_ascii(file);
        }
        // Otherwise, this STL is a binary stl but contains 'solid' as
        // the first five characters.  This is a bad life choice, but
        // we can gracefully handle it by falling through to the binary
        // STL reader below.
    }

    file.seek(0);
    return read_stl_binary(file);
}

Mesh* Loader::read_stl_binary(QFile& file)
{
    QDataStream data(&file);
    data.setByteOrder(QDataStream::LittleEndian);
    data.setFloatingPointPrecision(QDataStream::SinglePrecision);

    // Load the triangle count from the .stl file
    file.seek(80);
    uint32_t tri_count;
    data >> tri_count;

    // Verify that the file is the right size
    if (file.size() != 84 + tri_count*50)
    {
        emit error_bad_stl();
        return NULL;
    }

    // Extract vertices into an array of xyz, unsigned pairs
    QVector<Vertex> verts(tri_count*3);

    // Dummy array, because readRawData is faster than skipRawData
    std::unique_ptr<uint8_t[]> buffer(new uint8_t[tri_count * 50]);
    data.readRawData((char*)buffer.get(), tri_count * 50);

    // Store vertices in the array, processing one triangle at a time.
    auto b = buffer.get() + 3 * sizeof(float);
    for (auto v=verts.begin(); v != verts.end(); v += 3)
    {
        // Load vertex data from .stl file into vertices
        for (unsigned i=0; i < 3; ++i)
        {
            qFromLittleEndian<float>(b, 3, &v[i]);
            b += 3 * sizeof(float);
        }

        // Skip face attribute and next face's normal vector
        b += 3 * sizeof(float) + sizeof(uint16_t);
    }

    return mesh_from_verts(tri_count, verts);
}

Mesh* Loader::read_stl_ascii(QFile& file)
{
    file.readLine();
    uint32_t tri_count = 0;
    QVector<Vertex> verts(tri_count*3);

    bool okay = true;
    while (!file.atEnd() && okay)
    {
        const auto line = file.readLine().simplified();
        if (line.startsWith("endsolid"))
        {
            break;
        }
        else if (!line.startsWith("facet normal") ||
                 !file.readLine().simplified().startsWith("outer loop"))
        {
            okay = false;
            break;
        }

        for (int i=0; i < 3; ++i)
        {
            auto line = file.readLine().simplified().split(' ');
            if (line[0] != "vertex")
            {
                okay = false;
                break;
            }
            const float x = line[1].toFloat(&okay);
            const float y = line[2].toFloat(&okay);
            const float z = line[3].toFloat(&okay);
            verts.push_back(Vertex(x, y, z));
        }
        if (!file.readLine().trimmed().startsWith("endloop") ||
            !file.readLine().trimmed().startsWith("endfacet"))
        {
            okay = false;
            break;
        }
        tri_count++;
    }

    if (okay)
    {
        return mesh_from_verts(tri_count, verts);
    }
    else
    {
        emit error_bad_stl();
        return NULL;
    }
}

