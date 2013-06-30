package #
Date::Manip::TZ::afsao_00;
# Copyright (c) 2008-2013 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Jun  3 12:52:59 EDT 2013
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
        [ [1,1,2,0,0,0],[1,1,2,0,26,56],'+00:26:56',[0,26,56],
          'LMT',0,[1883,12,31,23,33,3],[1883,12,31,23,59,59],
          '0001010200:00:00','0001010200:26:56','1883123123:33:03','1883123123:59:59' ],
     ],
   1883 =>
     [
        [ [1883,12,31,23,33,4],[1883,12,31,22,56,32],'-00:36:32',[0,-36,-32],
          'LMT',0,[1912,1,1,0,36,31],[1911,12,31,23,59,59],
          '1883123123:33:04','1883123122:56:32','1912010100:36:31','1911123123:59:59' ],
     ],
   1912 =>
     [
        [ [1912,1,1,0,36,32],[1912,1,1,0,36,32],'+00:00:00',[0,0,0],
          'GMT',0,[9999,12,31,0,0,0],[9999,12,31,0,0,0],
          '1912010100:36:32','1912010100:36:32','9999123100:00:00','9999123100:00:00' ],
     ],
);

%LastRule      = (
);

1;
