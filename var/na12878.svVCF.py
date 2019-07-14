import sys, argparse

header_to_add = '''##CL="%s"
##ALT=<ID=DEL,Description="Deletion">
##ALT=<ID=INS,Description="Insertion">
##INFO=<ID=SVTYPE,Number=1,Type=String,Description="Type of structural variant">
##INFO=<ID=SVLEN,Number=1,Type=Integer,Description="Length of the SV">
##INFO=<ID=END,Number=1,Type=Integer,Description="End position of the structural variant">'''%(' '.join(sys.argv))

def reheader(header):
	new_header = []
	for line in header:
		if '##ALT' in line or '##INFO' in line:
			continue
		if '#CHROM' in line:
			break
		new_header.append(line)
	new_header.extend(header_to_add.split('\n'))
	new_header.append(line)
	return '\n'.join(new_header)

def convertRecord(line, min_length, remove):
	tokens = line.split('\t')
	REF = tokens[3]
	ALT = tokens[4]
	if len(REF) == 1 and len(ALT) > 1:
		tokens[3] = 'N'
		#tokens[4] = '<INS>'
		SVLEN = len(ALT) - 1
		if SVLEN < min_length:
			return None
		END = int(tokens[1]) + SVLEN
		INFO = 'SVTYPE=INS;SVLEN=%d;END=%d'%(SVLEN,END)
		tokens[7] = INFO
	elif len(REF) > 1 and len(ALT) == 1:
		#tokens[3] = 'N'
		tokens[4] = 'N'
		SVLEN = len(REF) - 1
		if SVLEN < min_length:
			return None
		END = int(tokens[1]) + SVLEN
		INFO = 'SVTYPE=DEL;SVLEN=-%d;END=%d'%(SVLEN,END)
		tokens[7] = INFO
	else:
		if remove:
			return None
	tokens[6] = 'PASS'
	line = '\t'.join(tokens)
	return line

def convertVCF(vcf, min_length, remove):
	with open(vcf, 'r') as file:
		vcflines = file.readlines()
		header = []
		inHeader = True
		for line in vcflines:
			line = line.rstrip()
			if line[0] == '#':
				header.append(line)
			else:
				if inHeader:
					new_header = reheader(header)
					print(new_header)
					inHeader = False
				new_line = convertRecord(line, min_length, remove)
				if new_line:
					print(new_line)


if __name__ == '__main__':
	desc = 'Convert normal variant call file to the format that decode structural variants.'
	parser = argparse.ArgumentParser(description = desc)
	parser.add_argument('vcf', metavar = 'VCF', type = str,
	                	 help = 'VCF input')
	parser.add_argument('-m', '--min-length', metavar = 'INT', type = int, default = 20,
		                help = 'Filter for minimum length of INS and DEL')
	parser.add_argument('-r', '--remove-snvs', action="store_true", 
		                help = 'Only out put SVs.')
	args = parser.parse_args()
	convertVCF(args.vcf, args.min_length, args.remove_snvs)

