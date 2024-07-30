:if ([:len [/system script environment find name=main]] = 0) do={ /system script run env } else={
:if ([:len [/system script job find script=spoof1]] = 0) do={/system script run spoof1} ;
:if ([:len [/system script job find script=spoof2]] = 0) do={/system script run spoof2} ;
:if ([:len [/system script job find script=spoof3]] = 0) do={/system script run spoof3} ;
};