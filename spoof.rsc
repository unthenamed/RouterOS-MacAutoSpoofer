:local name "spoof";
:local mode "0";
:local interface "wlan1";
:local macList "aysila.txt";
:local fileSave "macid";
:local dstAddressCheck "1.0.0.1";
:local gateway "192.168.5.1";

# load all environment
:global checkFileSaveMacConnected ; :global saveMacConnected ; :global checkDhcpCustomHostname ;
:global generateDhcpCustomHostname ; :global checkDhcpClient ; :global removeDhcpClient ;
:global checkBridgeNoInternet ; :global checkFailoverInterface ; :global checkRouteInterface ; 
:global checkAndChangeGateway ; :global checkNetwatchInterface ; :global checkNetwatchUnknown ;
:global removeInternetDetect ; :global firewallState ; :global scanMode ; 
:global keepAliveInternetConnected ; :global changeMacAddress ; :global addDhcpAntiStuck ;
:global removeDhcpAntiStuck ; :global waitingDhcpBound ; :global nameCustomHost ;
:global keepAliveDelay ; :global resetFailoverInterface ; :local interfaces $interface ;

# configuration check
:do { $removeInternetDetect } on-error={:put "error removeInternetDetect"};
:do { $removeDhcpAntiStuck $name } on-error={:put "error removeDhcpAntiStuck"};
:do { $checkFileSaveMacConnected $fileSave } on-error={:put "error checkFileSaveMacConnected"};
:do { $checkDhcpCustomHostname $interface $nameCustomHost } on-error={:put "error checkDhcpCustomHostname"};
:do { $checkDhcpClient $interface } on-error={:put "error checkDhcpClient"};
:do { $checkBridgeNoInternet } on-error={:put "error checkBridgeNoInternet"};
:do { $checkFailoverInterface $name $dstAddressCheck } on-error={:put "error checkFailoverInterface"};
:do { $checkRouteInterface $interface $name $gateway $dstAddressCheck } on-error={:put "error checkRouteInterface"};
:do { $checkNetwatchInterface $interface } on-error={:put "error checkNetwatchInterface"};

# running loop
:local content [/file get [/file find name=$macList] contents];
:local lineEnd 0; :local lastEnd 0; :local macAddress "";
:while ($lineEnd < [:len $content]) do={
    :set lineEnd [:find $content "\n" $lastEnd];
    :if ([:len $lineEnd] = 0) do={
       :set lineEnd [:len $content];
       :set macAddress [:pick $content $lastEnd $lineEnd];
       :set lineEnd 0;
       :set lastEnd 0;
     } else={
       :set macAddress [:pick $content $lastEnd $lineEnd];
       :set lastEnd ($lineEnd + 1);
     };

    :do { $checkNetwatchUnknown $interface } on-error={:put "error checkNetwatchUnknown"};
    :if ([:len $macAddress] = "17" ) do={
        :if ([/tool netwatch get [find comment=$interfaces] value-name=status]  = "up") do={
            :if ([/ip dhcp-client get [find interface=$interfaces] status] = "bound" ) do={
                :do { $firewallState $interface 1 } on-error={:put "error firewallState"};
                :do { $saveMacConnected $interface $fileSave } on-error={:put "error saveMacConnected"};
                :do { $scanMode $interface $mode } on-error={:put "error scanMode"};
                :do { $keepAliveInternetConnected $interface $keepAliveDelay $nameCustomHost} on-error={:put "error keepAliveInternetConnected"};
             };
         };
        :do { $resetFailoverInterface $name } on-error={:put "error resetFailoverInterface"};
        :do { $generateDhcpCustomHostname $interface $nameCustomHost } on-error={:put "error generateDhcpCustomHostname"};
        :do { $firewallState $interface 0 } on-error={:put "error firewallState"};
        :do { $changeMacAddress $interface $macAddress } on-error={:put "error changeMacAddress"};
        :do { $removeDhcpClient $interface } on-error={:put "error removeDhcpClient"};
        :do { $removeInternetDetect } on-error={:put "error removeInternetDetect"};
        :do { $checkDhcpClient $interface } on-error={:put "error checkDhcpClient"};
        :do { $addDhcpAntiStuck $interface $name } on-error={:put "error addDhcpAntiStuck"};
        :do { $waitingDhcpBound $interface } on-error={:put "error waitingDhcpBound"};
        :do { $removeDhcpAntiStuck $name } on-error={:put "error removeDhcpAntiStuck"};
        #:do { $checkAndChangeGateway $interface $name $gateway } on-error={:put "error checkAndChangeGateway"};
        :do { $resetFailoverInterface $name } on-error={:put "error resetFailoverInterface"};
        :delay 5;
     };
 };
