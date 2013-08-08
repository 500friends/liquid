# Liquid template engine

## Original Doc

Original doc can be found here: https://github.com/Shopify/liquid

## Changes in this fork
The original functionality of parsing and render methods are untouched and perform as expected. 

In this fork I added functionalities to render with variables and sections separated. Variables become separate substitution hash, and "if" conditionals becomes sections. It is to adapt specifically to sendgrid apis, but they should be applicable to other mass email providers, where variables and sections are much more preferred way to send mass emails.

The entry point is template.render_with_substitution method. Variables that are separated needs to match template.separate_variable_regex. 

Nested conditionals are tricky, because sendgrid does not support nested sections (and I think for good reason too). However that means we have to go down each code path properly and extract out the unneeded sections as empty string. More detail in if.rb file.  

## Important: no longer supported tags:
The following tags are no longer supported. Support for them is easy to add in, it's just that we never use them, and I am lazy. =D

* unless
* case
* cycle
* for loop
* tables (tablerow)
* ifchanged
* variable assignment
  * variable assignments are generally fine if they are not assigned anywhere again in the same template. Re-assignment is not supported. It is because I want to avoid unnecessary re-evaluation of variables. 
