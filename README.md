This is a [kaldi](https://kaldi-asr.org/) based recipie for Malayalam speech recognition. You need a working Kaldi directory to run this script.

Details on how to run this script and the working is described here.

To install Kaldi, see the documentation [here](https://kaldi-asr.org/doc/install.html)

The source code of `/asr_malayalam` has to be placed in the `/egs` directory of Kaldi installation directory.

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

- Create bigram word level LM grammar from text files
- Uses predefined phonetic lexicon
- Extracts MFCC features(13 cepstral bins) after converting all sampling rates to 16kHz
- Trains mono, tri, tri_lda, tri_sat acoustic models (AM) is that order, using alignments from previous stage.
- Compiles the LM grammar, phonetic lexicon and acoustic models to create HCLG.fst graph
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

To study the effect of subword based LM and pronunciation lexicon on Malayalam ASR task, we have designed the experiments such that all of them uses the same acoustic model, but different LMs and lexicons. In experiment W1, we prepare the first baseline ASR model with word based LM, trained on the speech transcripts
used for acoustic model training, and create a lexicon that covers all the words in this corpus. The OOV rate of this model is very high on test datasets.  Experiments W2-W4 use an expanded text corpus incorporating sentences from SMC corpus containing to 212k unique sentences. Lexicon expansion is carried out incrementally based on word frequencies in the LM training corpus. Words of at least 5, 4 and 3 occurrences in the LM corpus are included in the lexicons used in experiments W2, W3 and W4, respectively.
### EXPERIMENT W1

| n-gram order | T1 (WER) | T1 (CER) | T2 (WER) | T2 (CER) | T3 (WER) | T3 (CER) |
| ------------ | -------- | -------- | -------- | -------- | -------- | -------- |
| 2            | 14.1     | 4.26     | 47.55    | 11.89    | 88.5     | 43.16    |
| 3            | 14.15    | 4.27     | 47.37    | 11.88    | 88.43    | 43.17    |
| 4            | 14.15    | 4.27     | 47.37    | 11.88    | 88.39    | 43.17    |

### EXPERIMENT W2

| n-gram order | T1 (WER) | T1 (CER) | T2 (WER) | T2 (CER) | T3 (WER) | T3 (CER) |
| ------------ | -------- | -------- | -------- | -------- | -------- | -------- |
| 2            | 9.89     | 2.17     | 37.25    | 7.13     | 88.45    | 41.20   |
| 3            | 9.81     | 2.13     | 37.37    | 7.13     | 88.39    | 41.26   |
| 4            | 9.78     | 2.12     | 37.40    | 7.12     | 88.38    | 41.26   |

### EXPERIMENT W3

| n-gram order | T1 (WER) | T1 (CER) | T2 (WER) | T2 (CER) | T3 (WER) | T3 (CER) |
| ------------ | -------- | -------- | -------- | -------- | -------- | -------- |
| 2            | 10.03    | 2.17     | 36.43    | 6.86     | 87.91    | 40.91    |
| 3            | 9.89     | 2.11     | 36.33    | 6.85     | 87.75    | 40.88    |
| 4            | 9.86     | 2.11     | 36.43    | 6.84     | 87.72    | 40.88    |

### EXPERIMENT W4

| n-gram order | T1 (WER) | T1 (CER) | T2 (WER) | T2 (CER) | T3 (WER) | T3 (CER) |
| ------------ | -------- | -------- | -------- | -------- | -------- | -------- |
| 2            | 10.07    | 2.11     | 34.91    | 6.42     | 86.31    | 40.10    |
| 3            | 9.88     | 2.09     | 34.83    | 6.42     | 86.17    | 40.07    |
| 4            | 9.86     | 2.07     | 34.96    | 6.41     | 86.12    | 40.06    |

We repeat the above experiments, namely SW1-SW4, with the LM training corpus and lexicons in syllabified form. Lexicons with syllables as entries are significantly
smaller than word based lexicons and are able to decode speech with with improved word error rate (WER) on test datasets with medium to large word level OOVs.

### EXPERIMENT SW1

| n-gram order | T1 (WER) |T1 (SWER)| T1 (CER) | T2 (WER) | T2 (SWER)|T2 (CER)|T3 (WER)|T3 (SWER)| T3 (CER)|
| ------------ | -------- |---------| -------- | -------- |----------|--------|--------|---------| --------|
| 2            | 24.62    |9.69     | 5.23     | 43.67    | 15.52    |8.51    | 88.45  |53.85    |36.40    |
| 3            | 17.90    |7.12     | 3.81     | 38.09    | 12.81    |6.84    | 84.99  |51.69    |34.85    |
| 4            | 17.35    |6.87     | 3.68     | 37.70    | 12.66    |6.82    | 85.11  |51.43    |34.73    |

### EXPERIMENT SW2

| n-gram order | T1 (WER) |T1 (SWER)| T1 (CER) | T2 (WER) | T2 (SWER)|T2 (CER)|T3 (WER)|T3 (SWER)| T3 (CER)|
| ------------ | -------- |---------| -------- | -------- |----------|--------|--------|---------| --------|
| 2            | 23.76    |9.01     | 4.67     | 39.14    | 13.64    |7.25    | 85.88  |53.57    |36.63    |
| 3            | 14.75    |5.04     | 2.42     | 26.77    | 8.37     |4.22    | 79.53  |48.6     |33.34    |
| 4            | 13.43    |4.49     | 2.17     | 26.35    | 7.92     |3.85    | 78.38  |47.33    |32.48    |
### EXPERIMENT SW3

| n-gram order | T1 (WER) |T1 (SWER)| T1 (CER) | T2 (WER) | T2 (SWER)|T2 (CER)|T3 (WER)|T3 (SWER)| T3 (CER)|
| ------------ | -------- |---------| -------- | -------- |----------|--------|--------|---------| --------|
| 2            | 23.71    |8.99     | 4.67     | 39.09    | 13.63    |7.24    | 85.90  |53.59    |36.66    |
| 3            | 14.75    |5.05     | 2.43     | 26.77    | 8.35     |4.21    | 79.58  |48.62    |33.34    |
| 4            | 13.44    |4.49     | 2.17     | 26.32    | 7.91     |3.85    | 78.30  |47.37    |32.50    |

### EXPERIMENT SW4

| n-gram order | T1 (WER) |T1 (SWER)| T1 (CER) | T2 (WER) | T2 (SWER)|T2 (CER)|T3 (WER)|T3 (SWER)| T3 (CER)|
| ------------ | -------- |---------| -------- | -------- |----------|--------|--------|---------| --------|
| 2            | 23.78    |9.03     | 4.69     | 39.01    | 13.62    |7.24    | 85.91  |53.61    |36.66    |
| 3            | 14.76    |5.07     | 2.45     | 26.77    | 8.38     |4.21    | 79.46  |48.65    |33.34    |
| 4            | 13.44    |4.50     | 2.17     | 26.40    | 7.91     |3.84    | 78.30  |47.37    |32.55    |

