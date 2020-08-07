"""
	LDoc2MkDocs
"""

import os
import json

from pathlib import Path
from jinja2 import Environment, FileSystemLoader

from .filters import filters

class LDoc2MkDocs:

	def __init__(self, doc_json_path, out_path, templates_dir_path, pretty=False):
		self.doc_json_path = doc_json_path
		self.out_path = out_path
		self.pretty = pretty
		self.pretty_path = out_path / 'docs.pretty.json'
		self.templates_dir_path = templates_dir_path

		self.env = Environment(
			loader=FileSystemLoader(str(self.templates_dir_path)),
			autoescape=False
		)
		for filter_name in filters.keys():
			self.env.filters[filter_name] = filters[filter_name]

		self.api_path = out_path / 'api'

	def convert(self):
		# Load JSON from file
		doc_data = self.read_doc_json()

		# Write a pretty version to file, for debugging
		if self.pretty:
			self.write_pretty_json(doc_data)

		# Build various globals
		self.env.globals['ldoc_raw'] = doc_data
		self.env.globals['ldoc'] = self.process_ldoc_entries(doc_data)

		# Create a path for API md files
		self.api_path.mkdir(exist_ok=True)

		# Convert entries into markdown
		for entry in doc_data:
			self.entry_to_md(entry, self.api_path / (entry['name'] + '.md'))

	def process_ldoc_entries(self, doc_data):
		ldocEntriesByName = dict()
		for entry in doc_data:
			ldocEntriesByName[entry['name']] = entry
			for item in entry['items']:
				item['refmod'] = entry['name']
				item['refanchor'] = item['name']
				ldocEntriesByName[item['name']] = item
				if not (':' in item['name'] or '.' in item['name']):
					fqName = entry['name'] + (':' if entry['type'] == 'classmod' and item['type'] not in ('staticfunction',) else '.') + item['name']
					if fqName not in ldocEntriesByName:
						ldocEntriesByName[fqName] = item
		return ldocEntriesByName

	def read_doc_json(self):
		with open(str(self.doc_json_path), 'r') as f:
			return json.loads(f.read())

	def write_pretty_json(self, data):
		with open(str(self.pretty_path), 'w') as f:
			f.write(json.dumps(data, indent='\t'))
		print('Wrote indented json to: ' + str(self.pretty_path))

	def entry_to_md(self, entry, filepath):
		with open(str(filepath), 'w') as f:
			f.write(self.choose_entry_template(entry).render({
				'entry': entry
			}))

	def choose_entry_template(self, entry):
		return self.env.get_template('template.md')

