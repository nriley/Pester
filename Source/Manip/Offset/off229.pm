package #
Date::Manip::Offset::off229;
# Copyright (c) 2008-2013 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Jun  3 12:55:40 EDT 2013
#    Data version: tzdata2013c
#    Code version: tzcode2013c

# This module contains data from the zoneinfo time zone database.  The original
# data was obtained from the URL:
#    ftp://ftp.iana.orgtz

use strict;
use warnings;
require 5.010000;

our ($VERSION);
$VERSION='6.40';
END { undef $VERSION; }

our ($Offset,%Offset);
END {
   undef $Offset;
   undef %Offset;
}

$Offset        = '+11:00:00';

%Offset        = (
   0 => [
      'pacific/pohnpei',
      'pacific/kosrae',
      'pacific/efate',
      'pacific/guadalcanal',
      'pacific/noumea',
      'asia/sakhalin',
      'asia/vladivostok',
      'asia/kamchatka',
      'asia/magadan',
      'asia/anadyr',
      'etc/gmt+11',
      'x',
      'antarctica/macquarie',
      'pacific/kwajalein',
      'pacific/majuro',
      'antarctica/casey',
      'asia/ust-nera',
      'asia/khandyga',
      ],
   1 => [
      'australia/melbourne',
      'australia/currie',
      'australia/hobart',
      'australia/sydney',
      'asia/vladivostok',
      'asia/sakhalin',
      'australia/lord_howe',
      'australia/lindeman',
      'australia/brisbane',
      'asia/magadan',
      'antarctica/macquarie',
      'asia/khandyga',
      'asia/ust-nera',
      ],
);

1;
