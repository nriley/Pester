package #
Date::Manip::Offset::off458;
# Copyright (c) 2008-2013 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'tzdata' is run.
#    Generated on: Mon Jun  3 12:55:41 EDT 2013
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

$Offset        = '-09:00:00';

%Offset        = (
   0 => [
      'america/yakutat',
      'pacific/gambier',
      'america/anchorage',
      'america/juneau',
      'america/nome',
      'america/sitka',
      'etc/gmt-9',
      'i',
      'america/dawson',
      'america/whitehorse',
      ],
   1 => [
      'america/adak',
      'america/anchorage',
      ],
);

1;
