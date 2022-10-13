#!/usr/bin/env python
from obspy import read_inventory
import sys,os

#sys.argv[1]: inv
#sys.argv[2]: #SEISCOMP_ROOT
#sys.argv[3]: module:profile
#sys.argv[4]: module:profile
#sys.argv[5]: module:profile
#...
def getprefchan(s,
                pref_chan = ['HH','EH','SH','HN','EN','SN','BH','LH']):
    for pc in pref_chan:
        for c in s:
            if c.code[:len(pc)] == pc:
                return c

profile = '%s/etc/key/global' % (sys.argv[2])
if not os.path.exists(profile):
    os.mkdir(profile)
    
profile = '%s/etc/key/scautopick' % (sys.argv[2])
if not os.path.exists(profile):
    os.mkdir(profile)

profile = '%s/etc/key/scautopick/profile_default' % (sys.argv[2])
if not os.path.exists(profile):
    with open(profile, 'w') as f:
        f.write('#Default scautopick profile enables picking on the related station')
            
inv = read_inventory(sys.argv[1])
for n in inv:
    for s in n:
        c=getprefchan(s)

        bound = (sys.argv[2],n.code,s.code)
        bound = '%s/etc/key/station_%s_%s' % bound
        with open(bound, 'w') as f:
            bound = (c.code,
                     c.location_code)
            f.write('global:%s_%s' % bound)
            f.write('scautopick:default')
            for bound in sys.argv[3:]:
                f.write(bound)
        
        profile = (sys.argv[2],c.code,c.location_code)
        profile = '%s/etc/key/global/profile_%s_%s' % profile
        if not os.path.exists(profile):
            with open(profile, 'w') as f:
                f.write('amplitudes.enableResponses = true')
                f.write('detecStream = %s'%(c.code))
                if len(c.location_code):
                    f.write('detecLocid = %s'(c.location_code))