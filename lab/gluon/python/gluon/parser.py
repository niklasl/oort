# -*- coding: UTF-8 -*-
from __future__ import with_statement
from contextlib import closing
from rdflib.syntax.parsers import Parser
from gluon import Profile
from gluon.deps import json
from rdflib.graph import ConjunctiveGraph
from rdflib.term import URIRef, Literal, BNode


class GluonParser(Parser):
    def __init__(self):
        super(GluonParser, self).__init__()

    def parse(self, source, sink, profile=None, **args):
        with closing(source.getByteStream()) as f:
            tree = json.load(f)
            to_rdf(tree, sink, profile)


def to_rdf(tree, graph=None, profile_source=None):
    # TODO: determine profile from profile_source, or obj or ref in tree..
    profile = Profile(profile_source or tree.get('profile'))
    lang = tree.get('lang')
    base = tree.get('base')
    all_resources = _subject_data_pairs(tree.get('linked'),
            tree.get('resources'), tree.get('nodes'))

    graph = graph or ConjunctiveGraph()
    for pfx, uri in profile.prefixes.items():
        graph.bind(pfx, uri)

    for s, data in all_resources:
        subject = URIRef(s, base) if s else BNode()
        state = graph, profile, lang, base
        _populate_graph(state, subject, data)
    return graph

def _populate_graph(state, subject, data):
    graph, profile, lang, base = state
    for p, os in data.items():
        if p in ('$uri',):
            continue
        pred_uri = profile.uri_for_key(p)
        pred = URIRef(pred_uri)
        add_obj = lambda obj: graph.add((subject, pred, obj))
        dfn = profile.definitions.get(pred_uri)
        if not isinstance(os, list):
            os = [os]
        for o in os:
            if not isinstance(o, dict):
                if dfn and dfn.localized:
                    o = {'@'+lang: o}
                elif dfn and dfn.datatype:
                    o = {'$datatype': dfn.datatype, '$value': o}
                elif dfn and dfn.reference:
                    o = {'$ref': o}
                elif dfn and dfn.symbol:
                    o = {'$ref': profile.uri_for_key(o)}
                else:
                    add_obj(Literal(o))
                    continue
            if any(k.startswith('@') for k in o):
                for langkey, value in o.items():
                    values = value if isinstance(value, list) else [value]
                    for value in values:
                        obj = Literal(value, lang=langkey[1:])
                        add_obj(obj)
                continue
            elif '$datatype' in o:
                obj = Literal(o['$value'],
                        datatype=profile.uri_for_key(o['$datatype']))
            elif '$ref' in o:
                obj = URIRef(o['$ref'], base)
            else:
                obj = BNode()
                _populate_graph(state, obj, o)
            add_obj(obj)

def _subject_data_pairs(linked=None, *listed):
    if linked:
        for pair in linked.items():
            yield pair
    for l in listed:
        if not l:
            continue
        for data in l:
            yield data.get('$uri'), data


