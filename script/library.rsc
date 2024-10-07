
# Fungsi untuk menyimpan MAC yang terhubung
:global saveMAC do={
    :global macConnected
    :if ([:find $macConnected $1] = [] ) do={
        :set ($macConnected -> $2) "$1"
    }
}

# Fungsi untuk memindai dan menyimpan MAC yang ditemukan
:global scanMAC do={
    :global macAddresses;
    :global macExclude;
    :local scanResults [:toarray [/tool mac-scan $1 duration=$2 as-value proplist=mac-address]];
    :local index [:len $macAddresses];
    :foreach entry in=$scanResults do={
        :local mac [:pick $entry ([:find $entry "="] + 1) [:len $entry]];
        :if ([:find $macAddresses $mac] = [] && [:find $macExclude $mac] = []) do={
            :set ($macAddresses -> $index) "$mac";
            :set index ($index + 1);
        }
    }
}

# Fungsi untuk mendapatkan nama VRF berdasarkan antarmuka
:global getVRF do={
    :return [/ip vrf get number=[find interfaces=$1] value-name=name];
}

# Fungsi untuk mengambil kode voucher dari gateway tertentu
:global fetchID do={
    :local gateway [/ip dhcp-client get [find interface=$1] value-name=gateway];
    :local result [/tool fetch address="$gateway@$2" url=/status mode=http as-value output=user];
    :if ($result -> "status" = "finished") do={
        :local data ($result -> "data");
        :local startPos [:find $data "<h1>Hi, "];
        :local endPos [:find $data "!</h1>"];
        :if ($startPos != "") do={
            :return [:pick $data ($startPos + 8) $endPos];
        }
    }
}

:global randomHW do={

# Array model name dan kumpulan OUI dari masing-masing merek ponsel
:local samsungModels [:toarray "SM-S901B, SM-F936B, SM-A546E, SM-M326B, SM-A146P, SM-A346E, SM-A236B, SM-E145F, SM-A042M, SM-A037F, SM-M135F, SM-A137F, SM-A736B, SM-G990E, SM-A725F, SM-F721B, SM-S901E, SM-M536B, SM-A715F, SM-A528B, SM-A515F, SM-G780F, SM-G998B, SM-N986B, SM-A515F, SM-G781B, SM-A705F, SM-N970F, SM-A507FN, SM-A305F, SM-A920F, SM-G950F, SM-G955F, SM-J730G, SM-J610F, SM-A750GN, SM-A520F, SM-G611F, SM-J600F, SM-J810G, SM-A320Y, SM-G610F, SM-J530Y, SM-G920F, SM-G925F, SM-G935F, SM-G930F, SM-A310F, SM-J700F, SM-G610F"]
:local xiaomiModels [:toarray "Redmi Note 12 Pro, Mi 13, Poco X5 Pro, Mi 11 Lite, Redmi Note 12, Poco X4 GT, Poco F5, Redmi Note 11, Mi 11, Redmi 12C, Redmi 12, Poco M5, Mi 10T Pro, Poco X3 NFC, Poco M4 Pro, Redmi 10A, Redmi 9C, Redmi 10 2022, Mi 10, Mi 9 SE"]
:local oppoModels [:toarray "CPH2459, CPH2457, CPH2411, CPH2399, CPH2363, CPH2451, CPH2457, CPH2381, CPH2371, CPH2333, CPH2291, CPH2135, CPH2235, CPH2145, CPH2223, CPH2173, CPH2061, CPH2179, CPH1937, CPH2121, CPH2065, CPH2185, CPH2197, CPH2043, CPH2047, CPH1941, CPH2037, CPH2063, CPH2015, CPH2089, CPH2071, CPH1923, CPH1921"]
:local vivoModels [:toarray "V2154, V2255, V2034, V2069, V2164, V2152, V2126, V2025, V2040, V2031, V2042, V2026, V2009, V1934, V2026, V2013, V2041, V2030, V2039, V2145, V1938, V1829, V1832, V1941, V1911A, V1911T, V1921A, V1921T, V1818A, V1818T, V1818T, V1921A, V1921T, V1913A, V1913T, V1914A, V1914T, V1816A, V1816T, V1814A, V1814T"]
:local infinixModels [:toarray "RMX3393, RMX3392, RMX3430, RMX3715, RMX3741, RMX3686, RMX2161, RMX2180, RMX3286, RMX2156, RMX2121, RMX2185, RMX3243, RMX2170, RMX2176, RMX3388, RMX2091, RMX2075, RMX2002, RMX1941, RMX1971, RMX1945, RMX2040, RMX2051, RMX2063, RMX1973, RMX2062, RMX2081, RMX2076, RMX1973, RMX1973, RMX1992, RMX1801, RMX1821, RMX1851, RMX1855, RMX1831"]
:local realmeModels [:toarray "RMX1821, RMX2061, RMX1851, RMX1981, RMX2171, RMX1903, RMX2001, RMX2051, RMX2081, RMX1941, RMX2185, RMX2171, RMX2471, RMX2371, RMX3371, RMX2731, RMX3461, RMX2081, RMX3561, RMX3171"]

:local oppoOUI [:toarray "FC:4D:50,B8:27:EB,B0:2D:68,88:79:7E,74:29:AF,40:9C:28,54:4A:16,24:4B:FE,5C:BA:37,0C:D6:BD,34:DA:B7,40:BD:32,48:89:E7,64:A2:F9,70:41:B7,B4:B6:86,EC:89:F5,C8:32:E6,D8:58:D7,94:CC:04"]
:local samsungOUI [:toarray "00:07:AB,00:12:47,00:12:FB,00:13:77,00:15:99,00:15:B9,00:16:32,00:16:6B,00:16:6C,00:16:DB,00:17:C9,00:17:D5,00:18:AF,00:1A:8A,00:1B:98"]
:local vivoOUI [:toarray "00:4C:4E,00:4C:52,00:4C:53,00:4C:57,00:4C:59,00:4C:5C,00:4C:5D,00:4C:5E,00:4C:5F,00:4C:60,00:4C:61,00:4C:62,00:4C:63,00:4C:64,00:4C:65"]
:local realmeOUI [:toarray "FC:D9:6B,7C:FA:D6,AC:39:71,88:AE:35,E0:4C:12,84:E9:C1,A8:EF:5F,54:9A:8F,FC:2A:46,98:AC:EF,BC:2D:EF"]
:local infinixOUI [:toarray "04:F9:93,0C:01:DB,28:D2:5A,30:56:96,40:8E:F6,44:E7:61,54:C0:78,58:10:B7,74:30:9D,74:C1:7D,7C:8B:C1,80:79:5D,88:B8:6F,90:9D:AC,98:74:DA"]
:local xiaomiOUI [:toarray "50:4F:3B,5C:40:71,A4:C3:BE,FC:43:45,00:9E:C8,00:C3:0A,00:EC:0A,04:10:6B,04:7A:0B,04:B1:67,04:C8:07,04:D1:3A,04:CF:8C,04:E5:98,08:1C:6E"]

# Fungsi untuk memilih acak OUI dari array sesuai merek
:local getRandomOUI do={ :return [:pick $1 [:rndnum 0 ([:len $1] - 1)]] }

# Generate Random MAC Address
:local arrhex [:toarray "0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F"]
:local rndmac ""
:local tmp

:for x from=1 to=12 do={
   :set tmp [:rndnum 0 15]
   # Ensure the second byte makes it a valid unicast, locally administered MAC
   :if ($x =  2) do={:set tmp (($tmp | 0x2) & 0xE)}
   :set rndmac "$rndmac$($arrhex->$tmp)"
   # Add colon after every second segment
   :if ($x % 2 = 0) do={:set rndmac "$rndmac:"}
}

# Remove the trailing colon if it exists
:if ([:len $rndmac] > 0) do={
   :set rndmac [:pick $rndmac 0 ([:len $rndmac] - 1)]
}

# Pilih model dan OUI secara acak
:local randomBrandIndex [:rndnum 0 5]
:local selectedBrand ""
:local selectedOUI ""
:local selectedModel ""

:if ($randomBrandIndex = 0) do={
   :set selectedBrand "Samsung"
   :set selectedOUI [$getRandomOUI $samsungOUI]
   :set selectedModel [:pick $samsungModels [:rndnum 0 ([:len $samsungModels] - 1)]]
} else={
   :if ($randomBrandIndex = 1) do={
      :set selectedBrand "Xiaomi"
      :set selectedOUI [$getRandomOUI $xiaomiOUI]
      :set selectedModel [:pick $xiaomiModels [:rndnum 0 ([:len $xiaomiModels] - 1)]]
   } else={
      :if ($randomBrandIndex = 2) do={
         :set selectedBrand "Oppo"
         :set selectedOUI [$getRandomOUI $oppoOUI]
         :set selectedModel [:pick $oppoModels [:rndnum 0 ([:len $oppoModels] - 1)]]
      } else={
         :if ($randomBrandIndex = 3) do={
            :set selectedBrand "Vivo"
            :set selectedOUI [$getRandomOUI $vivoOUI]
            :set selectedModel [:pick $vivoModels [:rndnum 0 ([:len $vivoModels] - 1)]]
         } else={
            :if ($randomBrandIndex = 4) do={
               :set selectedBrand "Infinix"
               :set selectedOUI [$getRandomOUI $infinixOUI]
               :set selectedModel [:pick $infinixModels [:rndnum 0 ([:len $infinixModels] - 1)]]
            } else={
               :set selectedBrand "Realme"
               :set selectedOUI [$getRandomOUI $realmeOUI]
               :set selectedModel [:pick $realmeModels [:rndnum 0 ([:len $realmeModels] - 1)]]
            }
         }
      }
   }
}

# Ganti tiga byte pertama dengan OUI yang dipilih
:set rndmac "$selectedOUI$[:pick $rndmac 8 [:len $rndmac]]"
:set selectedModel [:convert $selectedModel to=hex]
:put $selectedBrand
# Cetak MAC Address dan model acak dari array
:return [:toarray "$rndmac,$selectedModel"]

}

# Fungsi untuk melakukan ping VRF
:global pingVRF do={
    :return [/ping $2 vrf=$1 count=3 size=28];
}

# Fungsi untuk mengubah MAC address dan mengelola DHCP Client
:global changeMAC do={
    
    # Hapus DHCP Client dan alamat IP yang terkait
    do {
        if ([:len [/ip dhcp-client find interface=$1]] = 1) do={
            /ip dhcp-client remove [find interface=$1];
            /ip address remove [find interface=$1];
        }
    } on-error={:return "removing dhcp error"};

    # Set MAC address baru
    do {
        if ([:len [/interface wireless find mac-address=$2]] = 0) do={
            /interface wireless disable $1;
            /interface wireless set $1 mac-address=$2;
            /interface wireless enable $1;
        }
    } on-error={:return "change mac error"};

    # Hapus DHCP Client dengan komentar "internet detect"
    do {
        if ([:len [/ip dhcp-client find comment="internet detect"]] != 0) do={
            /ip dhcp-client remove [find comment="internet detect"];
        }
    } on-error={:return "internet detect cannot removed"};

    # Tambah DHCP Client baru jika belum ada
    do {
        if ([:len [/ip dhcp-client find interface=$1]] = 0) do={
            /ip dhcp-client add interface=$1 dhcp-options="$1,clientid" use-peer-dns=no add-default-route=no disable=no;
        }
    } on-error={:return "add dhcp error"};

    # Set atau tambah opsi DHCP dengan nama hostname
    do {
        if ([:len [/ip dhcp-client option find name=$1]] != 0) do={
            /ip dhcp-client option set [find name=$1] value="0x$3";
        } else={
            /ip dhcp-client option add name=$1 code=12 value="0x$3";
        }
    } on-error={:return "generate random hostname error"};

    # Tambahkan scheduler untuk memonitor status DHCP Client
    do {
        if ([:len [/system scheduler find name="dhcp$1"]] = 0) do={
            /system scheduler add disabled=no interval=20s name="dhcp$1" on-event=":if ([/ip dhcp-client get [find interface=$1] status] = \"searching...\") do={ /interface wireless set $1 mac-address=$4 };" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-time=startup;
        }
    } on-error={:return "adding stuck error"};

    # Tunggu hingga DHCP Client terhubung
    do {
        :while ([/ip dhcp-client get [find interface=$1] status] != "bound") do={:delay 1};
    } on-error={:return "wait to bound error"};

    # Hapus scheduler setelah terhubung
    do {
        if ([:len [/system scheduler find name="dhcp$1"]] != 0) do={
            /system scheduler remove "dhcp$1";
        }
    } on-error={:return "remove stuck error"};
}
