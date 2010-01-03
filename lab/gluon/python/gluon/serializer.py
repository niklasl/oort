# -*- coding: UTF-8 -*-
from rdflib.syntax.serializers import Serializer
from gluon import GluonProfile
from gluon.deps import json
from rdflib.term import URIRef, Literal, BNode


class GluonSerializer(Serializer):
    def __init__(self, store):
        super(GluonSerializer, self).__init__(store)

    def serialize(self, stream, base=None, encoding=None, **args):
        raise NotImplementedError


# TODO: reuse rdflib things, e.g. RecursiveSerializer, used-qname-checking..
def to_tree(graph, profile=None, lang=None, base=None):

    # FIXME: make sure to use/update prefixes for created curies!
    if not profile:
        prefixes = dict((pfx, unicode(ns))
                for (pfx, ns) in graph.namespaces() if pfx)
        profile_data = {'prefix': prefixes}
        token_for_uri = lambda uri: _qname(graph, uri)
    else:
        profile_data = profile.source
        token_for_uri = lambda uri: profile.token_for_uri(uri) or _qname(graph, uri)

    tree = {'profile': profile_data}
    if lang: tree['lang'] = lang
    if base: tree['base'] = base

    # TODO: switch to "resources" if configured or non-reffed bnodes occur
    linked = {}
    nodes = []

    for s in graph.subjects():
        state = graph, profile, token_for_uri, lang
        current = _subject_to_data(state, s)
        if isinstance(s, URIRef):
            linked[unicode(s)] = current
        else:
            # only unreferenced..
            if not any(graph.subjects(None, s)):
                nodes.append(current)

    if linked:
        tree['linked'] = linked
    if nodes:
        tree['nodes'] = nodes
    return tree

def _subject_to_data(state, s):
    graph, profile, token_for_uri, lang = state
    current = {}
    p_os = {}
    for p, o in graph.predicate_objects(s):
        os = p_os.setdefault(p, [])
        os.append(o)
    for p, os in p_os.items():
        repr_value = lambda o: _to_raw_value(state, o)
        dfn = profile.definitions.get(unicode(p)) if profile else None
        if dfn:
            p_key = dfn.token
            if dfn.many is None:
                many = not _has_one_literal(os)
            else:
                many = dfn.many
            if dfn.reference:
                repr_value = lambda o: unicode(o)
            elif dfn.symbol:
                repr_value = lambda o: token_for_uri(o)
            elif dfn.localized:
                repr_value = (lambda o:
                        unicode(o) if o.language == lang
                        else _to_raw_value(state, o))
            elif dfn.datatype:
                repr_value = (lambda o:
                        unicode(o)
                        if unicode(o.datatype) == dfn.datatype_uri
                        else _to_raw_value(state, o))
        else:
            p_key = token_for_uri(p)
            many = not _has_one_literal(os)

        if _has_lang_literal(os):
            obj = {}
            for o in os:
                if not isinstance(o, Literal):
                    obj = None
                    break
                elif '@'+o.language in obj:
                    # TODO: multiple same-lang in list for lang-key
                    obj = None
                    break
                v = repr_value(o)
                if isinstance(v, dict):
                    obj.update(v)
            if obj is None:
                obj = [repr_value(o) for o in os]

        if not many:
            obj = repr_value(os[0])
        else:
            obj = [repr_value(o) for o in os]

        current[p_key] = obj

    return current

def _qname(graph, uri):
    pfx, ns, lname = graph.compute_qname(uri)
    return "%s:%s" % (pfx, lname)

def _has_lang_literal(items):
    return any(item.language for item in items if isinstance(item, Literal))

def _has_one_literal(items):
    return (len(items) == 1 and isinstance(items[0], Literal))

def _to_raw_value(state, o):
    graph, profile, token_for_uri, lang = state
    if isinstance(o, BNode):
        return _subject_to_data(state, o)
    if isinstance(o, URIRef):
        return {'$ref': unicode(o)}
    else:
        v = unicode(o)
        if o.language:
            return {'@'+o.language: v}
        elif o.datatype:
            return { '$datatype': _qname(graph, o.datatype),
                '$value': v }
            return {'$ref': v}
        else:
            return v


