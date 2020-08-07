-- Meta
project = "Modules"
description = "Another dependency loader for Roblox"
title = "Modules Documentation"

-- 
format = "markdown"
file = {
	"src"
}
dir = "ldoc-build"

--
use_markdown_titles = true
no_summary = false
no_space_before_args = true
not_luadoc = true

-- LDoc extensions
new_type("event", "Events")
new_type("staticfield", "Static Fields", false)
new_type("staticfunction", "Static Functions")
alias("property", "field")
alias("subclass", "see")
alias("private", "local")

custom_tags = {
	{'constructor', title='Constructor', hidden=true};
	{'remark', title='Remark', hidden=false};
	--{'warning',title='Warning',hidden=false};
	{'superclass', title='Superclass', hidden=false};
	{'abstract', title='Abstract', hidden=false};
}
