:while ([:len [/system script environment find name=scanMAC]] = 0) do={:delay 5}

    :global config
    :global scanMAC
    :local fileDump ($config -> "dumpFile")
    :local duration ($config -> "durationScan")
    :local hw ($config -> "hwList")
    :set hw "wlan$[:rndnum 0 $hw]"

    $scanMAC $hw $duration