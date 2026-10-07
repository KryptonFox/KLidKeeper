#include "lidcontroller.h"

#include <QQmlExtensionPlugin>
#include <qqml.h>

class KLidPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override
    {
        Q_ASSERT(QLatin1String(uri) == QLatin1String("com.github.kryptonfox.klidkeeper"));
        qmlRegisterType<LidController>(uri, 1, 0, "LidController");
    }
};

#include "plugin.moc"
