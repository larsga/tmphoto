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
  <tolog:out var="reifier"/>
</template:put>

<template:put name="body">

<tolog:if query="dc:creator(%reifier% : dcc:resource, $C : dcc:value)?">
<p>
 <b>Created by:</b> 
 <a href="person.jsp?id=<tolog:id var="C"/>">Lars Marius Garshol</a>
</p>
</tolog:if>

<p>
  <tolog:out query="dc:description(%reifier%, $DESC)?"/>
</p>

<p>Note that photos showing many people and places are hidden for
privacy reasons. To see these you need to <a href="login.jsp">log
in</a>. To get a password you need to email me.  </p>

<p>You can read more about the application 
<a href="http://www.garshol.priv.no/blog/126.html">on my blog</a>.</p>

<%-- LEFT-HAND CELL --%>
<table width="100%"><tr><td>

<p>
You can access the photos through lists of:
</p>

<table>
<tr><th><a href="people.jsp">People</a>
    <td><tolog:out query="select count($T) from instance-of($T, op:Person)?"/>
<tr><th><a href="places.jsp">Places</a>
    <td><tolog:out query="select count($T) from instance-of($T, op:Place)?"/>
<tr><th><a href="events.jsp">Events</a>
    <td><tolog:out query="select count($T) from instance-of($T, op:Event)?"/>
<tr><th><a href="categories.jsp">Categories</a>
    <td><tolog:out query="select count($T) from instance-of($T, op:Category)?"/>
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
