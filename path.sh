#Use the line below if the project is inside egs directory of kaldi
export KALDI_ROOT=`pwd`/../..


export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/src/gmm-bin:$KALDI_ROOT/src/chainbin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/ivectorbin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/online2bin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin/:$KALDI_ROOT/src/sgmm2bin/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:$KALDI_ROOT/src/nnetbin:$KALDI_ROOT/src/lmbin:$KALDI_ROOT/src/nnet2bin/:$KALDI_ROOT/src/nnet3bin/:$KALDI_ROOT/src/kwsbin:$PWD:$PATH
export LC_ALL=C
export IRSTLM=$KALDI_ROOT/tools/irstlm

