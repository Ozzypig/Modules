"""
	ldoc2mkdocs.py

Usage: python ldoc2md.py DOCJSON OUTPATH

Converts a json file containing a dump of LDoc's raw data output into Markdown ready for mkdoc.
Uses Jinja2 templates to generate API doc pages from the

"""

from click import command, argument, option, format_filename, Path as click_Path
from pathlib import Path

from .LDoc2MkDocs import LDoc2MkDocs

templates_dir_path = Path(__file__).parent.parent / 'doc-templates'

@command(help='Convert a JSON file containing a dump of LDoc data into mkdocs-ready markdown files')
@argument('doc_json_path', type=click_Path(exists=True, file_okay=True, dir_okay=False, readable=True))
@argument('out_path', type=click_Path(exists=True, file_okay=False, dir_okay=True, writable=True))
@option('-p', '--pretty', is_flag=True, help='Should a prettified copy of the json file be output as well?')
def ldoc2mkdocs(doc_json_path, out_path, pretty):
	ldoc2mkdocs = LDoc2MkDocs(
		Path(doc_json_path),
		Path(out_path),
		templates_dir_path,
		pretty=pretty
	)
	ldoc2mkdocs.convert()

if __name__ == '__main__':
	ldoc2mkdocs()
