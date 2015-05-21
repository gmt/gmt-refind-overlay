gmt-refind-overlay
==================

Portage overlay with ebuilds for whatever the TianoCore EFI
software development framework happens to be calling itself this
year and rEFInd boot manager.

Some of this code was inspired by alkan6's "gentoo" repo on github,
and from various folks' contributions to Gentoo bug #435960.

It should be safe to treat the ebuilds as GPLv2.

Feel free to blame me if it bricks your motherboard or formats
your hard-drive; you could also blame the Tooth Fairy, Pat Morita
or Margaret Thatcher.  Entirely your choice, but please choose
from only those four potential culprits.

To add this overlay to a Gentoo system, install layman
and run the following command as root:

```bash
wget https://raw.github.com/gmt/gmt-refind-overlay/master/gmt-refind.xml -O /etc/layman/overlays/gmt-refind.xml
layman -a gmt-refind
```

(note: I have not tested the above recipe for a while, pull
requests appreciated)

GL!

P.S.:
