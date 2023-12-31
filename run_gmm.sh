#!/usr/bin/env bash 
#set-up for single machine or cluster based execution
. ./cmd.sh
#set the paths to binaries and other executables
[ -f path.sh ] && . ./path.sh

# Kavya Manohar(2020)
# Malayalam ASR Training and Testing



if [ "$#" -ne 1 ]; then
    echo "ERROR: $0"
    echo "USAGE: $0 <input_dir>"
    exit 1
fi

input_dir=$1

#swunit=word
#swunit=bpe
#swunit=morph
#swunit=unigram
swunit=syl
#swunit=sbpe

#ngram=2
#ngram=3
#ngram=4
#ngram=5
ngram=6

language_dir=$1/languages
subwordlanguage_dir=$1/languages/$swunuit
data_dir=./data
train_dir=$1/train
test_dir=$1/test
#test_dir=$1/val

# Switches for GMM-HMM training are defined here
createsubwordlm_sw=1
traindataprep_sw=0
train_sw=0
rebuildgraph_sw=0
testdataprep_sw=0
test_sw=0

if [ $createsubwordlm_sw == 1 ]; then

echo ============================================================================
echo "                  Running the script for Subword Language Model Creation   	        "
echo ============================================================================

./createLMsubword.sh $subwordlanguage_dir $data_dir $swunit $ngram

fi


if [ $traindataprep_sw == 1 ]; then

echo ============================================================================
echo "  Preparing Audio Training Data (Combines files from all training corpora)  	        "
echo ============================================================================
rm -rf $data_dir/train
mkdir $data_dir/train
for d in $train_dir/* ; do
    echo "Corpus $d audio preparation"
    ./audiodataprep.sh $d $data_dir train
done

./utils/fix_data_dir.sh $data_dir/train



echo ============================================================================
echo "     MFCC Feature Extraction and Mean-Variance Tuning Files for Training  	        "
echo ============================================================================

./extractfeatures.sh $data_dir train


fi

if [ $train_sw == 1 ]; then

echo ============================================================================
echo "     Acoustic Model Training Compiling Decoding Graphs  	        "
echo ============================================================================
./utils/fix_data_dir.sh $data_dir/train

./train_gmm.sh $data_dir $swunit $ngram
fi

if [ $rebuildgraph_sw == 1 ]; then
./makegraphs_gmm.sh $data_dir $swunit $ngram

fi

if [ $test_sw == 1 ]; then

    echo ============================================================================
    echo "     Testing   	        "
    echo ============================================================================

    for d in $test_dir/* ; do
            test_dir=$(basename $d)
            if [ $testdataprep_sw == 1 ]; then

                rm -rf $data_dir/$test_dir
                mkdir $data_dir/$test_dir
                ./audiodataprep.sh $d $data_dir $test_dir
                ./utils/fix_data_dir.sh $data_dir/$test_dir


                echo "     MFCC Feature Extraction and Mean-Variance Tuning for Testing  	        "

                ./extractfeatures.sh $data_dir $test_dir
                ./utils/fix_data_dir.sh $data_dir/$test_dir
            fi

            echo "     Runing Decoding scripts  	        "
            ./test_gmm.sh $data_dir $test_dir $swunit $ngram
    done

fi

echo ============================================================================
echo "                   End of Script             	        "
echo ============================================================================
