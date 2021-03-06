#!/bin/bash

# Draw ROC and precision recall curves for binary classifiers
# Usage : ./roc.sh <input_file1> <input_file2> ...
# The input files contain gt value (0 or 1) and classifier score (float value)
# of a dataset, one sample per line and separated by space or tab.
# Any line with its first field different than '0' or '1' is ignored
#
# Example of input file :
#
# 1 0.8
# 1 0.5
# 0 0.1
# 0 0.4
# 1 1.2
# 0 0.6
# 1 0.7
#
# Output curves will be generate in roc.svg and pr.svg
# The curve name in legend will be the input file basenames, without extension


set -u
set -e

tmp_dir=$(mktemp -d)

roc_plot=""
pr_plot=""
for input_file in "$@"
do
	tmp_file="$tmp_dir/$(basename $input_file)"
	LC_ALL=C sort -k 2 -g $input_file | awk '
	BEGIN{
		N=0
		P=0
		print -1000000, 0, 0
	}
	{
		if($1=="0")
		{
			N+=1
		}
		else if($1=="1")
		{
			P+=1
		}
		print $2, N, P
	}' > $tmp_file

	N=$(tail -n 1 $tmp_file | awk '{print $2}')
	P=$(tail -n 1 $tmp_file | awk '{print $3}')

	title=$(basename  $input_file)
	title="${title%.*}"

	echo $title
	awk -v P=$P -v N=$N '
		BEGIN{best_accuracy=0} 
		{
			TN=$2;
			FN=$3;
			TP=P-FN;
			FP=N-TN;
			accuracy=(TN+TP)/(N+P);
			TPR=(TP/P)
			FPR=(FP/N)
			if(accuracy>best_accuracy)
			{
				best_accuracy=accuracy;
				best_accuracy_score=$1;
				best_TPR=TPR;
				best_FPR=FPR;
			}
		}
		END{
			print "Best accuracy :", best_accuracy, "(TPR =", best_TPR, ", FPR =", best_FPR, ") for score threshold", best_accuracy_score;
		}' $tmp_file

	roc_plot="$roc_plot '"$tmp_file"' using (($N-\$2)/$N):(($P-\$3)/$P) title \"$title\" with lines,"
	pr_plot="$pr_plot '"$tmp_file"' using (($P-\$3)/$P):(($P-\$3)/($P-\$3+$N-\$2)) title \"$title\" with lines,"
done

#remove last comma
roc_plot=${roc_plot%?}
pr_plot=${pr_plot%?}

gnuplot <<-EOF
	set terminal svg enhanced background rgb 'white' size 1000 1000 fsize 20
	set title "ROC curve"
	set xtics 0.1
	set ytics 0.1
	set grid 
	set key right bottom box
	set xlabel("False Positive Rate")
	set ylabel("True Positive Rate")
	set xrange [0:1]
	set yrange [0:1]
	set output 'roc.svg'
	plot $roc_plot
EOF

gnuplot <<-EOF
	set terminal svg enhanced background rgb 'white' size 1000 1000 fsize 20
	set title "Precision-Recall curve"
	set xtics 0.1
	set ytics 0.1
	set grid
	set key right bottom box
	set xlabel("Recall")
	set ylabel("Precision")
	set xrange [0:1]
	set yrange [0:1]
	set output 'pr.svg'
	plot $pr_plot
EOF

rm -r $tmp_dir
