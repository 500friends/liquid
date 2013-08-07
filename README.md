# Liquid template engine

## Original Doc

Original doc can be found here: https://github.com/Shopify/liquid

## Changes in this fork

The original functionality of parsing and render methods are untouched and perform as expected. 

In this fork I added functionalities to render with variables and sections separated. Variables become separate substitution hash, and "if" conditionals becomes sections. It is to adapt specifically to sendgrid apis, but they should be applicable to other mass email providers, where variables and sections are much more preferred way to send mass emails.

The entry point is template.render_with_substitution method. Variables that are separated needs to match template.separate_variable_regex. 

Nested conditionals are tricky, because sendgrid does not support nested sections (and I think for good reason too). However that means we have to go down each code path properly and extract out the unneeded sections as empty string. More detail in if.rb file.  

Modifications to this path may be confusing at first. I strongly suggest you read all the comments, play with it, and follow the code path through before making modifications. 

## Important: no longer supported tags:

The following tags are no longer supported in the new approach. Support for most of them is easy to add in, it's just that we never use them, and I am lazy. =D
The original render method still supports everything. These only apply to the new approach

* break/continue
* unless
* case
* raw
* cycle
* for loop
* tables (tablerow)
* ifchanged
* variable assignment
