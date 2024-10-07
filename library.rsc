:global macAddresses [:toarray ""];
:global macExclude [:toarray ""];
:global macConnected [:toarray ""];

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
    :local scanResults [:toarray [/tool mac-scan $interface duration=$duration as-value proplist=mac-address]];
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

# Fungsi untuk melakukan ping VRF
:global pingVRF do={
    :return [/ping 172.16.194.101 vrf=$1 count=3 size=28];
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
            /ip dhcp-client option set [find name=$1] value=$rdHostname;
        } else={
            /ip dhcp-client option add name=$1 code=12 value=$rdHostname;
        }
    } on-error={:return "generate random hostname error"};

    # Tambahkan scheduler untuk memonitor status DHCP Client
    do {
        if ([:len [/system scheduler find name="dhcp$1"]] = 0) do={
            /system scheduler add disabled=no interval=20s name="dhcp$1" on-event=":if ([/ip dhcp-client get [find interface=$1] status] = \"searching...\") do={ /interface wireless set $1 mac-address=$3 };" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-time=startup;
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