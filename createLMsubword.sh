#set-up for single machine or cluster based execution
. ./cmd.sh
#set the paths to binaries and other executables
[ -f path.sh ] && . ./path.sh

# Kavya Manohar(2020)
# For creating langauage model grammar G.fst and phonetic lexicon L.fst


# USAGE:
#
#      ./createLMsubword.sh <subwordlanguage_dir> <data_dir> <swunit>
#
# INPUT:
#
#   subwordlanguage_dir/
#       lexicon.txt
#       lm_train.txt
#   
# OUTPUT:
#
#   data_dir/
        # ├── lang_ngram
        # │   ├── G.fst
        # │   ├── L_disambig.fst
        # │   ├── L.fst
        # │   ├── oov.int
        # │   ├── oov.txt
        # │   ├── phones
        # │   │   ├── align_lexicon.int
        # │   │   ├── align_lexicon.txt
        # │   │   ├── context_indep.csl
        # │   │   ├── context_indep.int
        # │   │   ├── context_indep.txt
        # │   │   ├── disambig.csl
        # │   │   ├── disambig.int
        # │   │   ├── disambig.txt
        # │   │   ├── extra_questions.int
        # │   │   ├── extra_questions.txt
        # │   │   ├── nonsilence.csl
        # │   │   ├── nonsilence.int
        # │   │   ├── nonsilence.txt
        # │   │   ├── optional_silence.csl
        # │   │   ├── optional_silence.int
        # │   │   ├── optional_silence.txt
        # │   │   ├── roots.int
        # │   │   ├── roots.txt
        # │   │   ├── sets.int
        # │   │   ├── sets.txt
        # │   │   ├── silence.csl
        # │   │   ├── silence.int
        # │   │   ├── silence.txt
        # │   │   ├── wdisambig_phones.int
        # │   │   ├── wdisambig.txt
        # │   │   ├── wdisambig_words.int
        # │   │   ├── word_boundary.int
        # │   │   └── word_boundary.txt
        # │   ├── phones.txt
        # │   ├── topo
        # │   └── words.txt
        # ├── local
        # │   ├── dict
        # │   │   ├── extra_phones.txt
        # │   │   ├── extra_questions.txt
        # │   │   ├── lexiconp.txt
        # │   │   ├── lexicon.txt
        # │   │   ├── nonsilence_phones.txt
        # │   │   ├── optional_silence.txt
        # │   │   ├── phones.txt
        # │   │   └── silence_phones.txt
        # │   ├── lang_ngram
        # │   │   ├── align_lexicon.txt
        # │   │   ├── lexiconp_disambig.txt
        # │   │   ├── lexiconp.txt
        # │   │   ├── lex_ndisambig
        # │   │   └── phone_map.txt
        # │   └── tmp_lang_ngram
        # │       ├── lm_phone_bg.ilm.gz
        # │       └── oov.txt
        # └── train
        # └── lm_train.txt

if [ "$#" -ne 4 ]; then
    echo "ERROR: $0"
    echo "USAGE: $0 <subwordlanguage_dir> <data_dir> <swunit> <ngram>"
    exit 1
fi

language_dir=$1
data_dir=$2
swunit=$3
ngram=$4

#Defines the names of silence phone and spoken noice phone
silencephone=SIL
spokennoicephone=SPN




kaldi_root_dir='../..'

local=local_$swunit
dict_dir=${data_dir}/$local/dict
train_lang=lang_$swunit\_$ngram
train_folder=train_lm_$swunit


rm -rf $data_dir/$local/dict
rm -rf $data_dir/$local/tmp_$train_lang
rm -rf $data_dir/$train_lang
rm -rf $data_dir/$train_folder

echo "$0: Looking for lexicon files in $language_dir/$swunit"

sourcelexicon=lexicon_g.txt

for i in $sourcelexicon; do
    echo "$language_dir/$swunit/$i has the following contents"
    head $language_dir/$swunit/$i
done;

mkdir -p $data_dir/$local/dict
mkdir $data_dir/$local/tmp_$train_lang
mkdir $data_dir/$train_lang
mkdir $data_dir/$train_folder


echo ============================================================================
echo "                  Preparing the Lexicon Dictionary       	        "
echo ============================================================================

echo "!sil	$silencephone
<unk>	$spokennoicephone" > $dict_dir/lexicon.txt

echo "Creating the sorted lexicon file"
sort $language_dir/$swunit/$sourcelexicon | paste >> $dict_dir/lexicon.txt 

echo "Creating the list of Phones"
cat $dict_dir/lexicon.txt | cut -d '	' -f 2  - | tr ' ' '\n' | sort | uniq > $dict_dir/phones.txt
sed -i '/^$/d ' $dict_dir/phones.txt #Delete blank lines form phones.txt


cat $dict_dir/phones.txt | sed /$silencephone/d | sed /$spokennoicephone/d > $dict_dir/nonsilence_phones.txt 


echo $silencephone > $dict_dir/optional_silence.txt 
echo $silencephone > $dict_dir/silence_phones.txt
echo $spokennoicephone >> $dict_dir/silence_phones.txt

touch $dict_dir/extra_phones.txt $dict_dir/extra_questions.txt


echo ============================================================================
echo "                   Creating  lexicon dictionary L.fst               	        "
echo ============================================================================

utils/subword/prepare_lang_subword.sh --num-sil-states 3 --separator "+" $dict_dir "<unk>" $data_dir/$local/$train_lang $data_dir/$train_lang
# 
# For word position independent phones in the lexicon
# utils/subword/prepare_lang_subword.sh --num-sil-states 3  --separator "+" --position-dependent-phones "true" $dict_dir "<unk>" $data_dir/$local/$train_lang $data_dir/$train_lang


echo ============================================================================
echo "                   Creating  n-gram LM G.fst           	        "
echo ============================================================================
n_gram=3 # This specifies ngram order. for bigram set n_gram=2 for tri_gram set n_gram=3


echo "$0: Looking for language model training sentences files in $language_dir"
echo "$language_dir/$swunit/lm_train-$swunit.txt has the following contents"
head $language_dir/$swunit/lm_train-$swunit.txt

echo "Creating LM model creation input file"
cp $language_dir/$swunit/lm_train-$swunit.txt $data_dir/$train_folder/lm_train-$swunit.txt


head $data_dir/$train_folder/lm_train-$swunit.txt

echo "===== MAKING lm.arpa ====="
echo
loc=`which ngram-count`;
if [ -z $loc ]; then
        if uname -a | grep 64 >/dev/null; then
                sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64
        else
                        sdir=$KALDI_ROOT/tools/srilm/bin/i686
        fi
        if [ -f $sdir/ngram-count ]; then
                        echo "Using SRILM language modelling tool from $sdir"
                        export PATH=$PATH:$sdir
        else
                        echo "SRILM toolkit is probably not installed.
                                Instructions: tools/install_srilm.sh"
                        exit 1
        fi
fi

prune_thresh_small=0.00000003

cut -f 1 $dict_dir/lexicon.txt > $data_dir/$local/tmp_$train_lang/wordlist.txt 
# This word list is free from disambig symbols and  <eps>  which are present in $data_dir/$train_lang/words.txt and can affect arpa2fst conversions


#The words in lm_train.txt, which are listed in wordlist.txt, will have their entries in lm.arpa
ngram-count -order $n_gram -text $data_dir/$train_folder/lm_train-$swunit.txt \
    -vocab $data_dir/$local/tmp_$train_lang/wordlist.txt \
    -write-vocab $data_dir/$local/tmp_$train_lang/vocab-full.txt \
    -wbdiscount -wbdiscount1 -kndiscount2 -kndiscount3 -kndiscount4 -kndiscount5 -kndiscount6 -interpolate\
    -lm $data_dir/$local/tmp_$train_lang/lm.arpa

mkdir -p RESULT
echo "=======LM details=======" >> RESULT/LMmodel.txt
echo "$swunit Lexicon size:" >> RESULT/LMmodel.txt
wc -l $dict_dir/lexicon.txt  >> RESULT/LMmodel.txt
echo "Langauge model training sentences:" >> RESULT/LMmodel.txt
wc -l $data_dir/$train_folder/lm_train-$swunit.txt  >> RESULT/LMmodel.txt
echo "Ngram order: $n_gram" >> RESULT/LMmodel.txt
ngram -order $n_gram -lm $data_dir/$local/tmp_$train_lang/lm.arpa -ppl $language_dir/$swunit/lm_train-$swunit.txt >> RESULT/LMmodel.txt
ngram -order $n_gram -lm $data_dir/$local/tmp_$train_lang/lm.arpa -ppl $language_dir/$swunit/iiithtext-$swunit.txt >> RESULT/LMmodel.txt
ngram -order $n_gram -lm $data_dir/$local/tmp_$train_lang/lm.arpa -ppl $language_dir/$swunit/openslrtesttext-$swunit.txt >> RESULT/LMmodel.txt
ngram -order $n_gram -lm $data_dir/$local/tmp_$train_lang/lm.arpa -ppl $language_dir/$swunit/msctext-$swunit.txt >> RESULT/LMmodel.txt


arpa2fst --disambig-symbol=\#0 \
    --read-symbol-table=$data_dir/$train_lang/words.txt $data_dir/$local/tmp_$train_lang/lm.arpa $data_dir/$train_lang$lang/G.fst

echo ============================================================================
echo "                   End of Language Model Creation             	        "
echo ============================================================================


