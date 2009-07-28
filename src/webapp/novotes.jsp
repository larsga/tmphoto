<%@ include file="declarations.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:if var="nouser">
  <jsp:forward page="hidden.jsp"/>
</tolog:if>

<template:insert template='template.jsp'>
<template:put name='title'>
Photos with no votes
</template:put>

<template:put name="body">

<!-- PICTURES -->
<table width="100%">

<tolog:foreach query="
  instance-of($PHOTO, op:Image),
  not(ph:vote-score($PHOTO, $SCORE)),
  ph:time-taken($PHOTO, $DATE)
order by $DATE limit 50?">
<tr><td>
<a href="photo.jsp?id=<tolog:id var="PHOTO"/>"><img src="<%= pageContext.getServletContext().getInitParameter("photo-server") %><tolog:id var="PHOTO"/>;thumb" border="0"></a>

<td valign=top><span style="font-size: 75%"><tolog:out var="PHOTO"/><br>
<tolog:if query="ph:taken-at($PLACE : op:Place, %PHOTO% : op:Image)?">
  <a href="place.jsp?id=<tolog:id var="PLACE"/>"><tolog:out var="PLACE"/></a><br>
</tolog:if>
<tolog:out var="DATE"/>
</tolog:foreach>

</table>
</template:put>
</template:insert>
</tolog:context>
