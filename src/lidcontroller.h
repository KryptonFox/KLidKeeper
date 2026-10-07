#pragma once

#include <QObject>
#include <QSettings>
#include <qqmlregistration.h>

class LidController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool isInhibited READ isInhibited WRITE setInhibited NOTIFY inhibitedChanged FINAL)
    Q_PROPERTY(bool preventLock READ preventLock WRITE setPreventLock NOTIFY preventLockChanged FINAL)
    Q_PROPERTY(int screenAction READ screenAction WRITE setScreenAction NOTIFY screenActionChanged FINAL)
    Q_PROPERTY(bool isLidClosed READ isLidClosed NOTIFY lidClosedChanged FINAL)

public:
    enum ScreenAction {
        TurnOffScreen = 0,
        DimBrightness = 1,
        DoNothing = 2
    };
    Q_ENUM(ScreenAction)

    explicit LidController(QObject *parent = nullptr);
    ~LidController() override;

    bool isInhibited() const;
    void setInhibited(bool inhibited);

    bool preventLock() const;
    void setPreventLock(bool prevent);

    int screenAction() const;
    void setScreenAction(int action);

    bool isLidClosed() const;

    Q_INVOKABLE void toggle();
    Q_INVOKABLE void enableInhibit();
    Q_INVOKABLE void disableInhibit();

Q_SIGNALS:
    void inhibitedChanged();
    void preventLockChanged();
    void screenActionChanged();
    void lidClosedChanged();

private Q_SLOTS:
    void onNameOwnerChanged(const QString &serviceName, const QString &oldOwner, const QString &newOwner);
    void onLidClosedChanged(bool closed);
    void onLogindPropertiesChanged(const QString &interfaceName, const QVariantMap &changedProperties, const QStringList &invalidatedProperties);

private:
    void applyScreenActionOnClose();
    void restoreScreenActionOnOpen();
    void acquireLockInhibit();
    void releaseLockInhibit();

    void turnOffScreen();
    void turnOnScreen();
    void saveAndDimBrightness();
    void restoreBrightness();

    int m_inhibitFd = -1;
    uint m_screenSaverCookie = 0;
    bool m_preventLock = true;
    int m_screenAction = TurnOffScreen;
    bool m_isLidClosed = false;

    bool m_screenWasTurnedOff = false;
    int m_savedBrightness = -1;

    QSettings m_settings;
};
