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
        /ip dhcp-client add interface=$1 dhcp-options="$1,clientid" use-peer-dns=yes add-default-route=no disable=no ; };
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
        /ip route add dst-address=$2 gateway="spoof" distance=2 comment="F$1" check=arp 
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
        :delay 1
        :local Gateway ;
        :set Gateway [/ip dhcp-client get [find interface=$1] value-name=gateway];
        :put $Gateway ;
        :if ([:len $Gateway] != 0 ) do={
            /ip route set gateway="$Gateway%$1" [find comment=$1]
            /ip route set gateway="$Gateway%$1" [find comment=$2]
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
        /interface wireless set $1 mac-address=00:00:00:00:00:26
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
