#!/bin/sh

cp -r ./build/linux/x64/release/bundle/ ./build/linux/x64/release/Stronzflix.AppDir

cp ./linux/appimage/AppRun ./build/linux/x64/release/Stronzflix.AppDir/AppRun
chmod +x ./build/linux/x64/release/Stronzflix.AppDir/AppRun

cp ./linux/appimage/icon.png ./build/linux/x64/release/Stronzflix.AppDir/Stronzflix.png
cp ./linux/appimage/Stronzflix.desktop ./build/linux/x64/release/Stronzflix.AppDir/Stronzflix.desktop

appimagetool ./build/linux/x64/release/Stronzflix.AppDir ./build/linux/x64/release/Stronzflix.AppImage