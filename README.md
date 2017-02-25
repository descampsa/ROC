This is a simple bash script to draw ROC and Precision-Recall curves for binary classifiers, using gnuplot.
It takes test file(s) with binary ground truth and classification score as input. See comment for the exact format.
The test.txt file contains an example for a random classifier.

Simply call the script like that:

	./roc.sh test.txt

roc.svg and pr.svg images are generated, with ROC and Precision-Recall graphs.

Feel free to use and adapt to your needs.
