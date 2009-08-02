<%@ include file="declarations.jsp"%>
<%@ include file="randomclass.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:set var="reifier" 
  query="select $TMT from topicmap($TM), reifies($TMT, $TM)?"/>
<c:set var="place" scope="session"/>
<c:set var="person" scope="session" value=""/>
<c:set var="category" scope="session" value=""/>
<c:set var="filter" scope="session" value=""/>

<template:insert template='template.jsp'>
<template:put name='title'>
<tolog:choose>
  <tolog:when var="reifier">
    <tolog:out var="reifier"/>
  </tolog:when>
  <tolog:otherwise>
    tmphoto gallery
  </tolog:otherwise>
</tolog:choose>
</template:put>

<template:put name="body">

<tolog:if var="reifier">
<tolog:if query="dc:creator(%reifier% : dcc:resource, $C : dcc:value)?">
<p>
 <b>Created by:</b> 
 <a href="person.jsp?id=<tolog:id var="C"/>">Lars Marius Garshol</a>
</p>
</tolog:if>

  <tolog:if query="dc:description(%reifier%, $DESC)?">
    <%= MarkdownUtils.format(pageContext, "DESC") %>
  </tolog:if>
</tolog:if>

<%-- LEFT-HAND CELL --%>
<table width="100%"><tr><td>

<p>
You can access the photos through lists of:
</p>

<%-- FIXME: this code can be simplified dramatically once issue 80 in
     Ontopia is fixed: http://code.google.com/p/ontopia/issues/detail?id=80 --%>
<table>
<tr><th><a href="people.jsp">People</a>
    <td>
<tolog:set var="T" query="select count($T) from instance-of($T, op:Person)?"/>
<tolog:choose>
  <tolog:when var="T">
    <tolog:out var="T"/>
  </tolog:when>
  <tolog:otherwise>0</tolog:otherwise>
</tolog:choose>
<tr><th><a href="places.jsp">Places</a>
    <td>
<tolog:set var="T" query="select count($T) from instance-of($T, op:Place)?"/>
<tolog:choose>
  <tolog:when var="T">
    <tolog:out var="T"/>
  </tolog:when>
  <tolog:otherwise>0</tolog:otherwise>
</tolog:choose>
<tr><th><a href="events.jsp">Events</a>
    <td>
<tolog:set var="T" query="select count($T) from instance-of($T, op:Event)?"/>
<tolog:choose>
  <tolog:when var="T">
    <tolog:out var="T"/>
  </tolog:when>
  <tolog:otherwise>0</tolog:otherwise>
</tolog:choose>
<tr><th><a href="categories.jsp">Categories</a>
    <td>
<tolog:set var="T" query="select count($T) from instance-of($T, op:Category)?"/>
<tolog:choose>
  <tolog:when var="T">
    <tolog:out var="T"/>
  </tolog:when>
  <tolog:otherwise>0</tolog:otherwise>
</tolog:choose>
<% if (has_comments) { %>
<tr><th><a href="best-photos.jsp">The best photos</a>
    <td>-
<% } %>
</table>

<tolog:set var="photos" query="instance-of($P, op:Photo)?"/>
<p>There are <%= SelectRandomly.count("photos", pageContext) %> photos
in the system altogether.</p>

<p>You can follow new photos through two RSS streams:

<ul>
  <li><a href="rss.jsp">The events feed</a>, which lists new events.
  <li><a href="rss-eventless.jsp">The eventless photos feed</a>, which
  lists new photos which are not taken during a specific events.
</ul>

<p>Note that you can <a href="terms.jsp">use photos from this site</a>
on your own site, if you wish.

<%-- RIGHT-HAND CELL --%>
<td>
<table align=right>
<tr><td>
<%@ include file="randomphoto.jsp"%>

<tr><td colspan=2>&nbsp;
</table>

</table> <%-- END --%>
</template:put>

</template:insert>
</tolog:context>
