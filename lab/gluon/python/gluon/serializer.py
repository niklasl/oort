# -*- coding: UTF-8 -*-
from rdflib.syntax.serializers import Serializer
from gluon import Profile
from gluon.deps import json
from rdflib.term import URIRef, Literal, BNode


class GluonSerializer(Serializer):
    def __init__(self, store):
        super(GluonSerializer, self).__init__(store)

    def serialize(self, stream, base=None, encoding=None, **args):
        raise NotImplementedError # TODO (+ profile kw..)


# TODO: reuse rdflib things, e.g. RecursiveSerializer, used-qname-checking..
def to_tree(graph, profile=None, lang=None, base=None):

    # FIXME: make sure to use/update prefixes for created curies!
    # .. that is, reasonably(?) create profile if none exists (from graph
    # prefixes), and always only use token_for_uri (not _qname)..
    # .. and also, check which prefixes are actually used..
    if not profile:
        prefixes = dict((pfx, text(ns))
                for (pfx, ns) in graph.namespaces() if pfx)
        profile_data = {'prefix': prefixes}
        token_for_uri = lambda uri: _qname(graph, uri)
    else:
        profile_data = profile.source
        token_for_uri = lambda uri: profile.token_for_uri(uri) or _qname(graph, uri)

    tree = {'profile': profile_data}
    if lang: tree['lang'] = lang
    if base: tree['base'] = base

    # TODO: Switch to "resources" if configured or non-reffed bnodes occur?
    # The 'resources' or 'linked'+(opt)'nodes' needs to be specified..
    linked = {}
    nodes = []
    use_linked_and_nodes = profile and profile.definitions

    state = graph, profile, token_for_uri, lang, base

    for s in set(graph.subjects()):
        current = _subject_to_data(state, s)
        s_value = resolve(text(s), base)
        if isinstance(s, URIRef):
            if use_linked_and_nodes:
                linked[s_value] = current
            else:
                current['$uri'] = s_value
                nodes.append(current)
        else: # only unreferenced..
            if not any(graph.subjects(None, s)):
                nodes.append(current)

    if use_linked_and_nodes:
        tree['linked'] = linked
        if nodes:
            tree['nodes'] = nodes
    else:
        tree['resources'] = nodes

    return tree

def _subject_to_data(state, s):
    graph, profile, token_for_uri, lang, base = state
    current = {}
    p_os = {}
    for p, o in graph.predicate_objects(s):
        os = p_os.setdefault(p, [])
        os.append(o)
    for p, os in p_os.items():
        repr_value = lambda o: _to_raw_value(state, o)
        dfn = profile.definitions.get(text(p)) if profile else None
        if dfn:
            p_key = dfn.token
            if dfn.many is None:
                many = not _has_one_literal(os)
            else:
                many = dfn.many
            if dfn.reference:
                repr_value = lambda o: resolve(text(o), base)
            elif dfn.symbol:
                repr_value = lambda o: token_for_uri(o)
            elif dfn.localized:
                repr_value = (lambda o:
                        text(o) if o.language == lang
                        else _to_raw_value(state, o))
            elif dfn.datatype:
                repr_value = (lambda o:
                        text(o)
                        if text(o.datatype) == dfn.datatype_uri
                        else _to_raw_value(state, o))
        else:
            p_key = token_for_uri(p)
            many = not _has_one_literal(os)

        obj = None
        if _has_lang_literal(os):
            obj = {}
            lang_many = False
            for o in os:
                lang_key = '@'+o.language
                if not isinstance(o, Literal):
                    obj = None
                    break
                elif lang_key in obj:
                    lang_many = True
                v = repr_value(o)
                if isinstance(v, dict):
                    if lang_many:
                        cur_v = obj.get(lang_key) or []
                        if not isinstance(cur_v, list):
                            obj[lang_key] = cur_v = [cur_v]
                        cur_v.append(v[lang_key])
                    else:
                        obj.update(v)

        if not many:
            obj = repr_value(os[0])
        elif not obj:
            obj = [repr_value(o) for o in os]

        current[p_key] = obj

    return current

def _to_raw_value(state, o):
    graph, profile, token_for_uri, lang, base = state
    # TODO: support for collections and rdf:_{i} forms (using '$list')
    if isinstance(o, BNode):
        return _subject_to_data(state, o)
    if isinstance(o, URIRef):
        return {'$ref': resolve(text(o), base)}
    else:
        v = text(o)
        if o.language:
            return {'@'+o.language: v}
        elif o.datatype:
            return {'$datatype': token_for_uri(o.datatype), '$value': v}
            return {'$ref': v}
        else:
            return v

def _qname(graph, uri):
    pfx, ns, lname = graph.compute_qname(uri)
    return "%s:%s" % (pfx, lname)

def _has_lang_literal(items):
    return any(item.language for item in items if isinstance(item, Literal))

def _has_one_literal(items):
    return (len(items) == 1 and isinstance(items[0], Literal))

def text(value, encoding='utf-8'):
    return value.encode(encoding)

def resolve(uri, base):
    return uri[len(base):] if base and uri.startswith(base) else uri

