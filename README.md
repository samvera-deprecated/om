[![Build Status](https://travis-ci.org/projecthydra/om.png?branch=master)](https://travis-ci.org/projecthydra/om)
[![Gem Version](https://badge.fury.io/rb/om.png)](http://badge.fury.io/rb/om)

# om (Opinionated Metadata)

A library to help you tame sprawling XML schemas like MODS.

OM allows you to define a "terminology" to ease translation between XML and ruby objects – you can query the xml for Nodes or node values without ever writing a line of XPath.

OM "terms" are ruby symbols you define (in the terminology) that map specific XML content into ruby object attributes.

## Tutorials & Reference

* [Tame Your XML with OM](https://github.com/projecthydra/om/wiki/Tame-your-XML-with-OM)
* [Common OM Patterns](https://github.com/projecthydra/om/blob/master/COMMON_OM_PATTERNS.md)

### Solrizing Documents

The solrizer gem provides support for indexing XML documents into Solr based on OM Terminologies.  
That process is documented in the [solrizer README](https://github.com/projecthydra/solrizer)

## OM in the Wild

We have a page on the Hydra wiki with a list of OM Terminologies in active use: 
[OM Terminologies in the Wild](https://wiki.duraspace.org/display/hydra/OM+Terminologies+in+the+Wild)

## Acknowledgments

### Creator

Matt Zumwalt ([MediaShelf](http://yourmediashelf.com))

### Thanks To

* Bess Sadler, who enabled us to take knowledge gleaned from developing Blacklight and apply it to OM metadata indexing
* Ross Singer
* Those who participated in the Opinionated MODS breakout session at Code4Lib 2010

## Copyright

Copyright (c) 2010 Matt Zumwalt. See LICENSE for details.
