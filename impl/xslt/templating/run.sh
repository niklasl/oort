#!/bin/bash

data=$1
template=$2

xsltproc --stringparam doc "$data" $(dirname $0)/expand_rdfa.xslt "$template"

#xsltproc rdfxml-grit.xslt $INPUT_RDF /tmp/data.grit
#xsltproc rdfat-to-xslt.xslt $RDFA_TEMPLATE /tmp/rdfat.grit
#xsltproc /tmp/rdfat.xslt /tmp/rdfat.xslt $RESULT

