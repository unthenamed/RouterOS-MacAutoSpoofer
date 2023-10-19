:local name "Spoof1"
:local mode "0";
:local interface "wlan1"; 
:local maclist "macid.txt";
:local succes "macsave";
:local namehost "f09f98912047616b2067616e676775206b6f2c2063756d61206d696e746120696e7465726e65742074657263657061742040";
:local keepalive "15"; 
:local dstcheck "142.250.4.136" ;
:local gateway "192.168.5.1" 

######################################################################
:local content [/file get [/file find name=$maclist] contents];
:local genhostname ""; :local iface $interface; :local findmac "";
:local txt "$succes.txt" ; :local currentmac ""; :local currentmacline "";
:local defaultmac ""; :local lineEnd 0; :local lastEnd 0; :local mac "";


:if ([:len [/file find name=$txt]] = 0) do={
    /file print file=$succes; 
    :delay 1;  
    /file set $txt contents="Mac succes login" ;
};

/ip dhcp-client remove [find comment="internet detect"] ; :delay 1;

:if ([:len [ /ip dhcp-client option find name=$iface]] = 0) do={
    :set genhostname [pick ([/certificate scep-server otp generate minutes-valid=0 as-value]->"password") 0 16];
    /ip dhcp-client option add name=$iface code=12 value="0x$namehost'$genhostname'"; };

:if ([:len [/ip dhcp-client find interface=$iface]] = 0) do={
    /ip dhcp-client add interface=$iface dhcp-options="$iface,clientid" use-peer-dns=yes add-default-route=no disable=no ; };

:if ([:len [ /interface bridge find name=spoof]] = 0) do={
    /interface bridge add name=spoof };
    
:if ([:len [/ip route find comment="F$name"]] = 0) do={
    /ip route add dst-address=$dstcheck gateway="spoof" distance=2 comment="F$name" check=arp };

:if ([:len [/ip route find comment=$name]] = 0) do={
    /ip route add dst-address=$dstcheck gateway="$gateway%$iface" distance=1 comment=$name check=arp };

:if ([:len [/tool netwatch find comment=$iface]] = 0) do={
    /tool netwatch add host=$dstcheck interval=3s comment=$iface };

:while ($lineEnd < [:len $content]) do={
    :set lineEnd [:find $content "\n" $lastEnd];
    :if ([:len $lineEnd] = 0) do={
       :set lineEnd [:len $content];
       :set mac [:pick $content $lastEnd $lineEnd];
       :set lineEnd 0;
       :set lastEnd 0;
    } else={
       :set mac [:pick $content $lastEnd $lineEnd];
       :set lastEnd ($lineEnd + 1);
    };
 
    :while ([/tool netwatch get [find comment=$iface] value-name=status] = "unknown") do={
        :delay 1; 
        :put "pause";
    };
######################################################################
:if ([:len [/interface wireless find mac-address=$mac]] = 0) do={

    :if ([/tool netwatch get [find comment=$iface] value-name=status]  = "up") do={
    :if ([/ip dhcp-client get [find interface=$iface] status] = "bound" ) do={
        # Set Led and Firewall enable
        /beep
        /ip dhcp-client remove [find comment="internet detect"]
        /system leds enable [find interface=$iface]
        /ip route enable [find comment=$iface]
        /ip firewall nat enable [find comment=$iface]
        /ip firewall mangle enable [find comment=$iface]

        :set currentmac [/interface wireles get [/interface wireles find name=$iface] mac-address ] ;
        :set currentmacline "\n$currentmac";
        :set findmac [/file get [/file find name=$txt] contents];
        :if ([:len [:find $findmac $currentmac]] = 0) do={
            /file set $txt contents=([get $txt contents]  . $currentmacline )
            :log warning "| $currentmac | $iface | $[/tool netwatch get [find comment=$iface] value-name=status] | Saving |" ;
            :put "| $currentmac | $iface | $[/tool netwatch get [find comment=$iface] value-name=status] | Saving |" ;
        };

        :if ($mode = 1) do={
            :put "| $currentmac | $iface | $[/tool netwatch get [find comment=$iface] value-name=status] | Reseting |" ;
            /interface wireless set $iface mac-address=00:00:00:00:00:26
        };

        :log warning "| $currentmac | $iface | $[/tool netwatch get [find comment=$iface] value-name=status] | Keep alive |" ;
        :put "| $currentmac | $iface | $[/tool netwatch get [find comment=$iface] value-name=status] | Keep alive |" ;
        :while ([/tool netwatch get [find comment=$iface] value-name=status] = "up") do={:delay $keepalive;};
    };
    };


        # Generate Random Identity
        :set genhostname [pick ([/certificate scep-server otp generate minutes-valid=0 as-value]->"password") 0 16]; 
        /ip dhcp-client option set $iface value="0x$namehost'$genhostname'"

        # Set Led and Firewall disable
        /system leds disable [find interface=$iface]
        /ip route disable [find comment=$iface]
        /ip firewall nat disable [find comment=$iface]
        /ip firewall mangle disable [find comment=$iface]

        # Set Mac to New
        :if ([:len [/interface wireless find mac-address=$mac]] = 0) do={
        /interface wireless set $iface mac-address=$mac
        };
        

        :while ([:len [/ip dhcp-client find interface=$iface]] = 1) do={
        /ip dhcp-client remove $iface
        /ip dhcp-client remove [find comment="internet detect"]
        /ip address remove  [find interface=$iface]
        };
        
        :while ([:len [/ip dhcp-client find interface=$iface]] = 0) do={
        /ip dhcp-client add interface=$iface dhcp-options="$iface,clientid" use-peer-dns=yes add-default-route=no disable=no
        };



     :log warning "| $mac | $iface | $[/tool netwatch get [find comment=$iface] value-name=status] | Change |" ;
     :put "| $mac | $iface | $[/tool netwatch get [find comment=$iface] value-name=status] | Change |" ;
     :put "Waiting DHCP bound..."; 
     :while ([/ip dhcp-client get [find interface=$iface] status] != "bound" ) do={
     :delay 1;
     :while ([:len [/ip dhcp-client find interface=$iface]] = 0) do={ /ip dhcp-client add interface=$iface dhcp-options="$iface,clientid" use-peer-dns=yes add-default-route=no disable=no ;};
     };
     :put "DHCP bound...";
        :if ([/ip dhcp-client get [find interface=$iface] value-name=gateway] != $gateway ) do={
        :set gateway [/ip dhcp-client get [find interface=$iface] value-name=gateway] ;
        /ip route set gateway="$gateway%$iface" [find comment=$iface]
        /ip route set gateway="$gateway%$iface" [find comment=$name]
        };
     :delay 5;
     
};
};
