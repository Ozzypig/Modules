import re

from jinja2 import Markup, environmentfilter

def uri_fragment(s):
	return s.replace('[^a-zA-Z_-/?]', '')

def anchor_here(s):
	return Markup('<div id="-{}"></div>'.format(uri_fragment(s)))

lua_types = (
	'nil', 'boolean', 'number', 'string', 'function', 'userdata', 'table',
	'...', 'float', 'double', 'integer', 'bool', 'array', 'dictionary'
)
roblox_doc = 'https://developer.roblox.com/api-reference/'
lua_manual = 'https://www.lua.org/manual/5.1/manual.html'

@environmentfilter
def xref_link(env, api_name):
	if api_name[0:4] == 'rbx:':
		api_name = api_name[4:]
		text = api_name
		if api_name[0:9] == 'datatype/':
			text = api_name[9:]
		elif api_name[0:5] == 'enum/':
			text = api_name[5:]
		elif api_name[0:6] == 'class/':
			text = api_name[6:]
		return (text, roblox_doc + api_name)
	elif api_name in lua_types:
		return (api_name, lua_manual)

	raw_data = env.globals['ldoc'].get(api_name)
	if raw_data:
		# Determine what md file we should cross-reference
		md_file = api_name + '.md'
		if 'refmod' in raw_data:
			md_file = env.globals['ldoc'][raw_data['refmod']]['name'] + '.md'
		target = md_file
		if 'refanchor' in raw_data:
			target += '#-' + uri_fragment(raw_data['refanchor'])
		return (api_name, target)
	else:
		raise Exception('unknown xref: ' + api_name)

@environmentfilter
def xref(env, text):
	text, target = xref_link(env, text)
	return '[{text}]({target})'.format(
		text=text,
		target=target
	)

@environmentfilter
def xref_to(env, text, api_name):
	return '[{text}]({target})'.format(
		text=text,
		target=xref_link(env, api_name)
	)

# These regular expressions parse out LDoc-style cross references
# For example @{Module} or @{Module|text}
_re_xref_with_text = re.compile(r'@{(?P<api_name>[^\}\|]+)\|(?P<text>[^}]+)}')
_re_xref =           re.compile(r'@{(?P<api_name>[^\}]+)}')

"""Jinja2 filter which transforms LDoc-style cross-references into Markdown links appropriate for mkdocs"""
@environmentfilter
def ldoc_filter(env, s):
	def repl(match):
		d = match.groupdict()
		api_name = d['api_name']

		raw_data = env.globals['ldoc'].get(api_name)

		text = d.get('text', api_name)

		try:
			_, target = xref_link(env, api_name)
			return '[{text}]({target})'.format(text=text, target=target)
		except:
			return '{} (xref: \"{}\")'.format(text, api_name)

	s = _re_xref_with_text.sub(repl, s)
	s = _re_xref.sub(repl, s)
	return Markup(s)

filters = {
	'anchor_here': anchor_here,
	'xref': xref,
	'xref_link': xref_link,
	'xref_to': xref_to,
	'ldoc': ldoc_filter,
}
