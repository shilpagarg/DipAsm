#!/usr/bin/python
import sys

assert len(sys.argv) == 3 and sys.argv[1][-2:] != 'gz'

mergedVCF = open(sys.argv[1], 'r').read().split('\n')[:-1]
sample = sys.argv[2]

for line in mergedVCF:
    if line[:2] == '##':
        sys.stdout.write(line + '\n')
        continue
    tokens = line.split('\t')
    if line[0] == '#' and line[1] != '#':
        if len(tokens) != 11:
            sys.stderr.write('Please intput a VCF with only two samples.\n')
            exit(1)
        tokens = line.split('\t')[:-2]
        sys.stdout.write('\t'.join(tokens)+'\t%s\n'%sample)
        continue
    sm1 = tokens[-2]
    sm2 = tokens[-1]
    gt1 = sm1.split(':')[0]
    gt2 = sm2.split(':')[0]
    if gt1 == '1/1' and gt2 == '0/0':
        #sys.stderr.write(line + '\t1|0\n')
        sys.stdout.write('\t'.join(tokens[:-3])+'\tGT\t1|0\n')
    elif gt1 == '1/1' and gt2 == './.':
        sys.stdout.write('\t'.join(tokens[:-3])+'\tGT\t1|0\n')
    elif gt1 == '0/0' and gt2 == '1/1':
        #sys.stderr.write(line + '\t0|1\n')
        sys.stdout.write('\t'.join(tokens[:-3])+'\tGT\t0|1\n')
    elif gt1 == './.' and gt2 == '1/1':
        sys.stdout.write('\t'.join(tokens[:-3])+'\tGT\t0|1\n')
    #else:
        #sys.stderr.write(line+'\tDONT WRITE\n')

