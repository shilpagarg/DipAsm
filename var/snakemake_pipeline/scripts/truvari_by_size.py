import sys
from collections import Counter
import matplotlib.pyplot as plt
import numpy as np
import re

def read_variants(path, step_size_small = 50, step_size_large = 500):
    ins_counter = Counter()
    del_counter = Counter()
    rep_counter = Counter()
    open_file = open(path, "r")
    for line in open_file:
        if not line.startswith("#"):
            fields = line.strip().split("\t")
            ref_length = len(fields[3])
            alt_length = len(fields[4])
            match_len = re.search(r"SVLEN=(-?[0-9]+)", fields[7])
            if match_len:
                sv_len = int(match_len.group(1))
            else:
                sv_len = alt_length - ref_length
            match_rep = re.search(r"repClass=([A-Za-z_\\?,]+)", fields[7])
            if match_rep:
                repeat_classes = match_rep.group(1).split(",")
            else:
                repeat_classes = []
            if sv_len > 0:
                if sv_len >= 1000:
                    bucket_lower_bound = sv_len // step_size_large * step_size_large #round down to next step_size_large
                    bucket_name = "[{0},{1})".format(bucket_lower_bound, bucket_lower_bound + step_size_large)
                    ins_counter[bucket_name] += 1
                else:
                    bucket_lower_bound = sv_len // step_size_small * step_size_small #round down to next step_size_small
                    bucket_name = "[{0},{1})".format(bucket_lower_bound, bucket_lower_bound + step_size_small)
                    ins_counter[bucket_name] += 1
            if sv_len < 0:
                abs_sv_len = abs(sv_len)
                if abs_sv_len >= 1000:
                    bucket_lower_bound = abs_sv_len // step_size_large * step_size_large #round down to next step_size_large
                    bucket_name = "[{0},{1})".format(bucket_lower_bound, bucket_lower_bound + step_size_large)
                    del_counter[bucket_name] += 1
                else:
                    bucket_lower_bound = abs_sv_len // step_size_small * step_size_small #round down to next step_size_small
                    bucket_name = "[{0},{1})".format(bucket_lower_bound, bucket_lower_bound + step_size_small)
                    del_counter[bucket_name] += 1
            if len(repeat_classes) == 0:
                rep_counter["no_repeat"] += 1
            else:
                for cl in repeat_classes:
                    rep_counter[cl] += 1
    open_file.close()
    return (del_counter, ins_counter, rep_counter)


def plot_length(ax, xs, precs, recs):
    ax.plot(xs, precs, label='Precision')
    ax.plot(xs, recs, label='Recall')
    ax.set_xlabel('SV size')
    ax.set_ylabel('Performance')

    ax.set_title("Precision and Recall over SV size")
    ax.set_xlim(-10001, 10001)
    ax.set_ylim(0.0, 1.1)
    ax.axvline(x=0)
    ax.grid()
    ax.legend()


def plot_group_fraction_per_rep(ax, keys_union, counts):
    for group in counts.keys():
        sum_counts = sum(counts[group])
        fractions = [count / sum_counts for count in counts[group]]
        ax.scatter(keys_union, fractions, label=group)
    for tick in ax.get_xticklabels():
        tick.set_rotation(45)
    ax.legend()

def plot_rep(ax, keys_union, counts):
    col_labels = list(counts.keys())
    counts_array = np.array(list(counts.values()))
    counts_array_sums = np.sum(counts_array, axis=0)
    sort_order = counts_array_sums.argsort()[::-1]
    counts_array_sorted = np.take(counts_array, sort_order, axis=1)
    row_labels = [keys_union[i] for i in sort_order]
    transposed_counts_array = counts_array_sorted.T
    transposed_counts_array_cum = transposed_counts_array.cumsum(axis=1)
    category_colors = plt.get_cmap('RdYlGn')(
        np.linspace(0.15, 0.85, transposed_counts_array.shape[1]))

    ax.invert_yaxis()
    ax.xaxis.set_visible(False)
    ax.set_xlim(0, np.sum(transposed_counts_array, axis=1).max())

    for i, (colname, color) in enumerate(zip(col_labels, category_colors)):
        widths = transposed_counts_array[:, i]
        starts = transposed_counts_array_cum[:, i] - widths
        ax.barh(row_labels, widths, left=starts, height=0.8,
                label=colname, color=color)
        xcenters = starts + widths / 2

        r, g, b, _ = color
        text_color = 'white' if r * g * b < 0.5 else 'darkgrey'
        for y, (x, c) in enumerate(zip(xcenters, widths)):
            ax.text(x, y, str(int(c)), ha='center', va='center',
                    color=text_color)
    ax.legend(ncol=len(col_labels), bbox_to_anchor=(0, 1),
              loc='lower left', fontsize='small')


def main():
    truvari_dir = sys.argv[1]
    tpcall_path = truvari_dir + "/tp-call.annotated.vcf"
    tpbase_path = truvari_dir + "/tp-base.annotated.vcf"
    fp_path = truvari_dir + "/fp.annotated.vcf"
    fn_path = truvari_dir + "/fn.annotated.vcf"
    outsidecall_path = truvari_dir + "_outside/outside-call.annotated.vcf"
    outsidebase_path = truvari_dir + "_outside/outside-base.annotated.vcf"

    step_size_small = 100
    step_size_large = 500
    tp_call_dels, tp_call_ins, tp_call_reps = read_variants(tpcall_path, step_size_small, step_size_large)
    tp_base_dels, tp_base_ins, tp_base_reps = read_variants(tpbase_path, step_size_small, step_size_large)
    fp_dels, fp_ins, fp_reps = read_variants(fp_path, step_size_small, step_size_large)
    fn_dels, fn_ins, fn_reps = read_variants(fn_path, step_size_small, step_size_large)
    outsidecall_dels, outsidecall_ins, outsidecall_reps = read_variants(outsidecall_path, step_size_small, step_size_large)
    outsidebase_dels, outsidebase_ins, outsidebase_reps = read_variants(outsidebase_path, step_size_small, step_size_large)


    buckets = ["[{0},{1})".format(i, i + step_size_small) for i in range(0, 1000, step_size_small)] + \
              ["[{0},{1})".format(i, i + step_size_large) for i in range(1000, 10000, step_size_large)]

    print("DELETIONS")
    xs = []
    precs = []
    recs = []
    print("prec\trec\trange\tTP_call\tTP_base\tFP\tFN")
    for b in reversed(buckets):
        if fp_dels[b] + tp_call_dels[b] > 3:
            prec = round(tp_call_dels[b] / (fp_dels[b] + tp_call_dels[b]), 2)
        else:
            prec = None
        if fn_dels[b] + tp_base_dels[b] > 3:
            rec = round(tp_base_dels[b] / (fn_dels[b] + tp_base_dels[b]), 2)
        else:
            rec = None
        limits = b[1:-1].split(",")
        xs.append((int(limits[1]) + int(limits[0])) / -2)
        precs.append(prec)
        recs.append(rec)
        print("{0}\t{1}\t{2}\t{3}\t{4}\t{5}\t{6}".format(prec, rec, b, tp_call_dels[b], tp_base_dels[b], fp_dels[b], fn_dels[b]))

    print("INSERTIONS")
    for b in buckets:
        if fp_ins[b] + tp_call_ins[b] > 3:
            prec = round(tp_call_ins[b] / (fp_ins[b] + tp_call_ins[b]), 2)
        else:
            prec = None
        if fn_ins[b] + tp_base_ins[b] > 3:
            rec = round(tp_base_ins[b] / (fn_ins[b] + tp_base_ins[b]), 2)
        else:
            rec = None
        limits = b[1:-1].split(",")
        xs.append((int(limits[1]) + int(limits[0])) / 2)
        precs.append(prec)
        recs.append(rec)
        print("{0}\t{1}\t{2}\t{3}\t{4}\t{5}\t{6}".format(prec, rec, b, tp_call_ins[b], tp_base_ins[b], fp_ins[b], fn_ins[b]))

    print("REPATS")
    keys_union = list(set(list(tp_call_reps.keys()) + list(tp_base_reps.keys()) + list(fp_reps.keys()) + list(fn_reps.keys()) + list(outsidecall_reps.keys()) + list(outsidebase_reps.keys())))
    counts_calls = {
    "TP-call": [tp_call_reps[key] for key in keys_union],
    "FP": [fp_reps[key] for key in keys_union],
    "Outside-call": [outsidecall_reps[key] for key in keys_union]
    }

    print("\t" + "\t".join(counts_calls.keys()))
    for i, key in enumerate(keys_union):
        print("{0}:\t{1}".format(key, "\t".join([str(counts_calls[k][i]) for k in counts_calls.keys()])))

    counts_base = {
    "TP-base": [tp_base_reps[key] for key in keys_union],
    "FN": [fn_reps[key] for key in keys_union],
    "Outside-base": [outsidebase_reps[key] for key in keys_union]
    }

    print("\t" + "\t".join(counts_base.keys()))
    for i, key in enumerate(keys_union):
        print("{0}:\t{1}".format(key, "\t".join([str(counts_base[k][i]) for k in counts_base.keys()])))

    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(10,15))
    plot_length(ax1, xs, precs, recs)
    plot_rep(ax2, keys_union, counts_calls)
    plot_rep(ax3, keys_union, counts_base)

    output_path = sys.argv[2]
    fig.suptitle(truvari_dir)
    fig.savefig(output_path)
    fig.clf()

if __name__ == "__main__":
    sys.exit(main())
