GBASToolKit
============

[![DOI](https://zenodo.org/badge/126183592.svg)](https://zenodo.org/badge/latestdoi/126183592)

** Beta release v1.0-beta1 "Indy" **

**NOTE: At the moment you can now perform a gene-based analysis using 1000G phase 1 in VEGAS2; MAGMA also has the option to use other references. We are updating some items, so please check back. For a list of items we are working on check the bottom of this readme.**

### Introduction
A ToolKit to perform Gene-Based Association Studies of genome-wide association studies (GWAS) using VEGAS or MAGMA. 
This repository contains a ToolKit to perform a Gene-Based Association Study of GWAS (**GBASToolKit**) and comprises various scripts in Perl, Python, R, and BASH.

All scripts are annotated for debugging purposes - and future reference. The only scripts the user should edit are: 
- the main job submission script `gbastoolkit.qsub.sh`, 
- `gbastoolkit.conf`, a configuration file with some system and analytical settings, and 
- `gbastoolkit.list` which contains a list of all the GWAS datasets.

Scripts will work within the context of a certain Linux environment (in this case a CentOS7 system on a SUN Grid Engine background); we have tested **GBASToolKit** on CentOS7, although with some edits it should work on OS X Sierra (version 10.11.[x]) too. 

--------------

### Installing the scripts locally

We need to make an appropriate directory to download 'gits' to, and install this 'git'.

#### Step 1: Make a directory, and go there.

```
mkdir -p ~/git/ && cd ~/git
```

#### Step 2: Clone this git, unless it already exists. 
We clone using SSH, which makes editing, committing, pushing and pulling of the repository much easier.

```
if [ -d ~/git/GBASToolKit/.git ]; then \
		cd ~/git/GBASToolKit && git pull; \
	else \
		cd ~/git/ && git clone git@github.com:swvanderlaan/GBASToolKit.git; \
	fi
```

#### Step 3: Check for dependencies of Python, Perl and R, and install them if necessary.
:large_orange_diamond: [text and codes forthcoming]


#### Step 4: Create necessary databases. These include:
You will have to download and create some data needed for **GBASToolKit** to function. The `resource.creator.sh` script will automagically create the necessary files. For some of these files, it is necessary to supply the proper reference data in VCF-format (version 4.1+). The files created by `resource.creator.sh` include:
- GENESFILE    -- a file containing chromosomal basepair positions per gene, default is `Gencode`.

To download and install please run the following code, this should submit various jobs to create the necessary databases.

```
cd ~/git/GBASToolKit && bash resource.creator.sh
```

##### Available references
There are a couple of reference available per standard, these are:
- **HapMap 2 [`HM2`], version 2, release 22, b36.**        -- HM2 contains about 2.54 million variants, but does *not* include variants on the X-chromosome. Obviously few, if any, meta-analyses of GWAS will be based on that reference, but it's good to keep. View it as a 'legacy' feature. VEGAS2 only. [NOT AVAILABLE YET] :large_blue_diamond:
- **1000G phase 1, version 3 [`1Gp1`], b37.**              -- 1Gp1 contains about 38 million variants, including INDELs, and variation on the X, XY, and Y-chromosomes. VEGAS2 only.
- **1000G phase 3, version 5 [`1Gp3`], b37.**              -- 1Gp3 contains about 88 million variants, including INDELs, and variation on the X, XY, and Y-chromosomes. VEGAS2 and MAGMA. [NOT AVAILABLE YET for VEGAS2] :large_orange_diamond:

#### Step 5: Installation of necessary software :large_blue_diamond:
**GBASToolKit** requires you to install several software packages. 
- *PLINK2* for LD-calculations; reference: https://www.cog-genomics.org/plink2. 
- *VEGAS2*; for gene-based association analysis; reference: https://vegas2.qimrberghofer.edu.au. 
- *MAGMA* for gene-based association analysis, and gene-set enrichment analyses; reference: https://ctg.cncr.nl/software/magma. 

--------------

### Gene-Based Association Study of GWAS
**GBASToolKit** will (semi-)automatically perform a gene-based association study of GWAS. It will reformat, and optionally clean, and analyze the data based on some required user-specificied configuration settings. Some relevant statistics, such as HWE, minor allele count (MAC), and coded allele frequency (CAF) will also be added to the parsed GWAS dataset. The optional QC is based on the paper by [Winkler T.W. et al.](https://www.ncbi.nlm.nih.gov/pubmed/24762786).

The main script, which is controlled by `gbastoolkit.qsub.sh`, `gbastoolkit.conf`, and `gbastoolkit.list`, is `gbastoolkit.sh`. `gbastoolkit.sh` will automagically chunk up data, submit jobs, and set things so that your meta-analysis will run smoothly. 
The premier step is at the 'reformatting' stage. Any weirdly formatted GWAS dataset will immediately throw errors, and effectively throwing out that particular GWAS dataset from the gene-based analysis. Such errors will be reported.

#### Reformatting summary statistics GWAS data
GWAS datasets are first cut in chunks of 125,000 [default] variants by `gbastoolkit.sh`, and subsequently parse and reformat by `gwas.parser.R`. During *parsing* the GWAS dataset will be re-formatted to fit the downstream pipeline. In addition some variables are calculated (if not present), for instance "minor allele frequency (MAF)", and "minor allele count (MAC)". `gwas.wrapper.sh` will automagically wrap up all the parsed and reformatted data into a seperate dataset, entitled `dataset.pdat`.

#### Cleaning reformatted GWAS data
The user can choose to clean the parsed and reformatted the data; this will be based on the settings provided in  `gbastoolkit.conf`. Cleaning settings include:
- MAF, minimum minor allele frequency to keep variants, e.g. "0.005"
- MAC, minimum minor allele count to keep variants, e.g. "30"
- HWE, Hardy-Weinberg equilibrium p-value at which to drop variants, e.g. "1E-6"
- INFO, minimum imputation quality score to keep variants, e.g. "0.3"
- BETA, maximum effect size to allow for any variant, e.g. "10"
- SE, maximum standard error to allow for any variant, e.g. "10"

In such cases the resulting file, `dataset.cdat`, will be used for downstream analyses, instead of the `dataset.pdat` file.

#### Gene-based analysis
A genome-wide, per-chromosome VEGAS2 and MAGMA analysis is performed. In addition a standard pathway-enrichment analysis in MAGMA is also done. Results are summarised into easy tables.
:large_orange_diamond: [Future versions will also plot results.]

--------------

### Things to do for future versions
:ballot_box_with_check: *implemented*
:x: *skipped*
:construction: *working on it*
:large_orange_diamond: *next version, high priority*
:large_blue_diamond: *next version, low priority*

#### Scripts
- add script to check for dependencies :large_orange_diamond:
- workflows for installing PLINK2, VEGAS2 and MAGMA properly :large_blue_diamond:
- add in HapMap2 as reference (VEGAS2 only) :large_blue_diamond:
- add in download and parsing script for reference to enable per-chromosome analyses :large_blue_diamond:
- add in VEGAS2 based pathway enrichment analysis :construction:
- extent resource script with download of functional elements, to facilitate the analysis of transcription binding sites, or active enhancers, _etc._ :large_orange_diamond:

#### Plotting
- add (option) to plot results in a Manhattan :large_orange_diamond:
- add (option) to plot results in a QQ-plot :large_orange_diamond:
- add gene-names based on a threshold to Manhattan :large_blue_diamond:
- add option to plot regional plots of significant genes :large_blue_diamond:

--------------

#### The MIT License (MIT)
##### Copyright (c) 2015-2018 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:   

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Reference: http://opensource.org.


