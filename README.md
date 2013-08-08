# Liquid template engine

## Original Doc

Original doc can be found here: https://github.com/Shopify/liquid

## Changes in this fork

## Important: no longer supported tags:
The following tags are no longer supported. Support for them is easy to add in, it's just that we never use them, and I am lazy. =D

* unless
* case
* cycle
* for loop
* tables (tablerow)
* ifchanged
* variable assignment
  * variable assignments are generally fine if they are not assigned anywhere in the same template. Re-assignment is not supported, it may cause unpredictable behavior
