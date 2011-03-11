#!/usr/bin/env python
from os import path as p
from StringIO import StringIO
from lxml import etree, html
from rdflib import ConjunctiveGraph
from rdfextras.tools.pathutils import guess_format


_herepath = lambda *parts: p.normpath(p.join(p.dirname(__file__), *parts))

GRIT_XSLT = etree.XSLT(etree.parse(_herepath("..", "grit", "rdfxml-grit.xslt")))
RDFAT_XSLT = etree.XSLT(etree.parse(_herepath("rdfat-to-xslt.xslt")))


def to_rdf_etree(sources):
    graph = ConjunctiveGraph()
    for source in sources:
        graph.load(source, format=guess_format(source))
    io = StringIO()
    graph.serialize(io, format="pretty-xml")
    io.seek(0)
    return etree.parse(io)

def apply_rdfa_template(rdfa_tplt_path, sources):
  rdfat_tree = RDFAT_XSLT(etree.parse(rdfa_tplt_path))
  rdfat = etree.XSLT(rdfat_tree)
  rdf_tree = to_rdf_etree(sources)
  grit_tree = GRIT_XSLT(rdf_tree)
  return rdfat(grit_tree)


if __name__ == '__main__':
  from sys import argv
  args = argv[1:]
  tplt_path = args.pop(0)
  sources = args
  out_tree = apply_rdfa_template(tplt_path, sources)
  print etree.tostring(out_tree, pretty_print=True)

