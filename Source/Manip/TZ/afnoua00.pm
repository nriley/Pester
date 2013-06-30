package #
Date::Manip::TZ::afnoua00;
# Copyright (c) 2008-2013 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Jun  3 12:53:09 EDT 2013
#    Data version: tzdata2013c
#    Code version: tzcode2013c

# This module contains data from the zoneinfo time zone database.  The original
# data was obtained from the URL:
#    ftp://ftp.iana.org/tz

use strict;
use warnings;
require 5.010000;

our (%Dates,%LastRule);
END {
   undef %Dates;
   undef %LastRule;
}

our ($VERSION);
$VERSION='6.40';
END { undef $VERSION; }

%Dates         = (
   1    =>
     [
        [ [1,1,2,0,0,0],[1,1,1,22,56,12],'-01:03:48',[-1,-3,-48],
          'LMT',0,[1912,1,1,1,3,47],[1911,12,31,23,59,59],
          '0001010200:00:00','0001010122:56:12','1912010101:03:47','1911123123:59:59' ],
     ],
   1912 =>
     [
        [ [1912,1,1,1,3,48],[1912,1,1,1,3,48],'+00:00:00',[0,0,0],
          'GMT',0,[1934,2,25,23,59,59],[1934,2,25,23,59,59],
          '1912010101:03:48','1912010101:03:48','1934022523:59:59','1934022523:59:59' ],
     ],
   1934 =>
     [
        [ [1934,2,26,0,0,0],[1934,2,25,23,0,0],'-01:00:00',[-1,0,0],
          'WAT',0,[1960,11,28,0,59,59],[1960,11,27,23,59,59],
          '1934022600:00:00','1934022523:00:00','1960112800:59:59','1960112723:59:59' ],
     ],
   1960 =>
     [
        [ [1960,11,28,1,0,0],[1960,11,28,1,0,0],'+00:00:00',[0,0,0],
          'GMT',0,[9999,12,31,0,0,0],[9999,12,31,0,0,0],
          '1960112801:00:00','1960112801:00:00','9999123100:00:00','9999123100:00:00' ],
     ],
);

%LastRule      = (
);

1;
