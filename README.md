PrimerBot
=========

High-throughput qPCR primer design

HTML interface to a custom perl script to design qPCR primers for both mRNA and ChIP studies. Supports automated fetching of sequences and primer design through Primer3.

mRNA qPCR primer design Automatically identifies gene features( UTR, exon boundaries) to design primers that span exon-exon junctions, amplification of 3' UTR, or within an exon.

ChIP qPCR primer design fetches sequences from a local fasta file and designs primers to amplify in the middle of the genomic feature. 
