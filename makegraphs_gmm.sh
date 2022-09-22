#set-up for single machine or cluster based execution
. ./cmd.sh
#set the paths to binaries and other executables
[ -f path.sh ] && . ./path.sh

# Kavya Manohar(2020)


if [ "$#" -ne 3 ]; then
    echo "ERROR: $0"
    echo "USAGE: $0 <data_dir> <swunit> <ngram>"
    exit 1
fi

train_dict=dict
train_lang=lang_$swunit\_$ngram
exp=exp
data_dir=$1
swunit=$2
ngram=$3

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

echo ============================================================================
echo "     Building Decoding graphs    	        "
echo ============================================================================

if [ $mono_sw == 1 ]; then

echo "===== REMOVING EXISTING MONO GRAPH ====="

rm -rf $exp/mono/graph_$swunit\_$ngram 
echo "===== BUILDING MONO GRAPH ====="

utils/mkgraph.sh --mono $data_dir/$train_lang $exp/mono $exp/mono/graph_$swunit\_$ngram  || exit 1


fi

if [ $tri_sw == 1 ]; then

echo "===== REMOVING EXISTING TRI1 GRAPH ====="

rm -rf $exp/tri_$tri1sen\_$tri1gauss/graph_$swunit\_$ngram 
echo "===== BUILDING TRI1 (first triphone pass) GRAPH ====="

echo "========================="
echo " Sen = $tri1sen  Gauss = $tri1gauss"
echo "========================="

utils/mkgraph.sh $data_dir/$train_lang $exp/tri_$tri1sen\_$tri1gauss $exp/tri_$tri1sen\_$tri1gauss/graph_$swunit\_$ngram  || exit 1

fi

if [ $trilda_sw == 1 ]; then

echo "===== REMOVING EXISTING TRI_LDA GRAPH ====="

rm -rf $exp/tri_$trildasen\_$trildagauss\_lda/graph_$swunit\_$ngram 


echo "=====  BUILDING TRI_LDA (second triphone pass) GRAPH====="


echo "========================="
echo " Sen = $trildasen  Gauss = $trildagauss"
echo "========================="

utils/mkgraph.sh $data_dir/$train_lang $exp/tri_$trildasen\_$trildagauss\_lda $exp/tri_$trildasen\_$trildagauss\_lda/graph_$swunit\_$ngram  

fi


if [ $trisat_sw == 1 ]; then


echo "===== REMOVING EXISTING TRI_SAT GRAPH ====="

rm -rf $exp/tri_$trisatsen\_$trisatgauss\_sat/graph_$swunit\_$ngram  

echo "=====BUILDING for TRI_SAT (third triphone pass) GRAPH ====="

echo "========================="
echo " Sen = $trisatsen  Gauss = $trisatgauss"
echo "========================="


utils/mkgraph.sh $data_dir/$train_lang $exp/tri_$trisatsen\_$trisatgauss\_sat $exp/tri_$trisatsen\_$trisatgauss\_sat/graph_$swunit\_$ngram  

fi

echo ============================================================================
echo "                   End of Script             	        "
echo ============================================================================
