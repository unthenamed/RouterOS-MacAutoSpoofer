:local name "spoof3";
:local mode "0";
:local interface "wlan3";
:local macList "wlan3.txt";
:local fileSave "wlan2";
:local dstAddressCheck "1.0.0.3";
:local gateway "192.168.5.1";

:global main
$main $name $mode $interface $macList $fileSave $dstAddressCheck $gateway
