<%@ include file="declarations.jsp"%>
<%@ include file="randomclass.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>

<template:insert template='template.jsp'>
<template:put name='title'>
  Terms of Use
</template:put>

<template:put name="body">

<%-- LEFT-HAND CELL --%>
<table width="100%"><tr><td>

<p>This page describes the terms under which you may use all photos on
this site (www.garshol.priv.no/tmphoto). As long as you follow what is
set out here you do not need to ask for my permission, but I do
appreciate being notified, simply because I enjoy seeing my photos
used. If you want to use these photos under <em>other</em> terms, you
need to ask me first. My email address is larsga@garshol.priv.no.

<p>You may:

<ul>
  <li>copy these photos to your own site and use them in any context
  you wish,
  <li>scale, crop, and rotate the photos you use,
</ul>

<p>provided that:

<ul>
  <li>you credit me with a text like "photo(s): Lars Marius Garshol", and
  <li>each photo is a link to the corresponding photo.jsp URL on this
  site.
</ul>

<p>For an example of this done right, see <a
href="http://www.ballrogg.no/gallery.html">this page</a>.

<p>Note that there is also a way to get photos of certain subjects (at
the moment only people) automatically, through 
<a href="http://www.garshol.priv.no/blog/183.html">a web service</a>.</p>

<%-- RIGHT-HAND CELL --%>
<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<td>
<table align=right>
<tr><td>
<%@ include file="randomphoto.jsp"%>

<tr><td colspan=2>&nbsp;
</table>

</table> <%-- END --%>
</template:put>

</template:insert>
</tolog:context>
