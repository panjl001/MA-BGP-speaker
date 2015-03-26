
There are two programs:
one is filter function not included, and another one is filter function included.

The program is based on perl language.
After it runs , it would ask you to fill three path of file: one is BGP peer information ,one is filter information ,and the other one is routing information.

For BGP peer information ,it ask user to record network neighbor's IP and AS number and local's corresponding IP and AS
the example configuration file is bgp_peer

For filter information, it includes detailed filter information assigned to each router.
It includes regular expression followed by '@' and followed by remote router's IP 
the example configuration file is filter

routing information should be formed in  either TABLE_DUMP_V2 format or raw binary format.