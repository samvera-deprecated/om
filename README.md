# om (Opinionated Metadata)

[![Version](https://badge.fury.io/rb/om.png)](http://badge.fury.io/rb/om)
[![CircleCI](https://circleci.com/gh/samvera/om.svg?style=svg)](https://circleci.com/gh/samvera/om)
[![Coverage Status](https://coveralls.io/repos/github/samvera/om/badge.svg?branch=master)](https://coveralls.io/github/samvera/om?branch=master)

Jump In: [![Slack Status](http://slack.samvera.org/badge.svg)](http://slack.samvera.org/)

# What is om?

A library to help you tame sprawling XML schemas like MODS.

OM allows you to define a "terminology" to ease translation between XML and ruby objects – you can query the xml for Nodes or node values without ever writing a line of XPath.

OM "terms" are ruby symbols you define (in the terminology) that map specific XML content into ruby object attributes.

## Product Owner & Maintenance
 **om** is a Core Component of the Samvera community. The documentation for
what this means can be found
[here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).
 ### Product Owner
 [Jon Cameron](https://github.com/joncameron)

## Tutorials & Reference

* [Tame Your XML with OM](https://github.com/samvera/om/wiki/Tame-your-XML-with-OM)
* [Common OM Patterns](https://github.com/samvera/om/blob/master/COMMON_OM_PATTERNS.md)

### Solrizing Documents

The solrizer gem provides support for indexing XML documents into Solr based on OM Terminologies.  
That process is documented in the [solrizer README](https://github.com/samvera/solrizer)

## Acknowledgments

### Creator

Matt Zumwalt (MediaShelf)

### Thanks To

* Bess Sadler, who enabled us to take knowledge gleaned from developing Blacklight and apply it to OM metadata indexing
* Ross Singer
* Those who participated in the Opinionated MODS breakout session at Code4Lib 2010

## Copyright

Copyright (c) 2010 Matt Zumwalt. See LICENSE for details.
