:global config
:local fileConnected ($config -> saveFile)
:local fileDump ($config -> dumpFile)


:global macExclude [:toarray "78:9A:18:CF:60:40"];

:global macConnected [:toarray ""];
:local dataConnected [/file get [find name=$fileConnected] contents];
    :if ( [:len $macConnected] = 0 ) do={
        if ([:len $dataConnected] != 0) do={ 
            :local offset 0
            :while ($offset < [:len $dataConnected]) do={
                :local value
                :local delimeter [:find $dataConnected ";" $offset]
                
                :if ($delimeter = []) do={
                    :set value [:pick $dataConnected $offset [:len $dataConnected]]
                    :set offset [:len $dataConnected]
                } else={
                    :set value [:pick $dataConnected $offset $delimeter]
                    :set offset ($delimeter + 1)
                }
                
                local equal [find $value "="]
                local k [:pick $value 0 $equal]
                local v [:pick $value ($equal + 1) [:len $value]]
 
                :put "	Load $k $v"
                :if ([:find $macConnected $v] = [] ) do={
                    :set ($macConnected -> $k) "$v"
                }
            }
        }
    }
    
    
:global macAddresses [:toarray ""];    
:local macData [/file get [find name=$fileDump] contents];
        if ([:len $macData] != 0) do={
            :local macParse
            :local start 0
            :local zero 0
            :while ($start < [:len $macData]) do={
                :local end [:find $macData ";" $start]
                :if ($end = []) do={
                    :set macParse [:pick $macData $start [:len $macData]]
                    :set start [:len $macData]
                } else={
                    :set macParse [:pick $macData $start $end]
                    :set start ($end + 1)
                }
                :if ([:find $macExclude $macAddresses] = [] && \
                     [$isValidMac $macParse]) do={
                    :set ($macAddresses -> $zero) "$macParse"
                    :set zero ($zero + 1)
                    :put "$zero $macParse"
                }
            }
        }