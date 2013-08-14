<h1>DRAFT DRAFT DRAFT DRAFT</h1>

aco-mets
---

<h4>description:</h4>
 * This git repository is part of the Arabic Collections Online (ACO) Project. It is a work space to refine the METS document structures that will be used to transmit digital objects from Princeton University Libraries to New York University Libraries.

 
<h4>cases:</h4>
 * Multiple physical volumes will be digitized during the ACO project. In most cases, intellectual entities and physical volumes will align in a one-to-one relationship, however, we want to support intellectual entities that are bound with other intellectual entities in a single physical volume, and intellectual entities that span multiple physical volumes. To expand the applicability of the mapping strategy to non-text objects, e.g., audio, video, the term "source entity" is used.
<table>
<tr><th>entity type</th><th>intellectual entity count</th><th>source entity count</th><th>comments</th></tr>
<tr><td>ONE_TO_ONE_ENTITY</td><td>1</td><td>1</td><td>one intellectual entity bound in a single physical volume that does not contain any other intellectual entities.<br />this is the common case.</td></tr>
<tr><td>SOURCE_ENTITY</td><td>N</td><td>1</td><td>&gt; 1 intellectual entities bound in a single physical volume.</td></tr>
<tr><td>INTELLECTUAL_ENTITY</td><td>1</td><td>&lt; 1 or &gt; 1</td><td>used when the ONE_TO_ONE_ENTITY criteria are not met, i.e., the intellectual entity spans multiple source entities, or the intellectual entity is wholly contained in a portion of a source entity.</td></tr>
</table>
	
<h4>contents:</h4>
 * this repository contains METS documents for imaginary source and intellectual entities.
 * one-to-one entity example:
   * princeton\_book456
 * source entity example:
   * princeton\_book123
 * intellectual entity examples:
   * princeton\_ie987
   * princeton\_ie989


<h4>controlled terms:</h4>
 * entity types:
   * ONE\_TO\_ONE_ENTITY
   * SOURCE\_ENTITY
   * INTELLECTUAL\_ENTITY
 * digital object types:
   * TEXT
     * N.B. 'TEXT' is the only digital object type that will be used for the ACO project.
   * ETEXT
   * AUDIO
   * VIDEO
   * IMAGE\_REFLECTIVE
   * IMAGE\_TRANSMISSIVE
   * IMAGESET\_REFLECTIVE
   * IMAGESET\_TRANSMISSIVE
 * METS structMap div types:
   * INTELLECTUAL\_ENTITY
     * defines the boundaries of a discrete intellectual entity in a source entity
   * LOGICAL\_SECTION
     * used for chapter boundaries, etc.
 * binding orientation
   * VERTICAL
   * HORIZONTAL
 * scan order
   * LEFT\_TO\_RIGHT
   * RIGHT\_TO\_LEFT
   * TOP\_TO\_BOTTOM
   * BOTTOM\_TO\_TOP
 * read order
   * LEFT\_TO\_RIGHT
   * RIGHT\_TO\_LEFT
   * TOP\_TO\_BOTTOM
   * BOTTOM\_TO\_TOP
 * page location
   * LEFT
   * RIGHT
   * TOP
   * BOTTOM
   * _N.B. page location is independent of read order, and therefore different from recto/verso._
 * page types
   * PAGE
     * a numbered page
   * INSERT
     * a non-integral insert, e.g., a bookmark
   * UNNUMBERED
     * an integral insert, e.g., plates
   * PAGE_ALT
     * an alternate view of the page, e.g., an image of the page with non-integral insert overlaying text
   * PAGE\_MISSING
     * used to indicate missing pages
   * PAGE\_DEFECTIVE
     * a page with known defects, e.g., printing error, torn, defaced
   * OVERSIZED
     * a page that cannot be imaged in a single photograph and therefore has multiple master images
    
<h4>terms</h4>
* intellectual entity
  * "Intellectual Entity — a coherent unit of digital content which make up a single unit, e.g. the digitised pages of a book, or the complete set of files which make up a web page. Intellectual Entities can contain other Intellectual Entities. An Intellectual Entity can have one or more Digital Representation — the same content with different file formats, structures or functionalities, e.g. digital images in both TIFF and JPEG formats. Although defined in the data model, Intellectual Entity is regarded as out of scope for metadata specifications", from : <a href="http://www.dcc.ac.uk/resources/briefing-papers/standards-watch-papers/premis-data-dictionary">http://www.dcc.ac.uk/resources/briefing-papers/standards-watch-papers/premis-data-dictionary</a> , accessed 2013-08-07
  
* volume
  * "...In the physical sense, all the written or printed matter contained in a single binding, portfolio, etc., as originally issued or bound subsequent to issue (AACR2). Often used synonymously, in this sense, with book...", <a href="http://www.abc-clio.com/ODLIS/odlis_v.aspx">http://www.abc-clio.com/ODLIS/odlis_v.aspx</a>, accessed 2013-08-07

