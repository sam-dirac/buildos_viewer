#include <QDebug>
#include <QFileOpenEvent>
#include <QFileInfo>

#include "app.h"
#include "window.h"

App::App(int& argc, char *argv[]) :
    QApplication(argc, argv), window(new Window())
{
    qDebug() << "App constructor called";
    if (argc > 1)
        window->load_stl(argv[1]);
    else
        window->load_stl(":gl/sphere.stl");
    window->show();
    window->showMaximized();
}

App::~App()
{
    delete window;
}

bool App::event(QEvent* e)
{
    if (e->type() == QEvent::FileOpen)
    {
        QString filename = static_cast<QFileOpenEvent*>(e)->file();
        QFileInfo fileInfo(filename);
        QString extension = fileInfo.suffix().toLower();

        if (extension == "stl") {
            window->load_stl(filename);
        } else if (extension == "obj") {
            window->load_obj(filename);
        }
        return true;
    }
    else
    {
        return QApplication::event(e);
    }
}
