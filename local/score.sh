
#!/usr/bin/env bash

steps/scoring/score_kaldi_wer.sh "$@"
steps/scoring/score_kaldi_cer.sh --stage 2 "$@"
#local/score_kaldi_swer.sh "$@"
