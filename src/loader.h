#ifndef LOADER_H
#define LOADER_H

#include <QThread>

#include "mesh.h"

class Loader : public QThread
{
    Q_OBJECT
public:
    explicit Loader(QObject* parent, const QString& filename, bool is_reload);
    void run();

protected:
    Mesh* load_stl();
    Mesh* load_obj();

    /*  Reads an ASCII stl, starting from the start of the file*/
    Mesh* read_stl_ascii(QFile& file);
    /*  Reads a binary stl, assuming we're at the end of the header */
    Mesh* read_stl_binary(QFile& file);

signals:
    void loaded_file(QString filename);
    void got_mesh(Mesh* m, bool is_reload);

    void error_bad_stl();
    void error_empty_mesh();
    void error_missing_file();

    void error_bad_obj();

private:
    const QString filename;
    bool is_reload;
};

#endif // LOADER_H
