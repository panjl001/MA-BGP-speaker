

Command Based program is modified based on BGP simple
Which has alomost the same command as BGP simple
Only One thing need to change

You need to assign two BGP peers.

For example:

 sudo ./command_based.pl -myas 7777 -myip 192.168.10.1 -peerip 192.168.10.2 -peeras 7675 -peerip2 192.168.10.3 -peeras2 7676 -p src/bgp/bgp_data/myroutes -m 10 -n -v




bgp_filter_speaker is an filter example modified based on Command Based program,
which has a feature that speaker would seperate routing inforamtion one by one to two routers separately.

The usage is the same as BGP simple