import sys
import argparse
import subprocess


parser = argparse.ArgumentParser()
parser.add_argument('--hic-path', metavar = 'PATH', type = str, required = True,
                     help = 'Use Hi-C data from this path. Should be named by *1.fastq and *2.fastq.')
parser.add_argument('--pb-path', metavar = 'PATH', type = str, required = True,
                     help = 'Use PacBioCCS data from this path. All fastq will be used.')
parser.add_argument('--sample', metavar = 'NAME', type = str, required = True,
                     help = 'Sample name to put for Read Group of BAM and Sample of VCF.')
parser.add_argument('--female', action = 'store_true',
                     help = 'When sample is a female, specify this to also do phasing on chrX.')
parser.add_argument('--prefix', metavar = 'STR', type = str, required = True,
                     help = 'Prefix name for the experiment, for example "refBased", "ragooBased".')
args = parser.parse_args()

if args.female:
    female = 'TRUE'
else:
    female = 'FALSE'
commands = [args.hic_path, args.pb_path, args.sample, female, args.prefix]
commands = './pipeline.sh ' + ' '.join(commands)
process = subprocess.Popen(commands, shell = True, stdout=subprocess.PIPE)
comm = process.communicate()
stdout = comm[0].decode()

#stderr = comm[1].decode()
#sys.stderr.write('STDERR:::\n')
#sys.stderr.write(stderr+'\n')

sys.stdout.write('STDOUT:::\n')
sys.stdout.write(stdout+'\n')
