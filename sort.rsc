:local filesave "aysila.txt"
:local content [/file get [/file find name=console-dump.txt] contents];
:if ([:len [/file find name=$filesave]] = 0) do={
    /file add name=$filesave
 };
:local lineEnd 0; :local lastEnd 140; :local mac ""; :local macline "";:local findmac "";
:while ($lineEnd < [:len $content]) do={

    :set lineEnd [:find $content "\n" $lastEnd];
    :if ([:len $lineEnd] = 0) do={
      :set lineEnd [:len $content];
     } else={
       :set lineEnd ($lineEnd - 21);
       :set mac [:pick $content $lastEnd $lineEnd];
       :set lineEnd ($lineEnd + 21);
       :set lastEnd ($lineEnd + 1);
     };

    :set findmac [/file get [/file find name=$filesave] contents];
    :if ([:len [:find $findmac $mac]] = 0) do={
        :set macline "\n$mac";
        /file set $filesave contents=([get $filesave contents]  .$macline )
        :put "-> $mac saving to list up ... " ;
     };

}
/file remove console-dump.txt
