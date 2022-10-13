#!/usr/bin/env python
from obspy import read
import sys,os

data=read(sys.argv[1])

profile = '%s/etc/key/global' % (sys.argv[2])
if not os.path.exists(profile):
    print(profile)
    os.mkdir(profile)

profile = '%s/etc/key/scautopick' % (sys.argv[2])
if not os.path.exists(profile):
    print(profile)
    os.mkdir(profile)

profile = '%s/etc/key/scautopick/profile_default' % (sys.argv[2])
if not os.path.exists(profile):
    print(profile)
    with open(profile, 'w') as f:
        f.write('#Default scautopick profile enables picking on the related station')

def pref(chans,
         p=['HH','EH','SH','HN','HG','EN','SN','BH','LH']):
    for pc in p:
        for c in chans:
            if c[:len(pc)]==pc:
                return pc,c[3:]
        
nets = list(set([tr.stats.network for tr in data]))
for n in nets:
    stats = list(set([tr.stats.station for tr in data if tr.stats.network == n]))
    for s in stats:
        chans =  list(set([tr.stats.channel+'_'+tr.stats.location for tr in data if tr.stats.network == n and tr.stats.station]))
        c,l = pref(chans)
        n,s,c,l = map(str,(n,s,c,l))
        l=l.replace('_','')
        print(n,s,c,l)
        
        bound = (sys.argv[2],n,s)
        bound = '%s/etc/key/station_%s_%s' % bound
        with open(bound, 'w') as f:
            print(bound)
            bound = (c, l)
            f.write('global:%s_%s\n' % bound)
            f.write('scautopick:default')
            for bound in sys.argv[3:]:
                f.write('\n%s' % bound)

        profile = (sys.argv[2],c,l)
        profile = '%s/etc/key/global/profile_%s_%s' % profile
        if not os.path.exists(profile):
            with open(profile, 'w') as f:
                print(profile)
                f.write('amplitudes.enableResponses = true\n')
                f.write('detecStream = %s' % c)
                if len(l):
                    f.write('\ndetecLocid = %s' % l)