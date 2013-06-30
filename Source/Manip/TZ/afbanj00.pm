package #
Date::Manip::TZ::afbanj00;
# Copyright (c) 2008-2013 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Jun  3 12:53:03 EDT 2013
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
        [ [1,1,2,0,0,0],[1,1,1,22,53,24],'-01:06:36',[-1,-6,-36],
          'LMT',0,[1912,1,1,1,6,35],[1911,12,31,23,59,59],
          '0001010200:00:00','0001010122:53:24','1912010101:06:35','1911123123:59:59' ],
     ],
   1912 =>
     [
        [ [1912,1,1,1,6,36],[1912,1,1,0,0,0],'-01:06:36',[-1,-6,-36],
          'BMT',0,[1935,1,1,1,6,35],[1934,12,31,23,59,59],
          '1912010101:06:36','1912010100:00:00','1935010101:06:35','1934123123:59:59' ],
     ],
   1935 =>
     [
        [ [1935,1,1,1,6,36],[1935,1,1,0,6,36],'-01:00:00',[-1,0,0],
          'WAT',0,[1964,1,1,0,59,59],[1963,12,31,23,59,59],
          '1935010101:06:36','1935010100:06:36','1964010100:59:59','1963123123:59:59' ],
     ],
   1964 =>
     [
        [ [1964,1,1,1,0,0],[1964,1,1,1,0,0],'+00:00:00',[0,0,0],
          'GMT',0,[9999,12,31,0,0,0],[9999,12,31,0,0,0],
          '1964010101:00:00','1964010101:00:00','9999123100:00:00','9999123100:00:00' ],
     ],
);

%LastRule      = (
);

1;
