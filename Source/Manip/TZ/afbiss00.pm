package #
Date::Manip::TZ::afbiss00;
# Copyright (c) 2008-2014 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Fri Nov 21 10:41:36 EST 2014
#    Data version: tzdata2014j
#    Code version: tzcode2014j

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
$VERSION='6.48';
END { undef $VERSION; }

%Dates         = (
   1    =>
     [
        [ [1,1,2,0,0,0],[1,1,1,22,57,40],'-01:02:20',[-1,-2,-20],
          'LMT',0,[1912,1,1,1,2,19],[1911,12,31,23,59,59],
          '0001010200:00:00','0001010122:57:40','1912010101:02:19','1911123123:59:59' ],
     ],
   1912 =>
     [
        [ [1912,1,1,1,2,20],[1912,1,1,0,2,20],'-01:00:00',[-1,0,0],
          'WAT',0,[1975,1,1,0,59,59],[1974,12,31,23,59,59],
          '1912010101:02:20','1912010100:02:20','1975010100:59:59','1974123123:59:59' ],
     ],
   1975 =>
     [
        [ [1975,1,1,1,0,0],[1975,1,1,1,0,0],'+00:00:00',[0,0,0],
          'GMT',0,[9999,12,31,0,0,0],[9999,12,31,0,0,0],
          '1975010101:00:00','1975010101:00:00','9999123100:00:00','9999123100:00:00' ],
     ],
);

%LastRule      = (
);

1;
