# Main function
:while (true) do={
:local dumpMacs [:toarray [/tool mac-scan $hw duration=$duration as-value proplist=mac-address ]] 
    :foreach entry in=$dumpMacs do={
        :if ([:find $entry "mac-address"] != "") do={
            :local mac [: tostr [:pick $entry ([:find $entry "="] + 1) [:len $entry]]]
            :set mac [:pick $mac ([:find $mac "="] + 1) [:len $mac]]
            :if ([:find $macExclude $mac] = []) do={
                :put 8
                :local currentMac [/interface get [find name=$hw] mac]
                :local voucher
                :put $mac
                
        :local change 0
        :local saveCounter 0                
        :while ($change = 0) do={
            do {
:put 9
            :if ([$pingStatus $vrf] !=0 && \
                 [/ip dhcp-client get [find interface=$hw] value-name=status] = "bound") do={
                :set change 0
                
                if ($saveCounter = 0) do={
                    :set voucher [$getVoucher $hw $vrf]
                        if ([:len $voucher] != 0 ) do={
                            $saveMacs $currentMac $voucher $saveFile
                            :set saveCounter 11
                        }
                }

                :put ("	HW ADDR		: $hw@$vrf")
                :put ("	USER		: $voucher")
                :put ("	CURRENT MAC	: $currentMac")
                :put ("	NEXT SET MAC	: $mac")
        
                
            } else={
                :set change 1
                
                # remove
                /ip dhcp-client remove [find interface=$hw]
                /ip address remove [find interface=$hw]
                $genHostname $hw $id
                $changeMacs $hw $mac
                
                /ip dhcp-client remove [find comment="internet detect"]
                /ip dhcp-client add interface=$hw dhcp-options="$hw,clientid" use-peer-dns=no add-default-route=no disable=no ;
                do {:while ([/ip dhcp-client get [find interface=$hw] value-name=status] != "bound") do={:delay 1}}
            }
            } on-error={:put "error main"}
            :delay 5
        }
}}}}}
