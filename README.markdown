# egor

* http://www-cryst.bioc.cam.ac.uk/egor


## Description

'egor' is a program for calculating environment-specific substitution tables from user providing environmental class definitions and sequence alignments with the annotations of the environment classes.


## Features

* Environment-specific substitution table generation based on user providing environmental class definition
* Entropy-based smoothing procedures to cope with sparse data problem
* BLOSUM-like weighting procedures using PID threshold
* Both unidirectional and bidirectional substitution matirces can be generated (NOT IMPLEMENTED YET!!!)


## Installation

    ~user $ sudo gem install egor


## Requirements

* ruby 1.8.7 or above (http://www.ruby-lang.org)
* rubygems 1.2.0 or above (http://rubyforge.org/projects/rubygems/)

Following RubyGems will be automatically installed if you have rubygems installed on your machine

* narray (http://narray.rubyforge.org/)
* facets (http://facets.rubyforge.org/)
* bio (http://bioruby.open-bio.org/)
* simple_memoize (http://github.com/JackDanger/simple_memoize/tree/master)


## Basic Usage

It's pretty much the same as Kenji's subst (http://www-cryst.bioc.cam.ac.uk/~kenji/subst/), so in most cases, you can swap 'subst' with 'egor'.

    ~user $ egor -l TEMLIST-file -c classdef.dat
                or
    ~user $ egor -f TEM-file -c classdef.dat


## Options
    --tem-file (-f) FILE: a tem file
    --tem-list (-l) FILE: a list for tem files
    --classdef (-c) FILE: a file for the defintion of environments (default: 'classdef.dat')
    --outfile (-o) FILE: output filename (default 'allmat.dat')
    --weight (-w) INTEGER: clustering level (PID) for the BLOSUM-like weighting (default: 60)
    --noweight: calculate substitution count with no weights
    --smooth (-s) INTEGER:
        0 for partial smoothing (default)
        1 for full smoothing
    --p1smooth: perform smoothing for p1 probability calculation when partial smoothing
    --nosmooth: perform no smoothing operation
    --cys (-y) INTEGER:
        0 for using C and J only for structure (default)
        1 for both structure and sequence
        2 for using only C for both (must be set when you have no 'disulphide' or 'disulfide' annotation in templates)
    --output INTEGER:
        0 for raw count (no smoothing performed)
        1 for probabilities
        2 for log odds ratios (default)
    --noroundoff: do not round off log odds ratio
    --scale INTEGER: log odds ratio matrices in 1/n bit units (default 3)
    --sigma DOUBLE: change the sigma value for smoothing (default 5.0)
    --autosigma: automatically adjust the sigma value for smoothing
    --add DOUBLE: add this value to raw count when deriving log odds ratios without smoothing (default 1/#classes)
    --penv: use environment-dependent frequencies for log odds ratio calculation (default false) (NOT implemented yet!!!)
    --pidmin DOUBLE: count substitutions only for pairs with PID equal to or greater than this value (default none)
    --pidmax DOUBLE: count substitutions only for pairs with PID smaller than this value (default none)
    --verbose (-v) INTEGER
        0 for ERROR level
        1 for WARN or above level (default)
        2 for INFO or above level
        3 for DEBUG or above level
    --version: print version
    --help (-h): show help


## Usage

1. Prepare an environmental class definition file. For more details, please check this notes (http://www-cryst.bioc.cam.ac.uk/~kenji/subst/NOTES).

    ~user $ cat classdef.dat
    #
    # name of feature (string); values adopted in .tem file (string); class labels assigned for each value (string);\
    # constrained or not (T or F); silent (used as masks)? (T or F)
    #
    secondary structure and phi angle;HEPC;HEPC;T;F
    solvent accessibility;TF;Aa;F;F
    hydrogen bond to other sidechain/heterogen;TF;Ss;F;F
    hydrogen bond to mainchain CO;TF;Oo;F;F
    hydrogen bond to mainchain NH;TF;Nn;F;F

2. Prepare structural alignments and their annotations of above environmental classes in PIR format.

    ~user $ cat sample1.tem
    >P1;1mnma
    sequence
    QKERRKIEIKFIENKTRRHVTFSKRKHGIMKKAFELSVLTGTQVLLLVVSETGLVYTFSTPKFEPIVTQQEGRNL
    IQACLNAPDD*
    >P1;1egwa
    sequence
    --GRKKIQITRIMDERNRQVTFTKRKFGLMKKAYELSVLCDCEIALIIFNSSNKLFQYASTDMDKVLLKYTEY--
    ----------*
    >P1;1mnma
    secondary structure and phi angle
    CPCCCCCCCCCCCCHHHHHHHHHHHHHHHHHHHHHHHHHHPCCCEEEEECCCPCEEEEECCCCCHHHHCHHHHHH
    HHHHHCCCCP*
    >P1;1egwa
    secondary structure and phi angle
    --CCCCCCCCCCCCHHHHHHHHHHHHHHHHHHHHHHHHHCPCCCEEEEECCCPCEEEEECCCHHHHHHHHHHC--
    ----------*
    >P1;1mnma
    solvent accessibility
    TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTFTTTTTTTTTTTTTTTT
    TTTTTTTTTT*
    >P1;1egwa
    solvent accessibility
    --TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTFTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT--
    ----------*
    ... 

3. When you have two or more alignment files, you should make a separate file containing all the paths for the alignment files.

    ~user $ ls -1 *.tem > TEMLIST
    ~user $ cat TEMLIST
    sample1.tem
    sample2.tem
    ...

4. To produce substitution count matrices, type

    ~user $ egor -l TEMLIST --output 0 -o substcount.mat

5. To produce substitution probability matrices, type

    ~user $ egor -l TEMLIST --output 1 -o substprob.mat

6. To produce log odds ratio matrices, type

    ~user $ egor -l TEMLIST --output 2 -o substlogo.mat

7. To produce substitution data only from the sequence pairs within a given PID range, type (if you don't provide any name for output, 'allmat.dat' will be used.)

    ~user $ egor -l TEMLIST --pidmin 60 --pidmax 80 --output 1

8. To change the clustering level (default 60), type

    ~user $ egor -l TEMLIST --weight 80 --output 2

9. In case any positions are masked with the character 'X' in any environmental features will be excluded from the calculation of substitution counts.

10. Then, it will produce a file containing all the matrices, which will look like the one below. For more details, please check this notes (http://www-cryst.bioc.cam.ac.uk/~kenji/subst/NOTES).

#begin html
    #
    # Environment-specific amino acid substitution matrices
    # Creator: egor version 0.0.4
    # Creation Date: 20/01/2009 14:45
    #
    # Definitions for structural environments:
    # 5 features used
    #
    # secondary structure and phi angle;HEPC;HEPC;F;F
    # solvent accessibility;TF;Aa;F;F
    # hydrogen bond to DNA;TF;Hh;F;F
    # water-mediated hydrogen bond to DNA;TF;Ww;F;F
    # van der Waals contact to DNA;TF;Vv;F;F
    #
    # (read in from classdef.dat)
    #
    # Number of alignments: 86
    # (list of .tem files read in from TEMLIST)
    #
    # Total number of environments: 64
    #
    # There are 21 amino acids considered.
    # ACDEFGHIKLMNPQRSTVWYJ
    # 
    # C: Cystine (the disulfide-bonded form)
    # J: Cysteine (the free thiol form)
    #
    # Weighting scheme: clustering at PID 60 level
    #
    # ...
    #
    >HAHWV 0
    #        A      C      D      E      F      G      H      I      K      L      M      N      P      Q      R      S      T      V      W      Y      J
    A        5     -6      0      0     -2      0     -2     -1     -1     -1      1     -1     -1      0     -1      1      0      0     -2     -2     -2
    C       -7     28     -8    -49     -3    -49     -2     -1    -11     -5     -1    -49     -6    -49    -49     -4     -6     -4    -49      3      9
    D        0     -7      7      2     -3      0      0     -4      0     -3     -3      2      0      0     -2      1      0     -3     -5     -3     -6
    E        0    -68      2      5     -3     -1     -1     -3      0     -3     -1      0      0      1     -1      0      0     -3     -3     -2     -7
    F       -2     -3     -3     -4      8     -4     -1      2     -4      1      0     -4     -4     -4     -4     -4     -2      1      2      3     -5
    G        0    -67      0     -1     -4      9     -3     -4     -2     -3     -4      1     -1     -2     -3      0     -2     -3     -3     -3     -2
    H       -2     -2      0     -1     -1     -3     11     -3     -2     -3     -2      0     -2     -1     -1     -1     -1     -3     -2      0     -4
    I       -1     -1     -4     -3      2     -4     -3      6     -3      2      2     -4     -2     -2     -4     -3     -1      3     -1      0     -4
    K       -1    -10      0      0     -4     -2     -1     -3      5     -3     -2      0      0      1      2     -1     -1     -3     -4     -2     -5
    L       -1     -5     -3     -3      1     -3     -3      2     -3      5      2     -4     -1     -2     -2     -3     -1      1      0     -1     -4
    M        1     -1     -3     -1      0     -4     -2      2     -3      2      8     -2     -2     -1     -2     -2     -1      1     -1     -1     -4
    N       -1    -66      2      0     -4      1      0     -4      0     -4     -2      8     -1      0     -1      1      0     -3     -5     -4     -5
    P       -1     -6      0      0     -3     -1     -2     -2     -1     -1     -2     -1      9     -1     -2      0      0     -2     -4     -3     -7
    Q        0    -66      0      1     -4     -2     -1     -2      1     -2     -1      0     -1      6      0      0     -1     -2     -2     -2     -6
    R       -1    -69     -1      0     -4     -3     -1     -3      2     -2     -1     -1     -2      0      6     -1     -1     -3     -3     -2     -6
    S        1     -4      1      0     -3      0     -1     -3     -1     -3     -2      1      0      0     -1      5      2     -2     -3     -1     -3
    T        0     -5     -1     -1     -2     -2     -1     -1     -1     -1     -1      0      0     -1     -1      2      5     -1     -3     -2     -3
    V        0     -4     -3     -3      1     -4     -3      3     -3      1      1     -3     -2     -2     -3     -2     -1      6      0     -1     -2
    W       -2    -61     -5     -3      2     -3     -2     -1     -4      0     -1     -5     -4     -2     -3     -3     -3      0     14      3     -6
    Y       -2      3     -3     -2      4     -3      0      0     -2      0      0     -4     -3     -2     -2     -1     -2      0      3      9     -3
    J       -3      9     -7     -8     -5     -2     -4     -4     -6     -4     -4     -5     -7     -6     -6     -3     -3     -2     -6     -3     15
    U       -3     15     -7     -8     -5     -3     -4     -4     -6     -4     -4     -5     -7     -6     -6     -3     -3     -2     -6     -3     15
    ... 
#end


## Repository

You can download a pre-built RubyGems package from

* rubyforge: http://rubyforge.org/projects/egor

or, You can fetch the source from

* github: http://github.com/semin/egor/tree/master


## Contact

Comments are welcome, please send an email to me (seminlee at gmail dot com). 


## License

(The MIT License)

Copyright (c) 2008 Semin Lee

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
