{% macro render_return_list(retvals) -%}
{%- if retvals: -%}
{%- for value in retvals: -%}
{%- if not loop.first: -%}, {%- endif -%}
{%- if 'type' in value: -%}
{{ value['type'] | xref }}
{%- endif -%}
{%- endfor -%}
{%- endif -%}
{%- endmacro -%}

{%- macro render_params(item) -%}
	{%- for param in item['paramsList'] -%}
		{%- set isOpt = false %}
		{%- if param in item['modifiers']['param'] -%}
			{%- set paramModifiers = item['modifiers']['param'][param] -%}
			{%- set isOpt = paramModifiers['opt'] -%}
			{%- if isOpt -%}\[{%- endif %}
			{%- if not loop.first -%}, {% endif -%}
			{%- if 'type' in paramModifiers -%}
				{%- set paramType = item['modifiers']['param'][param]['type'] -%}
				{%- if paramType[0] == '?' -%}
					{%- for paramType2 in paramType[1:].split('|') -%}
						{%- if not loop.first -%}/{%- endif -%}
						{{ paramType2 | xref }}
					{%- endfor -%}&nbsp;
				{%- else -%}
					{{ paramType | xref }}&nbsp;
				{%- endif -%}
			{%- endif -%}
		{%- else -%}
			{%- if not loop.first -%}, {% endif -%}
		{%- endif -%}
		`{{ param }}`
		{%- if isOpt -%}\]{%- endif %}
	{%- endfor -%}
{%- endmacro -%}

{%- macro render_item(item) %}

### {{ render_return_list(item['modifiers']['return']) }} `{{ item['name'] }}`{%- if item['type'] in ('event', 'function', 'staticfunction') -%}({{ render_params(item) }}){%- endif -%} {{ item['name'] | anchor_here }}

{%- if item['summary']: %}


{{ item['summary'] | trim | ldoc }}
{%- endif -%}
{%- if item['description']: %}


{{ item['description'] | trim | ldoc }}
{%- endif -%}

{%- endmacro -%}

{%- macro render_type(header, items, types) -%}
{%- for item in entry['items'] if item['type'] in types and not 'constructor' in item['tags'] -%}
{% if loop.first %}

## {{ header }}

{% endif %}
{{ render_item(item) }}
{%- endfor -%}
{%- endmacro -%}

# `{{ entry['name'] }}` {{ entry['name'] | anchor_here }}

{{ entry['description'] | ldoc }}

{%- for item in entry['items'] if item['type'] in 'staticfunction' and 'constructor' in item['tags'] -%}
{% if loop.first %}

## Constructors

{% endif %}
{{ render_item(item) }}
{%- endfor -%}

{{ render_type('Static Functions', entry['items'], ('staticfunction',))}}
{{ render_type('Fields', entry['items'], ('field','table'))}}
{{ render_type('Functions', entry['items'], ('function',))}}
{{ render_type('Events', entry['items'], ('event',))}}
