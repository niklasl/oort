from os import path as p
from glob import glob
from StringIO import StringIO
from lxml import etree
try:
    from rdflib import ConjunctiveGraph
    from rdflib.compare import to_isomorphic, graph_diff
    def isograph(doc):
        g = ConjunctiveGraph().parse(data=etree.tostring(doc))
        return to_isomorphic(g)
except ImportError:
    isograph = None


_herepath = lambda *parts: p.normpath(p.join(p.dirname(__file__), *parts))

GRIT_XSLT = etree.XSLT(etree.parse(_herepath("rdfxml-grit.xslt")))
GRDDL_XSLT = etree.XSLT(etree.parse(_herepath("grit-grddl.xslt")))


def canonical_str(doc):
    return etree.tostring(doc, pretty_print=True)
    #output = StringIO()
    #doc.write_c14n(output)
    #return output.getvalue()

def run_grit_test(rdfxml_fpath, grit_fpath):
    rdfxml = etree.parse(rdfxml_fpath)
    speced_grit = etree.parse(grit_fpath)
    actual_grit = GRIT_XSLT(rdfxml)
    assert canonical_str(actual_grit) == canonical_str(speced_grit), \
            "Grit from <%s> doesn't equal specified result in <%s>" % (
                    rdfxml_fpath, grit_fpath)
    if not isograph:
        return
    gleaned_rdf = GRDDL_XSLT(speced_grit)
    gleaned_graph = isograph(gleaned_rdf)
    ref_graph = isograph(rdfxml)
    diff = lambda: "\nOnly in gleaned:%s\nOnly in spec:%s\n" % tuple(
                 "\n".join(
                    sorted(g.serialize(format='nt').splitlines()) )
                for g in graph_diff(gleaned_graph, ref_graph)[1:] )
    assert gleaned_graph == ref_graph, \
            "RDF from GRDDL:ed <%s> doesn't equal original RDF. Diff: %s" % (
                    grit_fpath, diff())

def file_pairs(testdir=None):
    testdir = testdir or _herepath('..','..','etc','grit','examples')
    for grit_fpath in glob(p.join(testdir, '*.xml')):
        rdfxml_fpath = grit_fpath.replace('.xml', '.rdf')
        if not p.exists(rdfxml_fpath):
            continue
        yield rdfxml_fpath, grit_fpath

def run_tests():
    for paths in file_pairs():
        try:
            run_grit_test(*paths)
            print "Ok.", paths
        except Exception, e:
            print "Error:",
            print e

if __name__ == '__main__':
    run_tests()

