#include <QProcess>
#include <QDebug>
#include <QString>
#include <iostream>

class StepConverter
{
public:
    StepConverter(const QString& step_filepath, const QString& output_path) : step_filepath_(step_filepath), output_path_(output_path) {}
    
    QString runScript() {
        QProcess process;
        // Change directory to DIRAC_BUILDOS_PATH
        QString diracBuildosPath = qgetenv("DIRAC_BUILDOS_PATH");
        process.setWorkingDirectory(diracBuildosPath);
        qDebug() << "🗂️  Changed working directory to: " << diracBuildosPath;

        // Append the DIRAC_BUILDOS_PATH to the QProcess environment PYTHONPATH
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
        env.insert("PYTHONPATH", env.value("PYTHONPATH") + ":" + diracBuildosPath);
        process.setProcessEnvironment(env);


        QFileInfo fileInfo(step_filepath_);
        QString filename = fileInfo.baseName();
        QString output_filepath = output_path_ + "/" + filename;

        // Create the output directory if it doesn't exist and clear it otherwise
        QDir dir(output_filepath);
        if (!dir.exists()) {
            dir.mkpath(".");
        } else {
            dir.setNameFilters(QStringList() << "*.*");
            dir.setFilter(QDir::Files);
            foreach(QString dirFile, dir.entryList())
            {
                dir.remove(dirFile);
            }
        }

        // Execute python -m app.lib.step_to_obj
        QString program = "conda";
        QStringList arguments = {"activate", "buildos", "&&", "python", "-m", "app.lib.step_to_obj", "--output-path",  output_filepath, "--filename", step_filepath_};
        process.setProgram(program);
        process.setArguments(arguments);
        std::cout << "🚀 Running command: '" << program.toStdString() << " " << arguments.join(" ").toStdString() << "'\n";
        process.start();
        if (!process.waitForFinished(-1)) {
            qDebug() << "Failed to execute " << program << " " << arguments.join(" ");
            return "";
        }
        QString output = process.readAllStandardOutput();
        std::cout << output.toStdString() << std::endl;
        if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
            qDebug() << "❌ Process exited with status " << process.exitStatus() << " and code " << process.exitCode();
            return "";
        }
        std::cout << "✅ Successfully executed '" << program.toStdString() << " " << arguments.join(" ").toStdString() << "'" << std::endl;
        return output_filepath;
    }

private:
    QString step_filepath_;
    QString output_path_;
};
