# Tool that creates a new extension in this project :)

param (
  [Parameter(Mandatory = $true)]
  [string]$ExtensionName
)

Write-Output $ExtensionName

New-Item -Path "./$$" -ItemType Directory
New-Item -Path "./$$/src" -ItemType Directory
Copy-Item -Path "./MyExtensionTemplate/ps_modules" -Destination "./$$/src/ps_modules" -Recurse
Copy-Item -Path "./MyExtensionTemplate/LICENSE" -Destination "./$$/LICENSE"

New-Item -Path "./$$/README.md"
"# $$" | Out-File -FilePath "./$$/README.md"

New-Item -Path "./$$/src/$$.ps1"
@"
[CmdletBinding()]
param()

Trace-VstsEnteringInvocation `$MyInvocation
try {
    Write-Output "Hello world! :)"
} finally {
    Trace-VstsLeavingInvocation `$MyInvocation
}
"@ | Out-File -FilePath "./$$/src/$$.ps1"

New-Item -Path "./$$/src/task.json"
@"
{
  "id": "$(New-Guid)",
  "name": "$$",
  "friendlyName": "$$",
  "description": "Add a Description Here",
  "author": "John Easterday",
  "helpMarkDown": "Replace with markdown to show in help",
  "category": "Utility",
  "visibility": [],
  "demands": [],
  "version": {
    "Major": "1",
    "Minor": "0",
    "Patch": "0"
  },
  "minimumAgentVersion": "1.95.0",
  "instanceNameFormat": "$$ `$(message)",
  "inputs": [],
  "execution": {
    "PowerShell3": {
      "target": "$$.ps1"
    }
  }
}
"@ | Out-File -FilePath "./$$/src/task.json"


New-Item -Path "./$$/vss-extension.json"
@"
{
  "manifestVersion": 1,
  "id": "jmeaster30-$($$.ToLower())",
  "name": "$$",
  "version": "1.0.0",
  "publisher": "jmeaster30",
  "description": "Add a description here :)",
  "public": false,
  "targets": [
    {
      "id": "Microsoft.VisualStudio.Services"
    }
  ],
  "scopes": [],
  "categories": [],
  "icons": {
    "default": "src/icon.png"        
  },
  "content": {
    "details": {
      "path": "README.md"
    },
    "license": {
      "path": "LICENSE"
    }
  },
  "repository": {
    "type": "git",
    "uri": "https://github.com/jmeaster30/ado-extensions/tree/main/$$"
  },
  "files": [
    {
      "path": "src"
    }
  ],
  "contributions": [
    {
      "id": "$$",
      "type": "ms.vss-distributed-task.task",
      "targets": [
        "ms.vss-distributed-task.tasks"
      ],
      "properties": {
        "name": "$$"
      }
    }
  ]
}
"@ | Out-File -FilePath "./$$/vss-extension.json"