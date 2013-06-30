package #
Date::Manip::TZ::amst_t00;
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
        [ [1,1,2,0,0,0],[1,1,1,19,40,16],'-04:19:44',[-4,-19,-44],
          'LMT',0,[1911,7,1,4,19,43],[1911,6,30,23,59,59],
          '0001010200:00:00','0001010119:40:16','1911070104:19:43','1911063023:59:59' ],
     ],
   1911 =>
     [
        [ [1911,7,1,4,19,44],[1911,7,1,0,19,44],'-04:00:00',[-4,0,0],
          'AST',0,[9999,12,31,0,0,0],[9999,12,30,20,0,0],
          '1911070104:19:44','1911070100:19:44','9999123100:00:00','9999123020:00:00' ],
     ],
);

%LastRule      = (
);

1;
