#! /usr/bin/perl
use strict;
use warnings;
use Thread;
#use Tk;
use threads::shared;
use Getopt::Long;
use Net::BGP;
use Net::BGP::Process;
 # program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# The program is improved based on BGP simple, which could be found on https://code.google.com/p/bgpsimple/
#
# And this improved program could be found on https://github.com/panjl001/MA-BGP-speaker 
 my %BGP_ERROR_CODES = (
			1 => { 		__NAME__ => "Message Header Error", 
				 	1 => "Connection Not Synchronized", 
					2 => "Bad Message Length", 
					3 => "Bad Message Type",
			},
			2 => {		__NAME__ => "OPEN Message Error",
					1 => "Unsupported Version Number",
					2 => "Bad Peer AS",
					3 => "Bad BGP Identifier",
					4 => "Unsupported Optional Parameter",
					5 => "[Deprecated], see RFC4271",
					6 => "Unacceptable Hold Time",
			},
			3 => { 		__NAME__ => "UPDATE Message Error",
					1 => "Malformed Attribute List",
					2 => "Unrecognized Well-known Attribute",
					3 => "Missing Well-known Attribute",
					4 => "Attribute Flags Error",
					5 => "Attribute Length Error",
					6 => "Invalid ORIGIN Attribute",
					7 => "[Deprecated], see RFC4271",
					8 => "Invalid NEXT_HOP Attribute",
					9 => "Optional Attribute Error",
					10 => "Invalid Network Field",
					11 => "Malformed AS_PATH",
			},
			4 => {		__NAME__ => "Hold Timer Expired",
			},
			5 => {		__NAME__ => "Finite State Machine Error",
			},
			6 => {		__NAME__ => "Cease",
					1 => "Maximum Number of Prefixes Reached",
					2 => "Administrative Shutdown",
					3 => "Peer De-configured",
					4 => "Administrative Reset",
					5 => "Connection Rejected",
					6 => "Other Configuration Change",
					7 => "Connection Collision Resolution",
					9 => "Out of Resources",
			},
);
 
			my $i=0;		
			my $ip_peer;
			my $route;
			my $filter;

			print "please input the file name of bgp peer !\n";
			$ip_peer = <STDIN>;
			print "please input the file name of bgp routing table information! \n";
			$route = <STDIN>;
			print "please input the file name of BGP filter,if not input enter! \n";
			$filter = <STDIN>;
			chomp($ip_peer);
			chomp($route);
			chomp($filter);
#			print "bgp file session file is : $ip_peer , bgp routing information is : $route , filter file is : $filter \n";

 			if (($ip_peer)&($route))
 			{
 			
 	# entering the real main program of BGP
 	#			print "show correctly!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!n";
 	#			print "$ip_peer      $route";
 	
 	
 				if ((!open(IPFILE,$ip_peer))|(!open(ROUTEFILE,$route)))
				{
					close IPFILE;
 					close ROUTEFILE;
 					die "Please confirm file name to make it at least exists!!!!!!!n";
 				}
 				else
 				{
 					if ($i !=0)
 					{
 						threads->exit();
 					}
 					$i++;
# 					print "initalizing BGP program\n";
 					my $myas;
 					my $myip;
 					my $peeras;
 					my $peerip;
 					my $tempcount=0;
 					
 					if ($filter)
 					{
 						if (!open(FILTERFILE,$filter))
 						{
 							close FILTERFILE;
 							die "Please confirm FILTER file name to make it at least correctly exists!!!!!!!n";
 						}
 						else
 						{
 							my %regex_filter = <FILTERFILE>;
 								if (%regex_filter)
 								{
 									foreach my $key (keys %regex_filter)
 									{
 										die "Key " . uc($key) . " is not valid.n" 		unless (uc($key) =~ /NEIG|NLRI|ASPT|ORIG|NXHP|LOCP|MED|COMM|ATOM|AGG/); 
 										die "Regex " . $regex_filter{$key} . " is bogus.n" 	unless ( eval { qr/$regex_filter{$key}/ } );
 										# convert hash keys to upper case
 										$regex_filter{uc($key)} = delete $regex_filter{$key};
 									}
 								}
 							close FILTERFILE;
 						}
 					}
 					
 					
 						

 					close ROUTEFILE;
 #					print "$route \n";
 					
 					rename($route,"routing_information_base");

					my @threads;
					
					
					close IPFILE;
					
					
					open(IPFILE,$ip_peer);
 					while (<IPFILE>)
 					{
 						my $line = $_;
 						chomp($line);
#						print "this is test location to see how many to show!\n $line \n";
				 		my @temp = split (/\|/,$line);
#
						$temp[4]= $route;
						$temp[5]= $filter;
#
#						print "this is test location to show some information of BGP PEER SESSION!\n";
#						print "@temp\n";
#						print "$temp[0]            $temp[1]       $temp[2]       $temp[3]   $temp[4]\n";
#
#
 #	
#						print "start one thread in loop! this is the $tempcount time to run it! \n";
						$threads[$tempcount]=Thread->new(\&start_thread,$temp[0],$temp[1],$temp[2],$temp[3],$temp[4],$temp[5]);
#						print "start one thread in loop! this is the $tempcount time to run it! \n";
						$threads[$tempcount]->detach();
#						print "start one thread in loop! this is the $tempcount time to run it! \n";
						$tempcount++;

				
 					}
 	
 					
 				}
 				
 				close IPFILE;
 				close ROUTEFILE;
 				
 				sleep 10;
 	
 				
 				
 			}
 			else
 			{
 	
 				die "Please input both file name to run BGP speaker program!Program will exit automatically!n";
 			}
 			

			while (1)
			{
				;
			
			}
 
sub start_thread
{

		my $line = $_;
 		my @temp = split (/\|/,$line);
 		my $myip = $temp[0];
 		my $myas = $temp[1];
 		my $peerip = $temp[2];
 		my $peeras = $temp[3];

		my $infile = "routing_information_base";
		my $filter_file = "";

#	print "$myip   \n   $myas   \n       $peerip   \n     $peeras   \n  $infile   $filter_file \n";		 
#	sleep 5;			
#	print "this is a debug location!\n";
	


	my $holdtime = 60;
	my $keepalive = 20;
	my $nolisten = 0;
	my $next_hop_self = "0";
	my $adj_next_hop = 0;

	my $peer_type = ( $myas == $peeras ) ? "iBGP" : "eBGP";
	
	if ($next_hop_self ne "0") 
	{
		if ($peer_type eq "eBGP")
		{
			sub_debug ("i","Force to change next hop ignored due to eBGP session (next hop self implied here).\n");
			$adj_next_hop = 1;
			$next_hop_self = "$myip";
		} elsif ($peer_type eq "iBGP") 
		{
			if ($next_hop_self eq "")
			{
				$adj_next_hop = 1;
				$next_hop_self = "$myip";
			} else 
			{
				die "Next hop self IP address is not valid: $next_hop_self" if sub_checkip($next_hop_self);
				$adj_next_hop = 1;
			}
		}
	} else 
	{
		$adj_next_hop = 0;
		$next_hop_self = "$myip";
	};
	
	open (ATTR , ">>attr") or die "There are no default attribution file! \n";
		print ATTR "$peerip|";
		print ATTR "$next_hop_self|";
		print ATTR "$myas|";
		print ATTR "$peer_type|";
		print ATTR "$adj_next_hop\n";
	close ATTR;
	
#	print "this is the next debug location!\n";
#	print "myas is $myas , peertype is $peer_type, nexthopself is $next_hop_self , adjnexthop is $adj_next_hop   \n  ";


	my $bgp  = Net::BGP::Process->new( ListenAddr => $myip );
	my $peer = Net::BGP::Peer->new(
	        Start    		=> 0,
	        ThisID   		=> $myip,
	        ThisAS   		=> $myas,
	        PeerID   		=> $peerip,
	        PeerAS   		=> $peeras,
		HoldTime		=> $holdtime,
		KeepAliveTime		=> $keepalive,
		Listen			=> !($nolisten),
	        KeepaliveCallback    	=> \&sub_keepalive_callback,
	        UpdateCallback       	=> \&sub_update_callback,
	        NotificationCallback 	=> \&sub_notification_callback,
	        ErrorCallback        	=> \&sub_error_callback,
	        OpenCallback        	=> \&sub_open_callback,
	        ResetCallback        	=> \&sub_reset_callback,
	);
	
	# full update required
	my $full_update = 0;
	die "can not open or locate full_update signal.\n"   if (!open(full_update_signal,">full_update"));
	print full_update_signal $full_update;
	close full_update_signal;
#	print "this is BGP session location to debug one!\n";
	$bgp->add_peer($peer);
#	print "this is BGP session location to debug two!\n";
	$peer->add_timer(\&sub_timer_callback, 10, \$bgp);
#		print "this is BGP session location to debug three!\n";
	$bgp->event_loop();
#	print "this is BGP session location to debug four!\n";
}
                           
                           
                           
                           
                           
                           
                           
                           
                           
                           
                           
                           
sub sub_debug
{
	my $level = shift(@_);	
	my $msg   = shift(@_);	

#	print $msg if ($level eq "m");				# mandatory
#	print $msg if ($level eq "e");				# error
#	print $msg if ($level eq "u");				# UPDATE
#	print $msg if ( ($level eq "i") && ($verbose >= 1) );	# informational
#	print $msg if ( ($level eq "d") && ($verbose >= 2) );	# debug

	
	print $msg;
#	
#	if ( ($outfile) && ($level eq "u") )
#	{
#		open (OUTPUT,">>$outfile") || die "Cannot open file $outfile"; 
#		print OUTPUT "$msg";	
#		close (OUTPUT);
#	}
}

sub sub_checkip
{
	("@_" !~ /^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$/) 
	? 1 : 0;

}

sub sub_checkas
{
	("@_" !~ /^([1-9]\d?\d?\d?|[1-5]\d\d\d\d|6[0-4]\d\d\d|65[0-4]\d\d|655[0-2]\d|6553[0-5])$/) ? 1 : 0;
}

sub sub_checkaspath
{
	("@_" !~ /^(([1-9]\d?\d?\d?|[1-5]\d\d\d\d|6[0-4]\d\d\d|65[0-4]\d\d|655[0-2]\d|6553[0-5]))(((\s| \{|,)([1-9]\d?\d?\d?|[1-5]\d\d\d\d|6[0-4]\d\d\d|65[0-4]\d\d|655[0-2]\d|6553[0-5]))\}?)*$|^$/) ? 1 : 0;
}


sub sub_checkcommunity
{
	("@_" !~ /^(([0-9]\d?\d?\d?|[1-5]\d\d\d\d|6[0-4]\d\d\d|65[0-4]\d\d|655[0-2]\d|6553[0-5])\:([1-9]\d?\d?\d?|[1-5]\d\d\d\d|6[0-4]\d\d\d|65[0-4]\d\d|655[0-2]\d|6553[0-5]))( (([1-9]\d?\d?\d?|[1-5]\d\d\d\d|6[0-4]\d\d\d|65[0-4]\d\d|655[0-2]\d|6553[0-5])\:([1-9]\d?\d?\d?|[1-5]\d\d\d\d|6[0-4]\d\d\d|65[0-4]\d\d|655[0-2]\d|6553[0-5])))*$|^$/) ? 1 : 0;
}

sub sub_checkprefix
{
	("@_" !~ /^(([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\/(\d|[12]\d|3[0-2])\s?)+$/) 
	? 1 : 0;

}

sub sub_connect_peer
{
	
	my ($peer) = shift(@_);
	my ($bgp) = shift(@_);
	
    	my $peerid = $peer->peer_id();
        my $peeras = $peer->peer_as();

	$bgp->remove_peer($peer);
	$bgp->add_peer($peer);


	die "can not open or locate full_update signal.\n"   if (!open(full_update_signal,">full_update"));
	print full_update_signal 0;
	close full_update_signal;
}

sub sub_timer_callback
{
        my ($peer) = shift(@_);
        my ($bgp) = shift(@_);
        my $infile = "routing_information_base";
        my $filter = "";
        my $peerid = $peer->peer_id();
        my $peeras = $peer->peer_as();

		print "this is to show peer ip : $peerid  \n";

#		print "this is a location to debug the name of routing and filter !\n\n\n#########################################################\n";
#		print "$infile    $filter\n";

		my $full_update = 0;
		die "can not open or locate full_update signal.\n"   if (!open(full_update_signal,">full_update"));
		print full_update_signal $full_update;
		close full_update_signal;


	if (! $peer->is_established)
	{ 
		sub_debug ("d", "Loop: trying to establish session.\n");
		sub_connect_peer($peer,\$bgp); 


	} elsif (($infile) && (! $full_update))
	{ 	
#		print "this is debug location !!!!!!!!!!!!!!!\n";

		sub_debug ("m","Sending full update.\n");

		$full_update = 1;
		die "can not open or locate full_update signal.\n"   if (!open(full_update_signal,"<full_update"));
		$full_update = <full_update_signal>;
		close full_update_signal;
		sub_update_from_file($peer);

		sub_debug ("m", "Full update sent.\n");
	} else
	{
		sub_debug ("d", "Nothing to do.\n");
	}
}

sub sub_open_callback
{
        my ($peer) = shift(@_);
        my $peerid = $peer->peer_id();
        my $peeras = $peer->peer_as();
        sub_debug ("i","Connection established with peer $peerid, AS $peeras.\n");
		die "can not open or locate full_update signal.\n"   if (!open(full_update_signal,">full_update"));
		print full_update_signal 0;
		close full_update_signal;
}

sub sub_reset_callback
{
        my ($peer) = shift(@_);
        my $peerid = $peer->peer_id();
        my $peeras = $peer->peer_as();
        sub_debug ("e","Connection reset with peer $peerid, AS $peeras.\n");
	
}

sub sub_keepalive_callback
{
	my ($peer) = shift(@_);
	my $peerid = $peer->peer_id();
	my $peeras = $peer->peer_as();
	sub_debug ("d","Keepalive received from peer $peerid, AS $peeras.\n");

}

sub sub_update_callback
{
	my ($peer) = shift(@_);
	my ($update) = shift(@_);
	my $peerid =  $peer->peer_id();
	my $peeras =  $peer->peer_as();
	my $nlri_ref = $update->nlri();
	my $locpref = $update->local_pref();
	my $med = $update->med();
	my $aspath = $update->as_path();
	my $comm_ref = $update->communities();
	my $origin = $update->origin();
	my $nexthop = $update->next_hop();
	my $aggregate = $update->aggregator();

	sub_debug ("u","Update received from peer [$peerid], ASN [$peeras]: ");

	my @prefixes = @$nlri_ref;
	sub_debug ("u","prfx [@prefixes] ");

	sub_debug ("u", "aspath [$aspath] ");
	sub_debug ("u", "nxthp [$nexthop] ")	if ($nexthop);
	sub_debug ("u", "locprf [$locpref] ") 	if ($locpref);
	sub_debug ("u", "med [$med] ")		if ($med);
	sub_debug ("u", "comm ");

	my @communities = @$comm_ref;
	sub_debug ("u", "[@communities] " );
	
	sub_debug ("u", "orig [IGP] ") if ($origin eq "0");
	sub_debug ("u", "orig [EGP] ") if ($origin eq "1");
	sub_debug ("u", "orig [INCOMPLETE] ") if ($origin eq "2");

	my @aggregator = @$aggregate;
	sub_debug ("u", "agg [@aggregator]\n");

}

sub sub_notification_callback
{
	my ($peer) = shift(@_);
	my ($msg) = shift(@_);

       	my $peerid =  $peer->peer_id();
        my $peeras =  $peer->peer_as();
	my $error_code = $msg->error_code();
	my $error_subcode = $msg->error_subcode();
	my $error_data = $msg->error_data();

	my $error_msg = $BGP_ERROR_CODES{ $error_code }{ __NAME__ };
	sub_debug ("e", "Notification received: type [$error_msg]");
	sub_debug ("e", " subcode [" . $BGP_ERROR_CODES{ $error_code }{ $error_subcode } . "]")	if ($error_subcode);
	sub_debug ("e", " additional data: [" .  unpack ("H*", $error_data) . "]") 		if ($error_data);
	sub_debug ("e", "\n");

}

sub sub_error_callback
{
	my ($peer) = shift(@_);
	my ($msg) = shift(@_);

       	my $peerid = $peer->peer_id();
        my $peeras = $peer->peer_as();
	my $error_code = $msg->error_code();
	my $error_subcode = $msg->error_subcode();
	my $error_data = $msg->error_data();

	my $error_msg = $BGP_ERROR_CODES{ $error_code }{ __NAME__ };
	sub_debug ("e", "Error occured: type [$error_msg]");
	sub_debug ("e", " subcode [" . $BGP_ERROR_CODES{ $error_code }{ $error_subcode } . "]")	if ($error_subcode);
	sub_debug ("e", " additional data: [" .  unpack ("H*", $error_data) . "]") 		if ($error_data);
	sub_debug ("e", "\n");
}

sub sub_update_from_file
{

	my ($peer) = shift(@_);
	my $infile = "routing_information_base";
	my $filter_name = "";
	
	my $cur = 1;
	my %regex_filter;
#	my $prefix_limit = 100;
	my $prefix_limit = 100000;	
	my $dry = 0 ;
	my $default_local_pref = 0;
	
	my $myas;
	my $peer_type;
	my $next_hop_self;
	my $adj_next_hop;

	my $temple = $peer->peer_id();




 my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
               open (TIME,">>time");
                my $temp = $hour."\:".$min."\:".$sec."\n";

                print TIME $temp;
               # print "$hour\:$min\:$sec\n";
                close TIME;



	
	open (INPUT, $infile) || die "Could not open $infile\n";
#	print "this is a debug location!\n";
	open (ATTR , "<attr") or die "There are no defaulet attribution file! \n";
	while (<ATTR>)
 	{
		s/^\n//;
	}
#	print "this is aaa debug location!\n";

	open (ATTR , "<attr") or die "There are no defaulet attribution file! \n";
		while (<ATTR>)
 		{
 						my $line = $_;
 				 		my @temp = split (/\|/,$line);
 						if	($temp[0] eq $temple)
 						{
 				 			$next_hop_self = ($temp[1]);
 				 			$myas = ($temp[2]);
 				 			$peer_type = ($temp[3]);
 				 			$adj_next_hop = ($temp[4]);
 				 			chomp($adj_next_hop);
 				 			print "this is in location update to show peerip: $temple  \n   nexthoself is : $next_hop_self \n adjnexthop is $adj_next_hop\n   and comparing to temp data structure: @temp";
 				 			last;
 				 		}
						
 		}
	close ATTR;
	
	
	
#	print "this is the next debug location!\n";
#	print "myas is $myas , peertype is $peer_type, nexthopself is $next_hop_self , adjnexthop is $adj_next_hop   \n  ";
#	sleep 10;
	

	if ($filter_name)
	{
			open(FILTER,$filter_name) or die "$filter_name can not be opened!\n" ;

			my $line = <FILTER>;
			print "$line \n";
			my @temp = split /\=/,$line;
			%regex_filter = (
					$temp[0] => $temp[1]
					);
					
			foreach my $key (keys %regex_filter)
			{
				die "Key " . uc($key) . " is not valid.\n" 		unless (uc($key) =~ /NEIG|NLRI|ASPT|ORIG|NXHP|LOCP|MED|COMM|ATOM|AGG/); 
				die "Regex " . $regex_filter{$key} . " is bogus.\n" 	unless ( eval { qr/$regex_filter{$key}/ } );
				# convert hash keys to upper case
				$regex_filter{uc($key)} = delete $regex_filter{$key};
			}
		

		close FILTER;
	}
	

	while (<INPUT>)
	{
		my $line = $_;
		chomp($line);
			
		my @nlri = split /\|/,$line; 

		# Filter based on advertising neighbor?
		if (($regex_filter{"NEIG"}) && ($nlri[3] !~ qr/$regex_filter{"NEIG"}/) )
		{
			sub_debug ("d", "Line [$.], Neighbor [$nlri[3]] skipped due to NEIG filter (value was: $nlri[3]).\n");
			next;
		};

		# Prefix valid?
		if (sub_checkprefix($nlri[5]))
		{
			sub_debug ("d", "Line [$.],Prefix [$nlri[5]] failed because of wrong prefix format.\n");
			next;
		}; 

		# Filter based on prefix?
		if (($regex_filter{"NLRI"}) && ($nlri[5] !~ qr/$regex_filter{"NLRI"}/) )
		{
			sub_debug ("d", "Line [$.], Prefix [$nlri[5]] skipped due to NLRI filter (value was: $nlri[5]).\n");
			next;
		};

		my $prefix = $nlri[5];

		# AS_PATH valid?
		if (sub_checkaspath($nlri[6]))
		{
			sub_debug ("d", "Line [$.], Prefix [$prefix] failed because of wrong AS_PATH format.\n");
			next;
		};

		# Filter based on AS_PATH?
		if (($regex_filter{"ASPT"}) && ($nlri[6] !~ qr/$regex_filter{"ASPT"}/) )
		{
			sub_debug ("d", "Line [$.], Prefix [$prefix] skipped due to ASPT filter (value was: $nlri[6]).\n");
			next;
		};
	
		my $aspath = Net::BGP::ASPath->new($nlri[6]);
 		
		# add own AS for eBGP adjacencies
                $aspath += "$myas" if ($peer_type eq "eBGP");

		# Community valid?
		if (sub_checkcommunity($nlri[11]))
		{
			sub_debug ("d", "Line [$.], Prefix [ $prefix ] failed because of wrong COMMUNITY format.\n");
			next;
		};

		# Filter based on COMMUNITY?
		if (($nlri[11]) && ($regex_filter{"COMM"}) && ($nlri[11] !~ qr/$regex_filter{"COMM"}/) )
		{
			sub_debug ("d", "Line [$.], Prefix [$prefix] skipped due to COMM filter (value was: $nlri[11]).\n");
			next;
		};

		my @communities = split / /,$nlri[11]; 


		# Filter based on LOCAL_PREF?
		# note: line is skipped if LOCP filter is specified, but line doesnt contain any LOCAL_PREF values 
		# also, for iBGP peerings, LOCAL_PREF is forced to $default_local_pref if none is provided
		my $local_pref;
		if  (($nlri[9] ne "0") && ($nlri[9] ne "")) 
		{
			if ( ($regex_filter{"LOCP"}) && ($nlri[9] !~ qr/$regex_filter{"LOCP"}/) )
			{
				sub_debug ("d", "Line [$.], Prefix [$prefix] skipped due to LOCP filter (value was: $nlri[9]).\n");
				next;
			} else
			{
				$local_pref = $nlri[9];
			}
		} elsif ($regex_filter{"LOCP"})
		{
			sub_debug ("d", "Line [$.], Prefix [$prefix] skipped - doesnt contain LOCAL_PREF value, but LOCP filter specified.\n");
			next;
		} elsif ($peer_type eq "iBGP")
		{
			sub_debug ("d", "Line [$.], Prefix [$prefix] - doesnt contain valid LOCAL_PREF value but we peer via iBGP (value forced to $default_local_pref).\n");
			$local_pref = $default_local_pref;
		};		

		# Filter based on MED?
		# note: line is skipped if MED filter is specified, but line doesnt contain any MED values 
		# (use -f MED='' in such a case)
		my $med;
		if  (($nlri[10] ne "0") && ($nlri[10] ne "")) 
		{
			if ( ($regex_filter{"MED"}) && ($nlri[10] !~ qr/$regex_filter{"MED"}/) )
			{
				sub_debug ("d", "Line [$.], Prefix [$prefix] skipped due to MED filter (value was: $nlri[10]).\n");
				next;
			} else
			{
				$med = $nlri[10];
			}
		} else
		{
			if ($regex_filter{"MED"})
			{
				sub_debug ("d", "Line [$.], Prefix [$prefix] skipped - doesnt contain MED value, but MED filter specified.\n");
				next;
			}	
		};		

		# NEXT_HOP valid?
		if (sub_checkip($nlri[8]))
		{
			sub_debug ("d", "Line [$.], Prefix [ $prefix ] failed because of wrong NEXT_HOP format.\n");
			next;
		}; 

		# Filter based on NEXT_HOP?
		if (($regex_filter{"NXHP"}) && ($nlri[8] !~ qr/$regex_filter{"NXHP"}/) )
		{
			sub_debug ("d", "Line [$.], Prefix [$prefix] skipped due to NXHP filter (value was: $nlri[8]).\n");
			next;
		};
		my $nexthop = $nlri[8];

             	# force NEXT_HOP change for eBGP sessions, or if requested for iBGP sessions
                $nexthop = $next_hop_self if ( ($peer_type eq "eBGP") || ($peer_type eq "iBGP") && ($adj_next_hop) );

		my $origin;
		
		# Filter based on ORIGIN?
		# note: line is skipped if ORIGIN filter is specified, but line doesnt contain vaild ORIGIN values 
		# if no filter is specified, and ORIGIN is empty, INCOMPLETE will be set
		if ($nlri[7]  =~ /^(IGP|EGP|INCOMPLETE)$/)
		{
			if (($regex_filter{"ORIG"}) && ($nlri[7] !~ qr/$regex_filter{"ORIG"}/) )
			{
				sub_debug ("d", "Line [$.], Prefix [$prefix] skipped due to ORIG filter (value was: $nlri[7]).\n");
				next;
			} else
			{
				$origin = 2;
				$origin = 0 if ($nlri[7] eq "IGP");
				$origin = 1 if ($nlri[7] eq "EGP");
			}
		} elsif (($nlri[7]) && ($regex_filter{"ORIG"}))
		{
			sub_debug ("d", "Line [$.], Prefix [$prefix] skipped - doesnt contain valid ORIGIN value, but ORIG filter specified.\n");
			next;
		} else
		{
			sub_debug ("d", "Line [$.], Prefix [$prefix] - doesnt contain valid ORIGIN value, ORIGIN adjusted to INCOMPLETE.\n");
			$origin = 2;
		};
		
		my @agg;
		
		# Filter based on AGGREGATOR?
		if (($nlri[13]) && ($nlri[13] ne ""))
		{
			if ( ($regex_filter{"AGG"}) && ($nlri[13] !~ qr/$regex_filter{"AGG"}/) )
			{
				sub_debug ("d", "Line [$.], Prefix [$prefix] skipped due to AGG filter (value was: $nlri[13]).\n");
				next;
			} else
			{
				@agg = split / /,$nlri[13];
			}
		} elsif (!($nlri[13]) && ($regex_filter{"AGG"}))
		{
			sub_debug ("d", "Line [$.], Prefix [$prefix] skipped - doesnt contain valid AGGREGATOR value, but AGG filter specified.\n");
			next;
	 	};

		my $atomic_agg; 

		# Filter based on ATOMIC_AGGREGATE
		if (($nlri[12]) && ($nlri[12] ne ""))
		{
			if ( ($regex_filter{"ATOM"}) && ($nlri[12] !~ qr/$regex_filter{"ATOM"}/) )
			{
				sub_debug ("d", "Line [$.], Prefix [$prefix] skipped due to ATOM filter (value was: $nlri[12]).\n");
				next;
			} else
			{	
				$atomic_agg = ($nlri[12] eq "AG") ? 1 : 0;
			}
		} elsif  (!($nlri[12]) && ($regex_filter{"ATOM"}))
		{
			sub_debug ("d", "Line [$.], Prefix [$prefix] skipped - doesnt contain valid ATOMIC_AGGREGATE value, but ATOM filter specified.\n");
			next;
	 	};

#		sub_debug ("u", "Send Update: ") 			if (!$dry);
#		sub_debug ("u", "Generated Update (not sent): ") 	if ($dry);
#		sub_debug ("u", "prfx [$prefix] aspath [$aspath] ");
#		sub_debug ("u", "locprf [$local_pref] ") 		if ($peer_type eq "iBGP");
#		sub_debug ("u", "med [$med] ")				if ($med);
#		sub_debug ("u", "comm [@communities] ")			if (@communities);
#		sub_debug ("u", "orig [$nlri[7]] ");
#		sub_debug ("u", "agg [@agg] ")				if (@agg);
#		sub_debug ("u", "atom [$atomic_agg] ")			if ($atomic_agg);
#		sub_debug ("u", "nxthp [$nexthop]\n");

		if (! $dry)
		{
			my $update = Net::BGP::Update->new(
       				NLRI            => [ $prefix ],
       				AsPath          => $aspath,
       				NextHop         => $nexthop,
				Origin		=> $origin,
			);
			$update->communities([ @communities ])	if (@communities);
			$update->aggregator([ @agg ])		if (@agg);
			$update->atomic_aggregate("1") 		if ($atomic_agg);
			$update->med($med)			if ($med);
			$update->local_pref($local_pref) 	if ($peer_type eq "iBGP");
			
			$peer->update($update);
		}
		$cur += 1;
		last if (($prefix_limit) && ($cur > $prefix_limit));
	}	
	close (INPUT);


	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
               open (TIME,">>time");
                my $temp = $hour."\:".$min."\:".$sec."\n";

                print TIME $temp;
               # print "$hour\:$min\:$sec\n";
                close TIME;


}
                           
                           
                           
                           
                           
                           
                           
                           
