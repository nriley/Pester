package #
Date::Manip::Offset::off255;
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

$Offset        = '+13:00:00';

%Offset        = (
   0 => [
      'asia/anadyr',
      'pacific/enderbury',
      'pacific/tongatapu',
      'pacific/apia',
      'pacific/fakaofo',
      ],
   1 => [
      'pacific/auckland',
      'pacific/fiji',
      'antarctica/mcmurdo',
      'asia/kamchatka',
      'asia/anadyr',
      ],
);

1;
