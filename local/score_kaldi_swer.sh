#!/usr/bin/env bash
# Copyright 2012-2014  Johns Hopkins University (Author: Daniel Povey, Yenda Trmal)
# Copyright 2022 Kavya Manohar (Adaptation of wsj/steps/scoring/score_kaldi_wer.sh and 
# wsj/steps/scoring/score_kaldi_cer.sh for subword level transcriptions)
# Apache 2.0

# if you need to compute both the WER and CER, you can use the stage parameters
# i.e. write your own local/score.sh that will contain

# steps/scoring/score_kaldi_wer.sh "$@"
# steps/scoring/score_kaldi_cer.sh --stage 2 "@"
# local/score_kaldi_swer.sh "$@"

[ -f ./path.sh ] && . ./path.sh

# begin configuration section.
cmd=run.pl
stage=0
decode_mbr=false
stats=true
beam=6
word_ins_penalty=0.0,0.5,1.0
min_lmwt=7
max_lmwt=17
iter=final
#end configuration section.

echo "$0 $@"  # Print the command line for logging
[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 3 ]; then
  echo "Usage: $0 [--cmd (run.pl|queue.pl...)] <data-dir> <lang-dir|graph-dir> <decode-dir>"
  echo " Options:"
  echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."
  echo "    --stage (0|1|2)                 # start scoring script from part-way through."
  echo "    --decode_mbr (true/false)       # maximum bayes risk decoding (confusion network)."
  echo "    --min_lmwt <int>                # minumum LM-weight for lattice rescoring "
  echo "    --max_lmwt <int>                # maximum LM-weight for lattice rescoring "
  exit 1;
fi

data=$1
lang_or_graph=$2
dir=$3

symtab=$lang_or_graph/words.txt # It is essentially subwords, the entries in subword lexicon

for f in $symtab $dir/lat.1.gz $data/text; do
  [ ! -f $f ] && echo "score.sh: no such file $f" && exit 1;
done


ref_filtering_cmd="cat"
hyp_filtering_cmd="cat"


if $decode_mbr ; then
  echo "$0: scoring with MBR, word insertion penalty=$word_ins_penalty"
else
  echo "$0: scoring with word insertion penalty=$word_ins_penalty"
fi


mkdir -p $dir/scoring_kaldi
cat $data/text | $ref_filtering_cmd > $dir/scoring_kaldi/test_filt_sw.txt || exit 1;
if [ $stage -le 0 ]; then

  for wip in $(echo $word_ins_penalty | sed 's/,/ /g'); do
    mkdir -p $dir/scoring_kaldi/penalty_$wip/log

    if $decode_mbr ; then
      $cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring_kaldi/penalty_$wip/log/best_path.LMWT.sw.log \
        acwt=\`perl -e \"print 1.0/LMWT\"\`\; \
        lattice-scale --inv-acoustic-scale=LMWT "ark:gunzip -c $dir/lat.*.gz|" ark:- \| \
        lattice-add-penalty --word-ins-penalty=$wip ark:- ark:- \| \
        lattice-prune --beam=$beam ark:- ark:- \| \
        lattice-mbr-decode  --word-symbol-table=$symtab \
        ark:- ark,t:- \| \
        utils/int2sym.pl -f 2- $symtab \| \
        $hyp_filtering_cmd '>' $dir/scoring_kaldi/penalty_$wip/LMWT.sw.txt || exit 1;

    else
      $cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring_kaldi/penalty_$wip/log/best_path.LMWT.sw.log \
        lattice-scale --inv-acoustic-scale=LMWT "ark:gunzip -c $dir/lat.*.gz|" ark:- \| \
        lattice-add-penalty --word-ins-penalty=$wip ark:- ark:- \| \
        lattice-best-path --word-symbol-table=$symtab ark:- ark,t:- \| \
        utils/int2sym.pl -f 2- $symtab \| \
        $hyp_filtering_cmd '>' $dir/scoring_kaldi/penalty_$wip/LMWT.sw.txt || exit 1;
    fi

    $cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring_kaldi/penalty_$wip/log/score.LMWT.sw.log \
      cat $dir/scoring_kaldi/penalty_$wip/LMWT.sw.txt \| \
      compute-wer --text --mode=present \
      ark:$dir/scoring_kaldi/test_filt_sw.txt  ark,p:- ">&" $dir/swer_LMWT_$wip || exit 1;

  done
fi



if [ $stage -le 1 ]; then

  for wip in $(echo $word_ins_penalty | sed 's/,/ /g'); do
    for lmwt in $(seq $min_lmwt $max_lmwt); do
      # adding /dev/null to the command list below forces grep to output the filename
      grep WER $dir/swer_${lmwt}_${wip} /dev/null
    done
  done | utils/best_wer.sh  >& $dir/scoring_kaldi/best_swer || exit 1

  best_swer_file=$(awk '{print $NF}' $dir/scoring_kaldi/best_swer)
  best_wip=$(echo $best_swer_file | awk -F_ '{print $NF}')
  best_lmwt=$(echo $best_swer_file | awk -F_ '{N=NF-1; print $N}')

  if [ -z "$best_lmwt" ]; then
    echo "$0: we could not get the details of the best SWER from the file $dir/swer_*.  Probably something went wrong."
    exit 1;
  fi

  if $stats; then
    mkdir -p $dir/scoring_kaldi/swer_details
    echo $best_lmwt > $dir/scoring_kaldi/swer_details/lmwt # record best language model weight
    echo $best_wip > $dir/scoring_kaldi/swer_details/wip # record best word insertion penalty

    $cmd $dir/scoring_kaldi/log/stats1.swer.log \
      cat $dir/scoring_kaldi/penalty_$best_wip/$best_lmwt.sw.txt \| \
      align-text --special-symbol="'***'" ark:$dir/scoring_kaldi/test_filt_sw.txt ark:- ark,t:- \|  \
      utils/scoring/wer_per_utt_details.pl --special-symbol "'***'" \| tee $dir/scoring_kaldi/swer_details/per_utt \|\
       utils/scoring/wer_per_spk_details.pl $data/utt2spk \> $dir/scoring_kaldi/swer_details/per_spk || exit 1;

    $cmd $dir/scoring_kaldi/log/stats2.swer.log \
      cat $dir/scoring_kaldi/swer_details/per_utt \| \
      utils/scoring/wer_ops_details.pl --special-symbol "'***'" \| \
      sort -b -i -k 1,1 -k 4,4rn -k 2,2 -k 3,3 \> $dir/scoring_kaldi/swer_details/ops || exit 1;

    $cmd $dir/scoring_kaldi/log/swer_bootci.log \
      compute-wer-bootci --mode=present \
        ark:$dir/scoring_kaldi/test_filt_sw.txt ark:$dir/scoring_kaldi/penalty_$best_wip/$best_lmwt.sw.txt \
        '>' $dir/scoring_kaldi/swer_details/swer_bootci || exit 1;

  fi
fi

# If we got here, the scoring was successful.
# As a  small aid to prevent confusion, we remove all wer_{?,??} files;
# these originate from the previous version of the scoring files
# i keep both statement here because it could lead to confusion about
# the capabilities of the script (we don't do cer in the script)
# rm $dir/wer_{?,??} 2>/dev/null
# rm $dir/cer_{?,??} 2>/dev/null
# rm $dir/swer_{?,??} 2>/dev/null
exit 0;
