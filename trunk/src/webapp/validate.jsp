<%@ include file="declarations.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:if var="nouser">
  <jsp:forward page="hidden.jsp"/>
</tolog:if>
<tolog:set var="topicmap" query="topicmap($TM)?"/>

<template:insert template='template.jsp'>
<template:put name='title'>
Validation report
</template:put>

<template:put name="body">

<!-- PICTURES -->
<table width="100%">

<tolog:foreach query="
  instance-of($PHOTO, ph:image),
  not(ph:taken-at($PHOTO : ph:photo, $PLACE : ph:location))?">
<tr><td>
<a href="photo.jsp?id=<tolog:id var="PHOTO"/>"><img src="<%= pageContext.getServletContext().getInitParameter("photo-server") %><tolog:id var="PHOTO"/>;thumb" border="0"></a>

<td valign=top><span style="font-size: 75%"><tolog:out var="PHOTO"/><br>
<tolog:if query="ph:taken-at($PLACE : ph:location, %PHOTO% : ph:photo)?">
  <a href="place.jsp?id=<tolog:id var="PLACE"/>"><tolog:out var="PLACE"/></a><br>
</tolog:if>
<tolog:out query="occ:last-modified-at(%PHOTO%, $DATE)?"/>
</tolog:foreach>

</table>
</template:put>
</template:insert>
</tolog:context>
