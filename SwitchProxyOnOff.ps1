function SwitchProxyOnOff(){
    $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Write-Host "Retrieve the proxy server status ..."
    $proxyServerStatus = Get-ItemProperty -path $regKey ProxyEnable -ErrorAction SilentlyContinue
    # Write-Host $proxyServerStatus.ProxyEnable

    switchProxy
    $rs = refreshsystem
    if (!($rs)) { Write-Warning "Can not force system refresh after proxy change" }

    Start-Sleep -s 3
}

function switchProxy() {
    if($proxyServerStatus.ProxyEnable -eq 0)
    {
        Write-Host "Proxy is actually disabled"
        Set-ItemProperty -path $regKey ProxyEnable -value 1
        Write-Host ""
        Write-Host "==> Proxy is now enabled"
    }
    else
    {
        Write-Host "Proxy is actually enabled"
        Set-ItemProperty -path $regKey ProxyEnable -value 0
        Write-Host ""
        Write-Host "==> Proxy is now disabled"
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