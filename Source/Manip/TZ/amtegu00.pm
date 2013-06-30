package #
Date::Manip::TZ::amtegu00;
# Copyright (c) 2008-2013 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Jun  3 12:53:13 EDT 2013
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
        [ [1,1,2,0,0,0],[1,1,1,18,11,8],'-05:48:52',[-5,-48,-52],
          'LMT',0,[1921,4,1,5,48,51],[1921,3,31,23,59,59],
          '0001010200:00:00','0001010118:11:08','1921040105:48:51','1921033123:59:59' ],
     ],
   1921 =>
     [
        [ [1921,4,1,5,48,52],[1921,3,31,23,48,52],'-06:00:00',[-6,0,0],
          'CST',0,[1987,5,3,5,59,59],[1987,5,2,23,59,59],
          '1921040105:48:52','1921033123:48:52','1987050305:59:59','1987050223:59:59' ],
     ],
   1987 =>
     [
        [ [1987,5,3,6,0,0],[1987,5,3,1,0,0],'-05:00:00',[-5,0,0],
          'CDT',1,[1987,9,27,4,59,59],[1987,9,26,23,59,59],
          '1987050306:00:00','1987050301:00:00','1987092704:59:59','1987092623:59:59' ],
        [ [1987,9,27,5,0,0],[1987,9,26,23,0,0],'-06:00:00',[-6,0,0],
          'CST',0,[1988,5,1,5,59,59],[1988,4,30,23,59,59],
          '1987092705:00:00','1987092623:00:00','1988050105:59:59','1988043023:59:59' ],
     ],
   1988 =>
     [
        [ [1988,5,1,6,0,0],[1988,5,1,1,0,0],'-05:00:00',[-5,0,0],
          'CDT',1,[1988,9,25,4,59,59],[1988,9,24,23,59,59],
          '1988050106:00:00','1988050101:00:00','1988092504:59:59','1988092423:59:59' ],
        [ [1988,9,25,5,0,0],[1988,9,24,23,0,0],'-06:00:00',[-6,0,0],
          'CST',0,[2006,5,7,5,59,59],[2006,5,6,23,59,59],
          '1988092505:00:00','1988092423:00:00','2006050705:59:59','2006050623:59:59' ],
     ],
   2006 =>
     [
        [ [2006,5,7,6,0,0],[2006,5,7,1,0,0],'-05:00:00',[-5,0,0],
          'CDT',1,[2006,8,7,4,59,59],[2006,8,6,23,59,59],
          '2006050706:00:00','2006050701:00:00','2006080704:59:59','2006080623:59:59' ],
        [ [2006,8,7,5,0,0],[2006,8,6,23,0,0],'-06:00:00',[-6,0,0],
          'CST',0,[9999,12,31,0,0,0],[9999,12,30,18,0,0],
          '2006080705:00:00','2006080623:00:00','9999123100:00:00','9999123018:00:00' ],
     ],
);

%LastRule      = (
);

1;