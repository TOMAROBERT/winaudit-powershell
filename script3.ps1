$html = @"
<!DOCTYPE html>
<html>
<head>
  <title>Raport tehnic PC/Laptop</title>
  <style>
    h1 {
      font-family: Arial, Helvetica, sans-serif;
      color: #e68a00;
      font-size: 28px;
    }

    h2 {
      font-family: Arial, Helvetica, sans-serif;
      color: #000099;
      font-size: 16px;
    }

    table {
      font-size: 12px;
      border: 0;
      font-family: Arial, Helvetica, sans-serif;
    }

    td {
      padding: 4px;
      margin: 0;
      border: 0;
    }

    th {
      background: #395870;
      background: linear-gradient(#49708f, #293f50);
      color: #fff;
      font-size: 11px;
      text-transform: uppercase;
      padding: 10px 15px;
      vertical-align: middle;
    }

    tbody tr:nth-child(even) {
      background: #f0f0f2;
    }

    #CreationDate {
      font-family: Arial, Helvetica, sans-serif;
      color: #ff3300;
      font-size: 12px;
    }

    .StopStatus {
      color: #ff0000;
    }

    .RunningStatus {
      color: #008000;
    }

    .scrollable-div {
      max-height: 200px;
      border: 1px solid #ccc;
      padding: 5px;
      overflow-y: auto;
    }

    .table-container {
      max-height: 300px;
      overflow-y: auto;
    }

    .table-pagination {
      margin-top: 10px;
    }

    .tab {
      overflow: hidden;
      border: 1px solid #ccc;
      background-color: #f1f1f1;
    }

    .tab button {
      background-color: inherit;
      float: left;
      border: none;
      outline: none;
      cursor: pointer;
      padding: 14px 16px;
      transition: 0.3s;
      font-size: 17px;
    }

    .tab button:hover {
      background-color: #ddd;
    }

    .tab button.active {
      background-color: #ccc;
    }

    .tabcontent {
      display: none;
      padding: 6px 12px;
      border: 1px solid #ccc;
      border-top: none;
    }
  </style>
</head>
<body>
  <div class="tab">
    <button class="tablinks" onclick="openTab(event, 'Basic')">Basic</button>
    <button class="tablinks" onclick="openTab(event, 'Services')">Services</button>
    <button class="tablinks" onclick="openTab(event, 'Network')">Network</button>
  </div>

  <div id="Basic" class="tabcontent">
    <!-- Basic information content -->
    <!-- Replace with PowerShell variable values -->
    $ComputerName
    $OSinfo
    $ProcessInfo
    $BiosInfo
    $DiscInfoRO1
    $networksParam 
    $localnetwork
  </div>

  <div id="Services" class="tabcontent">
    <!-- Services information content -->
    <!-- Replace with PowerShell variable valuess -->
    $ServicesInfo
  </div>

  <div id="Network" class="tabcontent">
    <!-- Network information content -->
    <!-- Replace with PowerShell variable valuesss -->
  </div>

  <script>
    function openTab(evt, tabName) {
      var i, tabcontent, tablinks;
      tabcontent = document.getElementsByClassName("tabcontent");
      for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
      }
      tablinks = document.getElementsByClassName("tablinks");
      for (i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" active", "");
      }
      document.getElementById(tabName).style.display = "block";
      evt.currentTarget.className += " active";
    }
  </script>
</body>
</html>
"@

# The command below will get the name of the computer
$ComputerName = "<h1>Nume dispozitiv: $env:computername</h1>"

# The command below will get the Operating System information, convert the result to HTML code as table, and store it to a variable
$OSinfo = Get-CimInstance -Class Win32_OperatingSystem | ConvertTo-Html -As List -Property Version, Caption, BuildNumber, Manufacturer -Fragment -PreContent "<h2>Informatii Sistem de Operare</h2>"

# The command below will get the Processor information, convert the result to HTML code as table, and store it to a variable
$ProcessInfo = Get-CimInstance -ClassName Win32_Processor | ConvertTo-Html -As List -Property DeviceID, Name, Caption, MaxClockSpeed, SocketDesignation, Manufacturer -Fragment -PreContent "<h2>Informatii despre Procese</h2>"

# The command below will get the BIOS information, convert the result to HTML code as table, and store it to a variable
$BiosInfo = Get-CimInstance -ClassName Win32_BIOS | ConvertTo-Html -As List -Property SMBIOSBIOSVersion, Manufacturer, Name, SerialNumber -Fragment -PreContent "<h2>Informatii BIOS</h2>"

# Get the total CPU consumed by all processes
$totalCpuConsumed = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue

# Get the processes with CPU consumption and calculate the CPU percentage
$TaskMgr = Get-Process |
    Select-Object ID, @{Name='Nume Proces'; Expression={ $_.ProcessName }}, @{Name='CPUPercentage'; Expression={ "{0:N2}" -f ($_.CPU * 0.01) }} |
    Sort-Object -Property CPUPercentage -Descending |
    Select-Object -First 10 |
    ConvertTo-Html -Property ID, 'Nume Proces', CPUPercentage -Fragment -PreContent "<h2>Top 10 Services/Processes with Highest CPU Consumption</h2>" |
    ForEach-Object { $_ -replace 'CPUPercentage', 'CPUPercentage (%)' }

# Get the processes with RAM consumption and calculate the RAM usage in MB
$TaskMgrRAM = Get-Process |
    Sort-Object -Property ws -Descending |
    Select-Object -First 10 ProcessName, @{Name="Mem Usage(MB)"; Expression={[math]::round($_.ws / 1mb)}} |
    ConvertTo-Html -Property ProcessName, "Mem Usage(MB)" -Fragment -PreContent "<h2>Top 5 Services/Processes with Highest RAM Consumption</h2>"


#The command below will get first 10 services information, convert the result to HTML code as table and store it to a variable
$ServicesInfo = Get-CimInstance -ClassName Win32_Service | Select-Object  |ConvertTo-Html -Property Name,DisplayName,State -Fragment -PreContent "<h2>Informatii despre serviciile existente</h2>"
$ServicesInfo = $ServicesInfo -replace '<td>Running</td>','<td class="RunningStatus">RULEAZA</td>'
$ServicesInfo = $ServicesInfo -replace '<td>Stopped</td>','<td class="StopStatus">OPRIT</td>'



#Check for Windows Updates
$WindowsUpdateSession = New-Object -ComObject Microsoft.Update.Session
$WindowsUpdateSearcher = $WindowsUpdateSession.CreateUpdateSearcher()
$SearchResult = $WindowsUpdateSearcher.Search("IsInstalled=0")
#$UpdatesAvailable = $SearchResult.Updates.Count -gt 0
#if ($UpdatesAvailable) {
#    $UpdatesAvailableString = "<h2>Update-uri Windows disponibile: True</h2>"
#} else {
#    $UpdatesAvailableString = "<h2>Update-uri Windows disponibile: False</h2>"
#}

#Check available Wi-Fi Networks and the Signal
$networksParam = (netsh wlan show networks mode=Bssid) -split '\r?\n' |
    ForEach-Object {
        if ($_ -match '^\s*SSID \d+ :\s*(.*)$') {
            $ssid = $Matches[1].Trim()
        } elseif ($_ -match '^\s*Signal\s+:\s+(\d+)\%') {
            $signalStrength = $Matches[1]
        } elseif ($_ -match '^\s*Channel\s+:\s+(\d+)') {
            $channel = $Matches[1]
            [PsCustomObject]@{
                SSID = $ssid
                'Putere semnal(%)' = $signalStrength
                Canal = $channel
            }
        }
    } |
    Sort-Object -Property 'Putere semnal(%)' -Descending | ConvertTo-Html -Property SSID,'Putere semnal(%)',Canal -Fragment -PreContent "<h2>Retele Wi-Fi disponibile</h2>"


#Collect local network data
$localnetwork = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    $adapterName = $_.Name
    $ipAddress = $_ | Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -eq $adapterName } | Select-Object -ExpandProperty IPAddress
    $subnetMask = $_ | Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -eq $adapterName } | Select-Object -ExpandProperty PrefixLength | ForEach-Object {
        $prefixLength = $_
        $subnetMask = "/$prefixLength"
        $subnetMask
    }
    $dns = $_ | Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses
    $gateway = $_ | Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } | Select-Object -ExpandProperty NextHop

    [PSCustomObject]@{
        'Tip conexiune' = $adapterName
        'Adresa IP' = $ipAddress
        'Mask' = $subnetMask
        DNS = $dns
        Gateway = $gateway
    }
} | ConvertTo-Html -Property 'Tip conexiune', 'Adresa IP', 'Mask', DNS, Gateway -Fragment -PreContent "<h2>Info retea: </h2>"








# Replace the placeholder in the HTML code with the actual values
$html = $html -replace "<!-- Replace with PowerShell variable values -->", "$ComputerName $OSinfo $ProcessInfo $BiosInfo $TaskMgr $TaskMgrRAM $networksParam $localnetwork"
$html = $html -replace "<!-- Replace with PowerShell variable valuess -->", "$ServicesInfo"
$html = $html -replace "<!-- Replace with PowerShell variable valuesss -->", ""




# Save the rendered HTML to a file
$html | Out-File -FilePath ".\Basic-Computer-Information-Reportt.html" -Force
