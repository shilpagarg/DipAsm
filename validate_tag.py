## Usage: mkdir accuracies; parallel 'python validate_tag.py --read-lists accuracies/accu_{} --write-tsv accuracies/accu_{}.tsv na12878.pacbioccs.chr{}_RaGOO.tagged.bam truth/{}.bam' ::: {1..22}

from collections import defaultdict
import sys
import argparse
import pysam

def compute_accuracy(pred_hap1, pred_hap2, trueHap1, trueHap2, prefix, pred_read_hp, partitioned):
	predBlocks = list(pred_hap1.keys())
	truthBlocks = list(trueHap1.keys())
	successCount = 0
	correct_reads = []
	for k1 in predBlocks:
		for k2 in truthBlocks:
			successCount += max(len(list(set(pred_hap1[k1]).intersection(set(trueHap1[k2])))), len(list(set(pred_hap1[k1]).intersection(set(trueHap2[k2])))))
			successCount += max(len(list(set(pred_hap2[k1]).intersection(set(trueHap1[k2])))), len(list(set(pred_hap2[k1]).intersection(set(trueHap2[k2])))))
			if len(list(set(pred_hap1[k1]).intersection(set(trueHap1[k2])))) > len(list(set(pred_hap1[k1]).intersection(set(trueHap2[k2])))):
				correct_reads.extend(list(set(pred_hap1[k1]).intersection(set(trueHap1[k2]))))
			else:
				correct_reads.extend(list(set(pred_hap1[k1]).intersection(set(trueHap2[k2]))))
			if len(list(set(pred_hap2[k1]).intersection(set(trueHap1[k2])))) > len(list(set(pred_hap2[k1]).intersection(set(trueHap2[k2])))):
				correct_reads.extend(list(set(pred_hap2[k1]).intersection(set(trueHap1[k2]))))
			else:
				correct_reads.extend(list(set(pred_hap2[k1]).intersection(set(trueHap2[k2]))))
	wrong_reads = partitioned.difference(set(correct_reads))
	if prefix != None:
		oc = open('%s_correct.reads'%prefix, 'w')
		for i in set(correct_reads):
			oc.write(i + '\t' + str(pred_read_hp[i]) + '\n')
		oc.close()
		ow = open('%s_wrong.reads'%prefix, 'w')
		for i in wrong_reads:
			ow.write(i + '\t' + str(pred_read_hp[i]) + '\n')
		ow.close()

	return successCount

def getBamPartition(bam):
	pred1 = defaultdict(set)
	pred2 = defaultdict(set)
	read_hp = dict()
	allReadCount = 0
	partitioned = 0
	pred_all = set()
	for read in bam:
		try:
			block = read.get_tag('PS')
			HP = read.get_tag('HP')
			read_hp[read.query_name] = HP
			if HP == 1:
				pred1[block].add(read.query_name)
			elif HP == 2:
				pred2[block].add(read.query_name)
			partitioned += 1
			pred_all.add(read.query_name)
		except:
			pass
		allReadCount += 1
	#assert len(pred1) == len(pred2), 'Seems there are blocks with only one haplotype phased.'
	sys.stderr.write('Totally %d reads processed, found %d blocks, with %d reads tagged.\n' % (allReadCount, len(pred1), partitioned))
	if partitioned == 0:
		sys.stderr.write('No reads tagged, stopping..\n')
		exit()
	return pred1, pred2, pred_all, read_hp

def getReadNum(HP):
	n = 0
	for block, readset in HP.items():
		n += len(readset)
	return n

def writeTSV(predFile, truthFiles, pred1, pred2, truth1, truth2, isec, successCount, filename):
	o = open(filename, 'w')
	o.write('PredFile\tTruthFile\tPredHP1 #\tPredHP2 #\tTruthHP1 #\tTruthHP2 #\tIntersection %\tAccracy %\n')
	nPred1 = getReadNum(pred1)
	nPred2 = getReadNum(pred2)
	nTruth1 = getReadNum(truth1)
	nTruth2 = getReadNum(truth2)
	if len(truthFiles) == 1:
		truthFiles = truthFiles[0]
	else:
		truthFiles = str(truthFiles)
	isecPerc = len(isec) / (nTruth1 + nTruth2)
	accu = successCount / len(isec)
	o.write('\t'.join([predFile, truthFiles, str(nPred1), str(nPred2), str(nTruth1), str(nTruth2), '%.2f'%(isecPerc*100), '%.2f'%(accu*100)])+'\n')
	o.close()

if __name__ == '__main__':
	parser = argparse.ArgumentParser()
	parser.add_argument('taggedBAM', metavar = 'BAM', type = str,
	                	 help = 'Input haplotag bam')
	parser.add_argument('truth', metavar = 'truthINFO', type = str, nargs='+', 
	                 	help = 'Ground truth partitions. Should be one tagged BAM or two files for each haplotype where each line is a read name.')
	parser.add_argument('--read-lists', metavar = 'PREFIX', type = str, 
						help = 'write correctly/wrongly tagged read names into file PREFIX_correct.reads and PREFIX_wrong.reads.')
	parser.add_argument('--write-tsv', metavar = 'FILE', type = str,
		                help = 'write the calculation result into a TSV format table.')

	args = parser.parse_args()

	if len(args.truth) == 1:
		truthBam = pysam.AlignmentFile(args.truth[0], "rb")
		twolist = None
	elif len(args.truth) == 2:
		truthBam = None
		twolist = [open(args.truth[0], 'r').read().split('\n')[:-1], open(args.truth[0], 'r').read().split('\n')[:-1]]
		assert not set(twolist[0]).intersection(set(twolist[1])), 'Truth sets have none empty intersection.'
	else:
		print('Wrong input for ground truth')

	bam = pysam.AlignmentFile(args.taggedBAM, "rb")
	sys.stderr.write('Reading input BAM file...\n')
	pred1, pred2, pred_all, pred_read_hp = getBamPartition(bam)

	if truthBam:
		sys.stderr.write('Reading ground truth BAM file...\n')
		truth1, truth2, truth_all, truth_read_hp = getBamPartition(truthBam)

	elif twolist:
		sys.stderr.write('Reading ground truth lists...\n')
		truth1 = {1:set(twolist[0])}
		truth2 = {1:set(twolist[1])}
		truth_all = set(twolist[0]).union(set(twolist[1]))
		sys.stderr.write('truth1: %d, truth2: %d.\n' % (len(truth1[1]), len(truth2[1])))

	isec = pred_all.intersection(truth_all)
	sys.stderr.write('intersection between pred and truth: %d\n' % len(isec))
	if len(isec) == 0:
		sys.stderr.write('No read intersects. Stopping..\n')

	successCount = compute_accuracy(pred1, pred2, truth1, truth2, args.read_lists, pred_read_hp, pred_all)

	accu = successCount / len(isec)
	sys.stderr.write('accuracy within the intersection: %.5f\n' % accu)

	if args.write_tsv != None:
		sys.stderr.write('Writing result to %s ...\n' % args.write_tsv)
		writeTSV(args.taggedBAM, args.truth, pred1, pred2, truth1, truth2, isec, successCount, args.write_tsv)
