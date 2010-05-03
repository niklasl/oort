import os
from os import path as p
from StringIO import StringIO
from lxml import etree
from rdflib import ConjunctiveGraph
from rdfextras.tools.pathutils import guess_format
from paste.fileapp import DataApp, FileApp
from paste.httpexceptions import HTTPNotFound
from webob import Request

_herepath = lambda *parts: p.normpath(p.join(p.dirname(__file__), *parts))
GRIT_XSLT = etree.XSLT(etree.parse(_herepath("rdfxml-grit.xslt")))


def to_rdf_etree(sources):
    graph = ConjunctiveGraph()
    for source in sources:
        graph.load(source, format=guess_format(source))
    io = StringIO()
    graph.serialize(io, format="pretty-xml")
    io.seek(0)
    return etree.parse(io)


class WebApp(object):

    def __init__(self, filedir=""):
        self._sourcecache = {}
        self._filedir = filedir


    def __call__(self, environ, start_response):
        handler = self._get_handler(Request(environ))
        return handler(environ, start_response)

    def _get_handler(self, req):
        filepath = p.join(self._filedir, *req.path.split('/'))
        if not p.exists(filepath):
            return HTTPNotFound('The resource does not exist',
                    comment="Nothing at %r" % req.path).wsgi_application
        elif p.isfile(filepath):
            return FileApp(filepath)

        if not req.GET:
            return DataApp("""<!doctype html>
                <form>
                    <label>Data:
                        <textarea name="data" cols="42" rows="8"></textarea>
                    </label>
                    <p>
                        <label>
                            XSLT:
                            <input name="xslt" size="42" />
                        </label>
                    </p>
                    <p>
                        <label>
                            Cache:
                            <input type="checkbox" name="cache" />
                        </label>
                    </p>
                    <button type="submit">Run</button>
                </form>
                """, [('Content-Type', "text/html")])

        sources = tuple(sorted(os.path.expanduser(l)
                for l in req.GET['data'].splitlines()))

        grit_data = self._sourcecache.get(sources)
        if not grit_data:
            rdfxml = to_rdf_etree(sources)
            grit_data = GRIT_XSLT(rdfxml)
        if req.GET.get('cache') == 'on':
            self._sourcecache[sources] = grit_data
        else:
            self._sourcecache.clear()

        xslt_path = req.GET['xslt']
        xslt = etree.XSLT(etree.parse(xslt_path))
        mimetype = "text/html"
        output = etree.tostring(xslt(grit_data))

        return DataApp(output, [('Content-Type', mimetype)])


def serve_wsgi(app, port, servername=''):
    from wsgiref.simple_server import make_server
    httpd = make_server(servername, port, app)
    print "Serving HTTP on port %s..." % port
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    from optparse import OptionParser
    op = OptionParser(
            "%prog [-h] [...] ENDPOINT_URL BASEDIR")
    op.add_option('-p', '--port', type=int, default=8800,
            help="Port to serve as web app.")
    opts, args = op.parse_args()
    app = WebApp(filedir=os.getcwd())
    serve_wsgi(app, port=opts.port)

