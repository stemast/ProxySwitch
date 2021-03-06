function SwitchProxyOnOff(){
    $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Write-Host "Retrieve the proxy server status ..."
    $proxyServerStatus = Get-ItemProperty -path $regKey ProxyEnable -ErrorAction SilentlyContinue

    $proxyActive = $proxyServerStatus.ProxyEnable -eq 1
    if ($proxyActive) {
        Write-Host("The proxy is active")
    }
    else{
        Write-Host("The proxy is inactive")
    }
    if (!(isLANConnected)) {
        
        $networkName = getNetworkName
        Write-Host("The connected WLAN is: $networkName")
    
        if (SwitchNeeded -netName $networkName -proxyIsActive $proxyActive)
        {
            switchProxy($proxyActive)
            $rs = refreshsystem
            if (!($rs)) { Write-Warning "Can not force system refresh after proxy change" }
        }
    } 
    else{
        Write-Host("Connected to LAN")
        if (SwitchNeeded -netName "LANConnected" -proxyIsActive $proxyActive)
        {
            switchProxy($proxyActive)
            $rs = refreshsystem
            if (!($rs)) { Write-Warning "Can not force system refresh after proxy change" }
        }
    }   

    Start-Sleep -s 3
}

function SwitchNeeded([String] $netName, [bool] $proxyIsActive) {
    if ($netName.Trim() -eq "LANConnected") {
        return !($proxyIsActive)
    }
    else {
        # List here the SSIDs of the WLANs that does need the proxy
        $arrProxyWLANs = "WLAN_SSID_1", "test"

        if ($arrProxyWLANs -contains $netName) {
            return !($proxyIsActive)
        }

        else {
            return $proxyIsActive
        }
    }
}

function getNetworkName() {
    $netshOut = netsh wlan show interfaces | Select-String '\sSSID'
    $res = $netshOut -match ":\s*(\S*)\s*"
    if ($res) {
        return $matches[1]
    }
}

function isLANConnected() {
    $netshOut = netsh interface ipv4 show interfaces | Select-String 'Local Area Connection'
    $netsplited = $netshOut.Line.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
    return $netsplited[3].Equals("connected") 
}

function switchProxy([bool] $proxyActive) {
    if($proxyActive)
    {
        Write-Host "Proxy is actually enabled"
        Set-ItemProperty -path $regKey ProxyEnable -value 0
        Write-Host ""
        Write-Host "==> Proxy is now disabled"
    }
    else
    {
        Write-Host "Proxy is actually disabled"
        Set-ItemProperty -path $regKey ProxyEnable -value 1
        Write-Host ""
        Write-Host "==> Proxy is now enabled"
    }
}

function refreshsystem() {
    $signature = @'
[DllImport("wininet.dll", SetLastError = true, CharSet=CharSet.Auto)]
public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
'@

    #$INTERNET_OPTION_SETTINGS_CHANGED   = 39
    #$INTERNET_OPTION_REFRESH            = 37
    $INTERNET_OPTION_PROXY_SETTINGS_CHANGED = 95
    $type = Add-Type -MemberDefinition $signature -Name wininet -Namespace pinvoke -PassThru
    $c = $type::InternetSetOption(0, $INTERNET_OPTION_PROXY_SETTINGS_CHANGED, 0, 0)
    #$a = $type::InternetSetOption(0, $INTERNET_OPTION_SETTINGS_CHANGED, 0, 0)
    #$b = $type::InternetSetOption(0, $INTERNET_OPTION_REFRESH, 0, 0)
    Write-Host "Refresh was triggered"
#    return $a -and $b
    return $c
}

SwitchProxyOnOff