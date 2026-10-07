cmake_minimum_required(VERSION 3.20)

project(com.github.kryptonfox.klidkeeper LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_MAJOR_VERSION 6)

find_package(ECM 6.0.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core DBus Qml Quick)
find_package(Plasma 6.0.0 REQUIRED)
find_package(KF6I18n 6.0.0 REQUIRED)

set(CMAKE_AUTOMOC ON)

# QML C++ Extension Plugin target
add_library(klidplugin SHARED
    src/lidcontroller.h
    src/lidcontroller.cpp
    src/plugin.cpp
)

target_link_libraries(klidplugin PRIVATE
    Qt6::Core
    Qt6::DBus
    Qt6::Qml
    Qt6::Quick
    KF6::I18n
)

# Place built plugin into build/bin/com/github/kryptonfox/klidkeeper for local development and testing
set_target_properties(klidplugin PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/com/github/kryptonfox/klidkeeper"
)

# Generate qmldir inside build/bin/com/github/kryptonfox/klidkeeper for plasmoidviewer
file(GENERATE
    OUTPUT "${CMAKE_BINARY_DIR}/bin/com/github/kryptonfox/klidkeeper/qmldir"
    CONTENT "module com.github.kryptonfox.klidkeeper\nplugin klidplugin\nclassname KLidPlugin\n"
)

# 1. Install QML C++ plugin and qmldir into ${KDE_INSTALL_QMLDIR}/com/github/kryptonfox/klidkeeper/
install(TARGETS klidplugin
    DESTINATION "${KDE_INSTALL_QMLDIR}/com/github/kryptonfox/klidkeeper"
)

install(FILES "${CMAKE_BINARY_DIR}/bin/com/github/kryptonfox/klidkeeper/qmldir"
    DESTINATION "${KDE_INSTALL_QMLDIR}/com/github/kryptonfox/klidkeeper"
)

# 2. Install icons to system hicolor theme for tray and panel support
install(FILES
    package/contents/icons/caffeine-cup-full.svg
    package/contents/icons/caffeine-cup-empty.svg
    DESTINATION "${KDE_INSTALL_DATADIR}/icons/hicolor/scalable/status"
)

install(FILES
    package/contents/icons/caffeine-cup-full.svg
    package/contents/icons/caffeine-cup-empty.svg
    DESTINATION "${KDE_INSTALL_DATADIR}/icons/hicolor/scalable/apps"
)

# 3. Install the plasmoid package into ${KDE_INSTALL_DATADIR}/plasma/plasmoids/com.github.kryptonfox.klidkeeper
plasma_install_package(package com.github.kryptonfox.klidkeeper)

# 4. Translations
ki18n_install(po)
