:local fileName "console-dump.txt"

:local fileContent [/file get [/file find name=$fileName] contents]

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


        :put "$counter $macAddress"
        :delay 1


    }
}