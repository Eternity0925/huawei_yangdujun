@echo off
set "DEVECO_SDK_HOME=E:\DevEco Studio\sdk"
"E:\DevEco Studio\tools\node\node.exe" "E:\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
