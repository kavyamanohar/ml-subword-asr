#set-up for single machine or cluster based execution
. ./cmd.sh
#set the paths to binaries and other executables
[ -f path.sh ] && . ./path.sh
basepath='.'

# Kavya Manohar(2020)
# Decoding Scripts

#USAGE
#      ./test.sh <data_dir> <test_dir>

if [ "$#" -ne 4 ]; then
    echo "ERROR: $0"
    echo "USAGE: $0 <data_dir> <test_dir> <swunit> <ngram>"
    exit 1
fi

data_dir=$1
test_dir=$2
swunit=$3
ngram=$4

nspk=$(wc -l <$data_dir/$test_dir/spk2utt)
nj=$nspk

mono_sw=1
tri_sw=0
trilda_sw=0
trisat_sw=0

tri1sen=150
tri1gauss=12000
trildasen=400
trildagauss=17000
trisatsen=550
trisatgauss=18000

echo "===== DECODING GMM-HMM====="


if [ $mono_sw == 1 ]; then

model_dir=exp/mono

echo "===== MONO DECODING ====="
echo "Decoding with the model $model_dir\_$swunit\_$ngram"

steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" --stage 0 $model_dir/graph_$swunit\_$ngram $data_dir/$test_dir $model_dir/decode_$test_dir\_$swunit\_$ngram

mkdir RESULT
echo "Saving Results"
model=$(basename $model_dir)
echo "=====WER=====" > RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
cat $model_dir/decode_$test_dir\_$swunit\_$ngram/scoring_kaldi/best_wer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
echo "=====CER=====" >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
cat $model_dir/decode_$test_dir\_$swunit\_$ngram/scoring_kaldi/best_cer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
echo "=====SWER=====" >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
cat $model_dir/decode_$test_dir\_$swunit\_$ngram/scoring_kaldi/best_swer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt

fi


if [ $tri_sw == 1 ]; then

model_dir=exp/tri_$tri1sen\_$tri1gauss

echo "===== TRI 1 DECODING ====="
echo "Decoding with the model $model_dir"
steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" --stage 0 $model_dir/graph_$swunit\_$ngram  $data_dir/$test_dir $model_dir/decode_$test_dir\_$swunit\_$ngram

mkdir RESULT
echo "Saving Results"
model=$(basename $model_dir)
echo "=====WER=====" > RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
cat $model_dir/decode_$test_dir\_$swunit\_$ngram /scoring_kaldi/best_wer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
echo "=====CER=====" >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
cat $model_dir/decode_$test_dir/scoring_kaldi/best_cer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
echo "=====SWER=====" >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
cat $model_dir/decode_$test_dir\_$swunit\_$ngram/scoring_kaldi/best_swer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt

fi

if [ $trilda_sw == 1 ]; then

model_dir=exp/tri_$trildasen\_$trildagauss\_lda

echo "===== TRI LDA DECODING ====="
echo "Decoding with the model $model_dir"
steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" --stage 0 $model_dir/graph_$swunit\_$ngram $data_dir/$test_dir $model_dir/decode_$test_dir\_$swunit\_$ngram

mkdir RESULT
echo "Saving Results"
model=$(basename $model_dir)
echo "=====WER=====" > RESULT/$test_dir\_$mode\_$swunit\_$ngraml.txt
cat $model_dir/decode_$test_dir\_$swunit\_$ngram/scoring_kaldi/best_wer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
echo "=====CER=====" >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
cat $model_dir/decode_$test_dir\_$swunit\_$ngram/scoring_kaldi/best_cer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
echo "=====SWER=====" >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
cat $model_dir/decode_$test_dir\_$swunit\_$ngram/scoring_kaldi/best_swer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt

fi

if [ $trisat_sw == 1 ]; then

model_dir=exp/tri_$trisatsen\_$trisatgauss\_sat

echo "===== TRI SAT DECODING ====="
echo "Decoding with the model $model_dir"
steps/decode_fmllr.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" --stage 0 $model_dir/graph_$swunit\_$ngram $data_dir/$test_dir $model_dir/decode_$test_dir

mkdir RESULT
echo "Saving Results"
model=$(basename $model_dir)
echo "=====WER=====" > RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
cat $model_dir/decode_$test_dir\_$swunit\_$ngram/scoring_kaldi/best_wer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
echo "=====CER=====" >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
cat $model_dir/decode_$test_dir\_$swunit\_$ngram/scoring_kaldi/best_cer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
echo "=====SWER=====" >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt
cat $model_dir/decode_$test_dir\_$swunit\_$ngram/scoring_kaldi/best_swer >> RESULT/$test_dir\_$model\_$swunit\_$ngram.txt

fi


echo ============================================================================
echo "                   End of Script             	        "
echo ============================================================================
