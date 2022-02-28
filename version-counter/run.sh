export INPUT_VARIABLEGROUPNAME="VariableGroup"
export INPUT_VARIABLENAME="VersionNumber"
export INPUT_VERSIONFORMAT="{major}.{minor}.{patch}"
export INPUT_MAXPATCH=9
export INPUT_MAXMINOR=12
export SYSTEM_TEAMFOUNDATIONCOLLECTIONURI="https://dev.azure.com/MedbillTrueSight/"
tsc tasks/index.ts
if [ $? -eq 0 ]; 
then 
    node tasks/index.js
else 
    echo "There were errors :(" 
fi
