# escape=`
FROM mcr.microsoft.com/windows/servercore:ltsc2022

SHELL ["powershell.exe"]
RUN mkdir "c:\LogMonitor"; `
    Invoke-WebRequest -Uri "https://github.com/microsoft/windows-container-tools/releases/download/v2.0.2/LogMonitor.exe" -OutFile "C:\LogMonitor\LogMonitor.exe"

COPY logmonitorconfig.json c:\\logmonitorconfig.json

COPY entrypoint.ps1 c:\\entrypoint.ps1

RUN reg add hklm\system\currentcontrolset\services\cexecsvc /v ProcessShutdownTimeoutSeconds /t REG_DWORD /d 7200  
RUN reg add hklm\system\currentcontrolset\control /v WaitToKillServiceTimeout /t REG_SZ /d 7200000 /f

# With log monitor the teardown works... but no output in container stdout
#CMD ["C:\\LogMonitor\\LogMonitor.exe",  "powershell.exe", "-File", "C:\\entrypoint.ps1" ]

CMD [ "powershell.exe", "-File", "C:\\entrypoint.ps1" ]

