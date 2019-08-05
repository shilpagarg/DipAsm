#!/usr/bin/env k8

var min_var_len = 50000, min_mapq = 5;

if (arguments.length == 0) {
	warn("Usage: k8 sam-flt.js <in.sam.gz>");
	exit(1);
}

var re = /(\d+)([MIDSH])/g;
var file = new File(arguments[0]);
var buf = new Bytes();

while (file.readline(buf) >= 0) {
	var line = buf.toString();
	if (line.charAt(0) == '@') print(line);
	var m, t = line.split("\t", 6);
	var flag = parseInt(t[1]);
	if (flag & 0x100) continue;
	if (parseInt(t[4]) < min_mapq) continue;
	var blen = 0;
	while ((m = re.exec(t[5])) != null)
		if (m[2] == 'M' || m[2] == 'I' || m[2] == 'D')
			blen += parseInt(m[1]);
	if (blen < min_var_len) continue;
	print(line);
}

buf.destroy();
file.close();
