This is a [kaldi](https://kaldi-asr.org/) based recipie for Malayalam speech recognition. You need a working Kaldi directory to run this script.

Details on how to run this script and the working is described here.

To install Kaldi, see the documentation [here](https://kaldi-asr.org/doc/install.html)

The source code of `/ml-subword-asr` has to be placed in the `/egs` directory of Kaldi installation directory.

## USAGE

`./run_gmm.sh ./inputdirectory`

input directory has the following structure:
```
├── language -> symlink/to/language/model/source ( lm_train.txt, lexicon.txt)
├── test
│   └── corpus1
│       ├── audio -> symlink/to/audio/files_directory (utt1.wav, utt2.wav)
│       └── metadata.tsv -> symlink/to/audio/files/metadata (metadata.tsv)
└── train
    ├── corpus2
    |      ├── audio -> symlink/to/audio/files_directory (utt1.wav, utt2.wav)
    |      └── metadata.tsv -> symlink/to/audio/files/metadata (metadata.tsv)
    └── corpus3
        ├── audio -> symlink/to/audio/files_directory (utt1.wav, utt2.wav)
        └── metadata.tsv -> symlink/to/audio/files/metadata (metadata.tsv)
```
metadata.tsv is a tab separated values of utterence_id, speaker_id, file_name in audio folder, transcript in Malayalam script.

This script performs the following tasks:

- Create n-gram subword level LM grammar from text files
- Uses predefined graphemic lexicon
- Extracts MFCC features(13 cepstral bins) after converting all sampling rates to 16kHz
- Trains mono, tri, tri_lda, tri_sat acoustic models (AM) is that order, using alignments from previous stage.
- Compiles the LM grammar, graphemic lexicon and acoustic models to create HCLG.fst graph
- Test each acoustic model and stores the decoding results



`./run_chain.sh`

This script performs the following tasks:

- Runs ivector training, extracts 30 dimensional ivectors. It uses high resolution MFCC (40 cepstral bins)
- Use alignments from the best trigram model (Currently hardcoded to tri_sat) to start nnet3 AM training
- nnet3 AM trained on CUDA compiled GPU (single Tesla T4)
- Checks phone compatibility of LM
- Make graph with new AM model
- Test and save the results

## RESULTS

|Segmentation| Best WER (%)| OOV-WER (%)|
|---         |---        |---       |
|Word        |35         |100       |
|Morfessor   |28         |55.3      |
|BPE         |28         |53.1      |
|Unigram     |29         |55.0      |
|Syllable    |26         |49.9      |
|SBPE        |28         |50.2      |

