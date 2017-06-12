Settings files must be in CSV format.
Any values which contain double-quotes must be escaped (Excel does this automatically on save).

--------------------------------------------

Settings files must have the following columns:

Tag
Xpath
Attribute
Token
NewValue

--------------------------------------------

Tag:
This creates a tag for the script and tokenizer.

Tag Scenarios:
	Configuration File - tag="Some-Tag-Name", and allowBlankSettings="false"
	The tokenizer will only evaluate rows with "Some-Tag-Name". No blank rows will be included.

	Configuration File - tag="Some-Tag-Name", and allowBlankSettings="true"
	The tokenizer will apply the matching tag and blank rows.

	Configuration File - tag="", and allowBlankSettings="true" or allowBlankSettings="false"
	The tokenizer will completely ignore all tagging.

--------------------------------------------

Xpath:
This is how the tokenizer will identify the nodes to replace values in.
Standard Xpath applies.

--------------------------------------------

Attribute:
This is the attribute to replace in the node(s) identified by the Xpath column.

--------------------------------------------

Token:
This will be set in the attribute instead of NewValue if the script configuration has tokenmode="true" set.
When the script configuration has tokenmode="false", this column is completely ignored.

--------------------------------------------

NewValue:
What value the Attribute should have.

--------------------------------------------

