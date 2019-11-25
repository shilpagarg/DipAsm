import sys
import argparse
import subprocess


parser = argparse.ArgumentParser()
parser.add_argument('--hic-path', metavar = 'PATH', type = str, required = True,
                     help = 'Use Hi-C data from this path. Should be named by *1.fastq and *2.fastq.')
parser.add_argument('--pb-path', metavar = 'PATH', type = str, required = True,
                     help = 'Use PacBioCCS data from this path. All fastq will be used.')
parser.add_argument('--scaffolds', metavar = 'FASTA', type = str, required = False,
                     help = 'The input reference scaffolds')
parser.add_argument('--ragoo', metavar = 'FASTA', type = str,
                     help = 'If specified, will use RaGOO to perform scaffolding on the input scaffolds. This will require another reference as input.')
parser.add_argument('--reference', metavar = 'FASTA', type = str, required = False,
                     help = 'The reference for RaGOO based scaffolding.')
parser.add_argument('--sample', metavar = 'NAME', type = str, required = True,
                     help = 'Sample name to put for Read Group of BAM and Sample of VCF.')
parser.add_argument('--female', action = 'store_true',
                     help = 'When sample is a female, specify this to also do phasing on chrX.')
parser.add_argument('--prefix', metavar = 'STR', type = str, required = True,
                     help = 'Prefix name for the experiment, for example "refBased", "ragooBased".')
args = parser.parse_args()

if args.ragoo:
    ragoo = args.ragoo
    if args.reference != None:
        ref = args.reference
    else:
        sys.stderr.write('When specified "--ragoo", should have reference input.\n')
        exit(1)
    scaffolds = 'FALSE'
else:
    if args.scaffolds != None:
        scaffolds = args.scaffolds
    else:
        sys.stderr.write('When "--ragoo" is not specified, should specify scaffolds.\n')
        exit(1)
    ragoo = 'FALSE'
    ref = 'FALSE'
if args.female:
    female = 'TRUE'
else:
    female = 'FALSE'
commands = [args.hic_path, args.pb_path, scaffolds, ragoo, ref, args.sample, female, args.prefix]
commands = './pipeline.sh ' + ' '.join(commands)
process = subprocess.Popen(commands, shell = True, stdout=subprocess.PIPE)
comm = process.communicate()
stdout = comm[0].decode()

#stderr = comm[1].decode()
#sys.stderr.write('STDERR:::\n')
#sys.stderr.write(stderr+'\n')

sys.stdout.write('STDOUT:::\n')
sys.stdout.write(stdout+'\n')
