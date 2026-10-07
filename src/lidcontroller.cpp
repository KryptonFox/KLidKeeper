#include "lidcontroller.h"

#include <QByteArray>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusError>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusReply>
#include <QDBusUnixFileDescriptor>
#include <QDebug>
#include <QProcess>

#include <cerrno>
#include <cstring>
#include <unistd.h>

static const QString s_logindService = QStringLiteral("org.freedesktop.login1");
static const QString s_logindPath = QStringLiteral("/org/freedesktop/login1");
static const QString s_logindInterface = QStringLiteral("org.freedesktop.login1.Manager");

static const QString s_solidService = QStringLiteral("org.kde.Solid.PowerManagement");
static const QString s_solidPath = QStringLiteral("/org/kde/Solid/PowerManagement");
static const QString s_solidInterface = QStringLiteral("org.kde.Solid.PowerManagement");

static const QString s_brightnessPath = QStringLiteral("/org/kde/Solid/PowerManagement/Actions/BrightnessControl");
static const QString s_brightnessInterface = QStringLiteral("org.kde.Solid.PowerManagement.Actions.BrightnessControl");

static const QString s_screenSaverService = QStringLiteral("org.freedesktop.ScreenSaver");
static const QString s_screenSaverPath = QStringLiteral("/ScreenSaver");
static const QString s_screenSaverInterface = QStringLiteral("org.freedesktop.ScreenSaver");

LidController::LidController(QObject *parent)
    : QObject(parent)
    , m_settings(QStringLiteral("kde.org"), QStringLiteral("KLidKeeper"))
{
    // Load persisted settings
    m_preventLock = m_settings.value(QStringLiteral("preventLock"), true).toBool();
    m_screenAction = m_settings.value(QStringLiteral("screenAction"), static_cast<int>(TurnOffScreen)).toInt();
    if (m_screenAction < 0 || m_screenAction > 2) {
        m_screenAction = TurnOffScreen;
    }

    // 1. Listen for logind service lifetime events
    QDBusConnection::systemBus().connect(
        QStringLiteral("org.freedesktop.DBus"),
        QStringLiteral("/org/freedesktop/DBus"),
        QStringLiteral("org.freedesktop.DBus"),
        QStringLiteral("NameOwnerChanged"),
        this,
        SLOT(onNameOwnerChanged(QString,QString,QString))
    );

    // 2. Listen for Solid PowerManagement lid state signal
    QDBusConnection::sessionBus().connect(
        s_solidService,
        s_solidPath,
        s_solidInterface,
        QStringLiteral("lidClosedChanged"),
        this,
        SLOT(onLidClosedChanged(bool))
    );

    // 3. Listen for logind LidClosed property changes
    QDBusConnection::systemBus().connect(
        s_logindService,
        s_logindPath,
        QStringLiteral("org.freedesktop.DBus.Properties"),
        QStringLiteral("PropertiesChanged"),
        this,
        SLOT(onLogindPropertiesChanged(QString,QVariantMap,QStringList))
    );

    // Query initial lid status from Solid
    QDBusMessage msg = QDBusMessage::createMethodCall(
        s_solidService,
        s_solidPath,
        s_solidInterface,
        QStringLiteral("isLidClosed")
    );
    const QDBusReply<bool> reply = QDBusConnection::sessionBus().call(msg);
    if (reply.isValid()) {
        m_isLidClosed = reply.value();
    }
}

LidController::~LidController()
{
    disableInhibit();
}

bool LidController::isInhibited() const
{
    return m_inhibitFd >= 0;
}

void LidController::setInhibited(bool inhibited)
{
    if (inhibited) {
        enableInhibit();
    } else {
        disableInhibit();
    }
}

bool LidController::preventLock() const
{
    return m_preventLock;
}

void LidController::setPreventLock(bool prevent)
{
    if (m_preventLock != prevent) {
        m_preventLock = prevent;
        m_settings.setValue(QStringLiteral("preventLock"), m_preventLock);
        Q_EMIT preventLockChanged();

        if (isInhibited()) {
            if (m_preventLock) {
                acquireLockInhibit();
            } else {
                releaseLockInhibit();
            }
        }
    }
}

int LidController::screenAction() const
{
    return m_screenAction;
}

void LidController::setScreenAction(int action)
{
    if (m_screenAction != action) {
        m_screenAction = action;
        m_settings.setValue(QStringLiteral("screenAction"), m_screenAction);
        Q_EMIT screenActionChanged();
    }
}

bool LidController::isLidClosed() const
{
    return m_isLidClosed;
}

void LidController::enableInhibit()
{
    if (m_inhibitFd >= 0) {
        return;
    }

    QDBusMessage msg = QDBusMessage::createMethodCall(
        s_logindService,
        s_logindPath,
        s_logindInterface,
        QStringLiteral("Inhibit")
    );

    msg << QStringLiteral("handle-lid-switch:sleep")
        << QStringLiteral("KLid Plasmoid")
        << QStringLiteral("User requested stay awake on lid close")
        << QStringLiteral("block");

    const QDBusReply<QDBusUnixFileDescriptor> reply = QDBusConnection::systemBus().call(msg);
    if (!reply.isValid()) {
        qWarning() << "KLidKeeper: Failed to call Inhibit on logind:" << reply.error().message();
        return;
    }

    const QDBusUnixFileDescriptor descriptor = reply.value();
    if (!descriptor.isValid() || descriptor.fileDescriptor() < 0) {
        qWarning() << "KLidKeeper: Received invalid file descriptor from logind";
        return;
    }

    m_inhibitFd = ::dup(descriptor.fileDescriptor());
    if (m_inhibitFd < 0) {
        qWarning() << "KLidKeeper: Failed to duplicate file descriptor:" << std::strerror(errno);
        return;
    }

    // Inhibit screen locker if configured
    if (m_preventLock) {
        acquireLockInhibit();
    }

    // If lid is currently closed, apply configured screen action immediately
    if (m_isLidClosed) {
        applyScreenActionOnClose();
    }

    Q_EMIT inhibitedChanged();
}

void LidController::disableInhibit()
{
    if (m_inhibitFd >= 0) {
        if (::close(m_inhibitFd) != 0) {
            qWarning() << "KLidKeeper: Failed to close inhibit file descriptor:" << std::strerror(errno);
        }
        m_inhibitFd = -1;

        releaseLockInhibit();
        restoreScreenActionOnOpen();

        Q_EMIT inhibitedChanged();
    }
}

void LidController::toggle()
{
    if (isInhibited()) {
        disableInhibit();
    } else {
        enableInhibit();
    }
}

void LidController::acquireLockInhibit()
{
    if (m_screenSaverCookie != 0) {
        return;
    }

    QDBusMessage msg = QDBusMessage::createMethodCall(
        s_screenSaverService,
        s_screenSaverPath,
        s_screenSaverInterface,
        QStringLiteral("Inhibit")
    );
    msg << QStringLiteral("KLidKeeper")
        << QStringLiteral("Prevent screen lock on lid close");

    const QDBusReply<uint> reply = QDBusConnection::sessionBus().call(msg);
    if (reply.isValid()) {
        m_screenSaverCookie = reply.value();
    } else {
        qWarning() << "KLidKeeper: Failed to inhibit ScreenSaver:" << reply.error().message();
    }
}

void LidController::releaseLockInhibit()
{
    if (m_screenSaverCookie == 0) {
        return;
    }

    QDBusMessage msg = QDBusMessage::createMethodCall(
        s_screenSaverService,
        s_screenSaverPath,
        s_screenSaverInterface,
        QStringLiteral("UnInhibit")
    );
    msg << m_screenSaverCookie;

    QDBusConnection::sessionBus().call(msg);
    m_screenSaverCookie = 0;
}

void LidController::applyScreenActionOnClose()
{
    if (m_screenAction == TurnOffScreen) {
        turnOffScreen();
        m_screenWasTurnedOff = true;
    } else if (m_screenAction == DimBrightness) {
        saveAndDimBrightness();
    }
}

void LidController::restoreScreenActionOnOpen()
{
    if (m_screenWasTurnedOff) {
        turnOnScreen();
        m_screenWasTurnedOff = false;
    }
    if (m_savedBrightness >= 0) {
        restoreBrightness();
    }
}

void LidController::turnOffScreen()
{
    const QByteArray sessionType = qgetenv("XDG_SESSION_TYPE").toLower();
    if (sessionType == "x11") {
        if (!QProcess::startDetached(QStringLiteral("xset"), {QStringLiteral("dpms"), QStringLiteral("force"), QStringLiteral("off")})) {
            QProcess::startDetached(QStringLiteral("kscreen-doctor"), {QStringLiteral("--dpms"), QStringLiteral("off")});
        }
    } else {
        if (!QProcess::startDetached(QStringLiteral("kscreen-doctor"), {QStringLiteral("--dpms"), QStringLiteral("off")})) {
            QProcess::startDetached(QStringLiteral("xset"), {QStringLiteral("dpms"), QStringLiteral("force"), QStringLiteral("off")});
        }
    }
}

void LidController::turnOnScreen()
{
    const QByteArray sessionType = qgetenv("XDG_SESSION_TYPE").toLower();
    if (sessionType == "x11") {
        if (!QProcess::startDetached(QStringLiteral("xset"), {QStringLiteral("dpms"), QStringLiteral("force"), QStringLiteral("on")})) {
            QProcess::startDetached(QStringLiteral("kscreen-doctor"), {QStringLiteral("--dpms"), QStringLiteral("on")});
        }
    } else {
        if (!QProcess::startDetached(QStringLiteral("kscreen-doctor"), {QStringLiteral("--dpms"), QStringLiteral("on")})) {
            QProcess::startDetached(QStringLiteral("xset"), {QStringLiteral("dpms"), QStringLiteral("force"), QStringLiteral("on")});
        }
    }
}

void LidController::saveAndDimBrightness()
{
    QDBusInterface brightnessIface(
        s_solidService,
        s_brightnessPath,
        s_brightnessInterface,
        QDBusConnection::sessionBus()
    );

    if (brightnessIface.isValid()) {
        const QDBusReply<int> curReply = brightnessIface.call(QStringLiteral("brightness"));
        if (curReply.isValid()) {
            m_savedBrightness = curReply.value();
        }
        const QDBusReply<int> minReply = brightnessIface.call(QStringLiteral("brightnessMin"));
        const int minB = minReply.isValid() ? minReply.value() : 0;
        brightnessIface.call(QStringLiteral("setBrightness"), minB);
    }
}

void LidController::restoreBrightness()
{
    if (m_savedBrightness < 0) {
        return;
    }

    QDBusInterface brightnessIface(
        s_solidService,
        s_brightnessPath,
        s_brightnessInterface,
        QDBusConnection::sessionBus()
    );

    if (brightnessIface.isValid()) {
        brightnessIface.call(QStringLiteral("setBrightness"), m_savedBrightness);
    }
    m_savedBrightness = -1;
}

void LidController::onLidClosedChanged(bool closed)
{
    m_isLidClosed = closed;
    Q_EMIT lidClosedChanged();

    if (!isInhibited()) {
        return;
    }

    if (closed) {
        applyScreenActionOnClose();
    } else {
        restoreScreenActionOnOpen();
    }
}

void LidController::onLogindPropertiesChanged(const QString &interfaceName, const QVariantMap &changedProperties, const QStringList &invalidatedProperties)
{
    Q_UNUSED(invalidatedProperties);
    if (interfaceName == s_logindInterface && changedProperties.contains(QStringLiteral("LidClosed"))) {
        const bool closed = changedProperties.value(QStringLiteral("LidClosed")).toBool();
        onLidClosedChanged(closed);
    }
}

void LidController::onNameOwnerChanged(const QString &serviceName, const QString &oldOwner, const QString &newOwner)
{
    Q_UNUSED(oldOwner);
    if (serviceName == s_logindService && newOwner.isEmpty()) {
        if (m_inhibitFd >= 0) {
            ::close(m_inhibitFd);
            m_inhibitFd = -1;
            m_screenSaverCookie = 0;
            restoreScreenActionOnOpen();
            Q_EMIT inhibitedChanged();
        }
    }
}
