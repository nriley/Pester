package #
Date::Manip::TZ::atst_h00;
# Copyright (c) 2008-2013 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Jun  3 12:53:06 EDT 2013
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
        [ [1,1,2,0,0,0],[1,1,1,23,37,12],'-00:22:48',[0,-22,-48],
          'LMT',0,[1890,1,1,0,22,47],[1889,12,31,23,59,59],
          '0001010200:00:00','0001010123:37:12','1890010100:22:47','1889123123:59:59' ],
     ],
   1890 =>
     [
        [ [1890,1,1,0,22,48],[1890,1,1,0,0,0],'-00:22:48',[0,-22,-48],
          'JMT',0,[1951,1,1,0,22,47],[1950,12,31,23,59,59],
          '1890010100:22:48','1890010100:00:00','1951010100:22:47','1950123123:59:59' ],
     ],
   1951 =>
     [
        [ [1951,1,1,0,22,48],[1951,1,1,0,22,48],'+00:00:00',[0,0,0],
          'GMT',0,[9999,12,31,0,0,0],[9999,12,31,0,0,0],
          '1951010100:22:48','1951010100:22:48','9999123100:00:00','9999123100:00:00' ],
     ],
);

%LastRule      = (
);

1;
