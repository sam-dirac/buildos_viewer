#include <QDebug>
#include <QFileOpenEvent>
#include <QFileInfo>
#include <QDesktopWidget>

#include "app.h"
#include "window.h"

App::App(int& argc, char *argv[]) :
    QApplication(argc, argv), window(new Window())
{
    if (argc > 1) {
        QFileInfo fileInfo(argv[1]);
        QString extension = fileInfo.suffix().toLower();

        if (extension == "stl") {
            window->load_stl(argv[1]);
        } else if (extension == "obj") {
            window->load_obj(argv[1]);
        } else if (extension == "step") {
            window->load_step(argv[1]);
        } else {
            qCritical() << "Unsupported file type: " << extension;
        }
    } else {
        window->load_stl(":gl/sphere.stl");
    }
    window->show();
    window->resize(this->desktop()->availableGeometry().width()/2, this->desktop()->availableGeometry().height()/2);
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
