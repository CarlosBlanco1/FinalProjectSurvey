$Computer_System_Info = @("Name", "Model", "TotalPhyicalMemory") 
$OS_Info = @("Caption", "Manufacturer", "Organization", "SerialNumber")
$Computer_Info = @("OsTotalVisibleMemorySize", "OsFreePhysicalMemory")
$GPU_Info = @("Caption", "VideoModeDescription", "MaxRefreshRate", "MinRefreshRate")
$Processor_Info = @("Name","NumberOfCores", "NumberOfLogicalProcessors")
$Disc_Info = @("DeviceID", "DriveType", "ProviderName", "VolumeName", "Size", "FreeSpace")
$Service_Info = @("Name", "DisplayName", "State")

$ComputerName = "<h1>Computer name: $env:computername</h1>"
$OS_HTML = Get-CimInstance -ClassName Win32_OperatingSystem | ConvertTo-Html -As List -Property $OS_Info -Fragment -PreContent "<h2>Operating System Information</h2>"
$GPU_HTML = Get-CimInstance -ClassName win32_VideoController | ConvertTo-Html -As List -Property $GPU_Info -Fragment -PreContent "<h2>Graphics Card Information</h2>"
$Computer_System_HTML = Get-CimInstance -ClassName Win32_ComputerSystem | ConvertTo-Html -As List  -Property $Computer_System_Info -Fragment -PreContent "<h2>Computer System Information</h2>"
$Computer_HTML = Get-ComputerInfo | ConvertTo-Html -As List -Property $Computer_Info -Fragment -PreContent "<h2>OS Memory Information</h2>"
$Processor_HTML = (Get-ComputerInfo -Property CsProcessors).CsProcessors | ConvertTo-Html -As List -Property $Processor_Info -Fragment -PreContent "<h2>Processor Information</h2>"
$Disc_HTML = Get-CimInstance -ClassName Win32_LogicalDisk | ConvertTo-Html -As List -Property $Disc_Info -Fragment -PreContent "<h2>Disk Information</h2>"
$Services_HTML = Get-CimInstance -ClassName Win32_Service | Select-Object -First 10  | ConvertTo-Html -Property $Service_Info -Fragment -PreContent "<h2>Services Information</h2>"
$Services_HTML = $Services_HTML -replace '<td>Running</td>','<td class="RunningStatus">Running</td>' 
$Services_HTML = $Services_HTML -replace '<td>Stopped</td>','<td class="StopStatus">Stopped</td>'

function PopulateDictionary {
    param(
        [scriptblock]$cmdletBlock,
        [string]$className,
        [array]$properties
    )

    $Dictionary = @{}

    foreach ($property in $properties) {
        $scriptSnippet = & $cmdletBlock -ClassName $className | ConvertTo-Html -As List -Property $property -Fragment -PreContent "<h2>$property Information</h2>"
        $Dictionary.Add("$property", "$scriptSnippet")
    }

    return $Dictionary
}

function MergeDictionaries{
    param(
        [hashtable] $D1,
        [hashtable] $D2
    )

    foreach($key in $D2.Keys){
        $D1[$key] = $D2[$key]
    }

    return $D1
}

$CounterToPropertyDictionary = PopulateDictionary -cmdletBlock {param($ClassName) Get-CimInstance -ClassName $ClassName} -className Win32_OperatingSystem -properties $OS_Info
$CounterToPropertyDictionary = MergeDictionaries -D1 $CounterToPropertyDictionary -D2 (PopulateDictionary -cmdletBlock {param($ClassName) Get-CimInstance -ClassName $ClassName} -className win32_VideoController -properties $GPU_Info)
$CounterToPropertyDictionary = MergeDictionaries -D1 $CounterToPropertyDictionary -D2 (PopulateDictionary -cmdletBlock {param($ClassName) Get-CimInstance -ClassName $ClassName} -className Win32_ComputerSystem -properties $Computer_System_Info)
$CounterToPropertyDictionary = MergeDictionaries -D1 $CounterToPropertyDictionary -D2 (PopulateDictionary -cmdletBlock {param($ClassName) Get-CimInstance -ClassName $ClassName} -className Win32_LogicalDisk -properties $Disc_Info)
$CounterToPropertyDictionary = MergeDictionaries -D1 $CounterToPropertyDictionary -D2 (PopulateDictionary -cmdletBlock {param($ClassName) Get-CimInstance -ClassName $ClassName} -className Win32_Service -properties $Service_Info )

$jsonString = $CounterToPropertyDictionary | ConvertTo-Json

$JSONfilePath = "C:\Users\carlo\OneDrive\Escritorio\FinalProjectSurvey\Dictionary.json"

$jsonString | Set-Content -Path $JSONfilePath

$Form = "
    <h1>Expand on a particular metric</h1>
        <form id=`"metricForm`">
            <label for=`"metricValue`">Input Metric:</label><br>
            <select id=`"metricValue`">
                $(foreach ($key in $CounterToPropertyDictionary.Keys)
                {
                    "<option value="`"$key`"">$key</option>"
                })
            </select>
            <input type=`"submit`" id=`"metric`" name=`"metric`">
        </form>"

$header = @"
<meta name="viewport" content="width=device-width, initial-scale=1">

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
        border: 0px; 
        font-family: Arial, Helvetica, sans-serif;
    } 

    td {
        padding: 4px;
        margin: 0px;
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

    td {
        padding: 10px;
    }

    tr:hover {
        background-color: #f0f0f0;
        transform: scale(1.2); 
    }

    .RunningStatus {
        color: #008000;
    }
    
    .StopStatus {
        color: #ff0000;
    }

</style>
"@

$script = @"

    <script>
    document.getElementById('metricForm').addEventListener('submit', function (event) {

        event.preventDefault();

        var userInput = document.getElementById('metricValue');
        const inputData = userInput.value;
        
        const jsonFilePath = './Dictionary.json';

        let PropertyToScriptDic
        
        fetch(jsonFilePath)
        .then((response) => response.json())
        .then(json => 
        {
            PropertyToScriptDic = json;
            ProcessData(PropertyToScriptDic, inputData);
        });
        

        function ProcessData(p, i)
        {
            const divToAppend = document.createElement('div');
            const encodedHtml = p[i];
            let decodedHtml = JSON.parse(``"`${encodedHtml}"``);

            divToAppend.innerHTML = decodedHtml;

            var container = document.getElementById('m-container');

            container.appendChild(divToAppend);           
        }
    });


    </script>

"@

$container = @"
    <div id="m-container">

    </div>
"@

$Report = ConvertTo-HTML -Body "$ComputerName $Form $container $script $OS_HTML $GPU_HTML $Computer_System_HTML $Computer_HTML $Processor_HTML $Disc_HTML $Services_HTML" `
-Title "Computer Information Report" -Head $header -PostContent "<p>Creation Date: $(Get-Date)<p>"

$Report | Out-File .\Report.html

$filePath = "C:\Users\carlo\OneDrive\Escritorio\FinalProjectSurvey\Report.html"

$edgeExecutable = "msedge.exe"

Start-Process -FilePath $edgeExecutable -ArgumentList $filePath