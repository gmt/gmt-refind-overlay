gmt-refind-overlay
==================

Portage overlay with the goodies (term perhaps loosely applied) needed
to build the rEFInd (U)EFI bootloader

Pretty sure some of this code was stolen from alkan6's "gentoo" repo,
also found here on github.  And/or maybe from Gentoo bug #435960...

Feel free to blame me when it bricks your motherboard, or, the Tooth
Fairy, or Pat Morita or Margaret Thatcher.  Entirely your choice,
so long as you pick only from those four...

Furthermore: only one percieved culprit is allowed at a time.  But you
can always change your mind later.

To add this overlay to a Gentoo system, install layman
and run the following command as root:

```bash
wget https://raw.github.com/gmt/gmt-refind-overlay/master/gmt-refind.xml -O /etc/layman/overlays/gmt-refind.xml
layman -a gmt-refind
```

GL!

gmt@be-evil.net

P.S.:
It should be safe to treat all these ebuilds as GPLv2. But IANAL etc.
