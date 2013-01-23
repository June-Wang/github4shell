#!/usr/bin/perl -w 
############################## check_snmp_juniper6500.pl ##############
# Version : 0.1
# Date : Jan 28 2010
# Author : Christophe Sahut (christophe.sahut at sgs dot com)
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt
# Thanks to Patrick Proy for his work on nagios snmp plugins
#######################################################################
#
# Help : ./check_snmp_juniper6500.pl -h
#
# Example: ./check_snmp_juniper6500.pl -H myappliance -C mycommunity -T cpu -w 80 -c 90
#

use strict;
use Net::SNMP;
use Getopt::Long;
use Switch;

# Nagios specific
#use lib "/usr/local/nagios/libexec";
use lib "/usr/lib/nagios/plugins";
use utils qw(%ERRORS $TIMEOUT);
#my $TIMEOUT = 15;
#my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

# SNMP Datas
my $juniper_ive	= "1.3.6.1.4.1.12532.";
my $juniper_2_webusers		= $juniper_ive."2.0";
my $juniper_3_mailusers		= $juniper_ive."3.0";
my $juniper_9_concmeetingusers	= $juniper_ive."9.0";
my $juniper_10_cpu		= $juniper_ive."10.0";
my $juniper_11_memory		= $juniper_ive."11.0";
my $juniper_12_totalusersnode	= $juniper_ive."12.0";
my $juniper_13_totaluserscluster= $juniper_ive."13.0";
my $juniper_22_concmeetings	= $juniper_ive."22.0";
my $juniper_24_swap		= $juniper_ive."24.0";
my $juniper_25_disk		= $juniper_ive."25.0";

# Globals
my $Version='0.1';
my $o_host = 	undef; 		# hostname
my $o_community = undef; 	# community
my $o_port = 	161; 		# port
my $o_help=	undef; 		# wan't some help ?
my $o_verb=	undef;		# verbose mode
my $o_version=	undef;		# print version
my $o_type=	undef;		# Check cisco router mem
my $o_warn=	undef;		# warning level option
my $o_crit=	undef;		# Critical level option
my $o_perf=	undef;		# Performance data option
my $o_cache=	undef;		# Include cached memory as used memory
my $o_timeout=  undef; 		# Timeout (Default 5)
my $o_version2= undef;          # use snmp v2c
# SNMPv3 specific
my $o_login=	undef;		# Login for snmpv3
my $o_passwd=	undef;		# Pass for snmpv3
my $v3protocols=undef;	# V3 protocol list.
my $o_authproto='md5';		# Auth protocol
my $o_privproto='des';		# Priv protocol
my $o_privpass= undef;		# priv password

# functions

sub p_version { print "check_snmp_juniper6500 version : $Version\n"; }

sub print_usage {
    print "Usage: $0 [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>|<privp>])  [-p <port>] -T [cpu|memory|swap|disk|clusterusers|nodeusers|meetings|meetingusers|webusers|mailusers] -w <warn level> -c <crit level> [-f] [-m] [-t <timeout>] [-V]\n";
}

sub isnnum { # Return true if arg is not a number
  my $num = shift;
  if ( $num =~ /^(\d+\.?\d*)|(^\.\d+)$/ ) { return 0 ;}
  return 1;
}

sub round ($$) {
    sprintf "%.$_[1]f", $_[0];
}

sub help {
   print "\nSNMP Juniper 6500 Monitor for Nagios version ",$Version,"\n";
   print "(c)2010 Author: Christophe Sahut\n\n";
   print_usage();
   print <<EOT;
-v, --verbose
   print extra debugging information (including interface list on the system)
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies SNMP v1 or v2c with option)
-2, --v2c
   Use snmp v2c
-l, --login=LOGIN ; -x, --passwd=PASSWD
   Login and auth password for snmpv3 authentication 
   If no priv password exists, implies AuthNoPriv 
-X, --privpass=PASSWD
   Priv password for snmpv3 (AuthPriv protocol)
-L, --protocols=<authproto>,<privproto>
   <authproto> : Authentication protocol (md5|sha : default md5)
   <privproto> : Priv protocole (des|aes : default des) 
-P, --port=PORT
   SNMP port (Default 161)
-T,  --type
   Choose what you want: cpu,memory,swap,disk,clusterusers,nodeusers,meetings,meetingusers,webusers,mailusers
-w, --warn=INTEGER
   warning level
   Units: percentage for cpu,memory,swap,disk, no unit for others
-c, --crit=INTEGER
   critical level
   Units: percentage for cpu,memory,swap,disk, no unit for others
-f, --perfdata
   Performance data output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
EOT
}

# For verbose output
sub verb { my $t=shift; print $t,"\n" if defined($o_verb) ; }

# Get the alarm signal (just in case snmp timout screws up)
$SIG{'ALRM'} = sub {
     print ("ERROR: Alarm signal (Nagios time-out)\n");
     exit $ERRORS{"UNKNOWN"};
};

sub check_options {
    Getopt::Long::Configure ("bundling");
	GetOptions(
   	'v'	=> \$o_verb,		'verbose'	=> \$o_verb,
        'h'     => \$o_help,    	'help'        	=> \$o_help,
        'H:s'   => \$o_host,		'hostname:s'	=> \$o_host,
        'p:i'   => \$o_port,   		'port:i'	=> \$o_port,
        'C:s'   => \$o_community,	'community:s'	=> \$o_community,
	'l:s'	=> \$o_login,		'login:s'	=> \$o_login,
	'x:s'	=> \$o_passwd,		'passwd:s'	=> \$o_passwd,
	'X:s'	=> \$o_privpass,		'privpass:s'	=> \$o_privpass,
	'L:s'	=> \$v3protocols,		'protocols:s'	=> \$v3protocols,   
	't:i'   => \$o_timeout,       	'timeout:i'     => \$o_timeout,
	'V'	=> \$o_version,		'version'	=> \$o_version,
	'T:s'	=> \$o_type,		'type:s'	=> \$o_type,   
        '2'     => \$o_version2,        'v2c'           => \$o_version2,
        'c:s'   => \$o_crit,            'critical:s'    => \$o_crit,
        'w:s'   => \$o_warn,            'warn:s'        => \$o_warn,
        'm'   	=> \$o_cache,           'memcache'      => \$o_cache,
        'f'     => \$o_perf,            'perfdata'      => \$o_perf
    );
    if (defined ($o_help) ) { help(); exit $ERRORS{"UNKNOWN"}};
    if (defined($o_version)) { p_version(); exit $ERRORS{"UNKNOWN"}};
    if ( ! defined($o_host) ) # check host and filter 
	{ print "No host defined!\n";print_usage(); exit $ERRORS{"UNKNOWN"}}
    # check snmp information
    if ( !defined($o_community) && (!defined($o_login) || !defined($o_passwd)) )
	  { print "Put snmp login info!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	if ((defined($o_login) || defined($o_passwd)) && (defined($o_community) || defined($o_version2)) )
	  { print "Can't mix snmp v1,2c,3 protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	if (defined ($v3protocols)) {
	  if (!defined($o_login)) { print "Put snmp V3 login info with protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	  my @v3proto=split(/,/,$v3protocols);
	  if ((defined ($v3proto[0])) && ($v3proto[0] ne "")) {$o_authproto=$v3proto[0];	}	# Auth protocol
	  if (defined ($v3proto[1])) {$o_privproto=$v3proto[1];	}	# Priv  protocol
	  if ((defined ($v3proto[1])) && (!defined($o_privpass))) {
	    print "Put snmp V3 priv login info with priv protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	}
	if (defined($o_timeout) && (isnnum($o_timeout) || ($o_timeout < 2) || ($o_timeout > 60))) 
	  { print "Timeout must be >1 and <60 !\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	if (!defined($o_timeout)) {$o_timeout=5;}
	#Check Warning and crit are present
    if ( ! defined($o_warn) || ! defined($o_crit))
 	{ print "Put warning and critical values!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    # Get rid of % sign
    $o_warn =~ s/\%//g; 
    $o_crit =~ s/\%//g;
    if (defined($o_type)) {
      if ( isnnum($o_warn) || isnnum($o_crit)) 
	{ print "Numeric value for warning or critical !\n";print_usage(); exit $ERRORS{"UNKNOWN"} }
      if ( ($o_crit != 0) && ($o_warn > $o_crit) ) 
        { print "warning <= critical ! \n";print_usage(); exit $ERRORS{"UNKNOWN"}}
      } 
      else {
	print "Define a type !\n";
	exit $ERRORS{"UNKNOWN"};
      }
}

########## MAIN #######

check_options();

# Check gobal timeout if snmp screws up
if (defined($TIMEOUT)) {
  verb("Alarm at $TIMEOUT");
  alarm($TIMEOUT);
} else {
  verb("no timeout defined : $o_timeout + 10");
  alarm ($o_timeout+10);
}

# Connect to host
my ($session,$error);
if ( defined($o_login) && defined($o_passwd)) {
  # SNMPv3 login
  if (!defined ($o_privpass)) {
  verb("SNMPv3 AuthNoPriv login : $o_login, $o_authproto");
    ($session, $error) = Net::SNMP->session(
      -hostname   	=> $o_host,
      -version		=> '3',
      -username		=> $o_login,
      -authpassword	=> $o_passwd,
      -authprotocol	=> $o_authproto,
      -timeout          => $o_timeout
    );  
  } else {
    verb("SNMPv3 AuthPriv login : $o_login, $o_authproto, $o_privproto");
    ($session, $error) = Net::SNMP->session(
      -hostname   	=> $o_host,
      -version		=> '3',
      -username		=> $o_login,
      -authpassword	=> $o_passwd,
      -authprotocol	=> $o_authproto,
      -privpassword	=> $o_privpass,
	  -privprotocol => $o_privproto,
      -timeout      => $o_timeout
    );
  }
} else {
   if (defined ($o_version2)) {
     # SNMPv2 Login
	 verb("SNMP v2c login");
	 ($session, $error) = Net::SNMP->session(
	-hostname  => $o_host,
	    -version   => 2,
	-community => $o_community,
	-port      => $o_port,
	-timeout   => $o_timeout
     );
   } else {
    # SNMPV1 login
	verb("SNMP v1 login");
    ($session, $error) = Net::SNMP->session(
       -hostname  => $o_host,
       -community => $o_community,
       -port      => $o_port,
       -timeout   => $o_timeout
    );
  }
}
if (!defined($session)) {
   printf("ERROR opening session: %s.\n", $error);
   exit $ERRORS{"UNKNOWN"};
}

# Global variable
my $result=undef;
my $result_value=undef;
my $c_status=undef;
my $c_output = undef;
my @oid = ();
my $unit="";

switch ($o_type) {

	case "cpu" {
		@oid=($juniper_10_cpu);
		$c_output = "Juniper CPU";
		$unit = "%";
	}
	case "memory" {
		@oid=($juniper_11_memory);
		$c_output = "Juniper Memory usage";
		$unit = "%";
	}
	case "swap" {
		@oid=($juniper_24_swap);
		$c_output = "Juniper Swap usage";
		$unit = "%";
	}
	case "disk" {
		@oid=($juniper_25_disk);
		$c_output = "Juniper Disk usage";
		$unit = "%";
	}
	case "clusterusers" {
		@oid=($juniper_13_totaluserscluster);
		$c_output = "Juniper Cluster Logged Users";
	}
	case "nodeusers" {
		@oid=($juniper_12_totalusersnode);
		$c_output = "Juniper IVE Node Logged Users";
	}
	case "meetings" {
		@oid=($juniper_22_concmeetings);
		$c_output = "Juniper Concurrent Meetings number";
	}
	case "meetingusers" {
		@oid=($juniper_9_concmeetingusers);
		$c_output = "Juniper Concurrent Meetings Users";
	}
	case "webusers" {
		@oid=($juniper_2_webusers);
		$c_output = "Juniper Signed-In Web Users";
	}
	case "mailusers" {
		@oid=($juniper_3_mailusers);
		$c_output = "Juniper Signed-In Mail Users";
	}
	else {
		print "Type not found!\n";
	}
}

$result = (Net::SNMP->VERSION < 4) ?
    $session->get_request(@oid)
  : $session->get_request(varbindlist => \@oid);

if (!defined($result)) {
	printf("UNKNOWN : Value not given by the appliance: %s.\n", $session->error);
	$session->close;
	exit $ERRORS{"UNKNOWN"};
}

$result_value = $$result{$oid[0]};

if ($o_crit <= $result_value) {
	$c_status="CRITICAL";
	$c_output .= " ".$c_status." - ".$result_value.$unit." > ".$o_crit.$unit;
} 
elsif ($o_warn <= $result_value) {
	$c_status="WARNING";
	$c_output .= " ".$c_status." - ".$result_value.$unit." > ".$o_warn.$unit;
}
else{
	$c_status="OK";
	$c_output .= " ".$c_status." - ".$result_value.$unit;

}

if (defined ($o_perf)) {
	$c_output .= " | ".$o_type."=" . $result_value.";";
	$c_output .= ($o_warn ==0)? ";" : $o_warn.";"; 
	$c_output .= ($o_crit ==0)? ";" : $o_crit.";";
	$c_output .= "0;";
}             
$session->close; 
print "$c_output \n";
exit $ERRORS{$c_status};
