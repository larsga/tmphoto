<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:set var="topicmap" query="topicmap($TM)?"/>

<template:insert template='template.jsp'>
<template:put name='title'>
The best photos
</template:put>

<template:put name="body">

<p>This page shows the photos with the highest average scores,
computed from all votes by all users. Feel free to record your own
votes (click on the photo to do so), for example if you disagree with
the rankings here. All votes are welcome.</p>

<!-- PICTURES -->
<tolog:set var="query">
  ph:vote-score($PHOTO, $AVG)
  <tolog:if var="nouser">
  ,
  not(ph:hide($PLACE : ph:hidden)),
  not(ph:hide($PHOTO : ph:hidden)),
  not(ph:depicted-in($OTHER : ph:depicted, $PHOTO : ph:depiction),
      ph:hide($OTHER : ph:hidden)),
  not(ph:taken-during($PHOTO : op:Image, $EVENT : op:Event),
      ph:hide($EVENT : ph:hidden))
  </tolog:if>
</tolog:set>
<%
  request.setAttribute("filter", new FilterContext(pageContext));
  String query = (String) ContextUtils.getSingleValue("query", pageContext);
  String sort = "$AVG desc limit 100";
  FilteredList list = new FilteredList(pageContext, query, sort, "PHOTO",
                                       "person");
  request.setAttribute("list", list);
%>

<c:set var="pagelink">best-photos.jsp</c:set>
<%@ include file="paging.jsp"%>

<tolog:out var="paging" escape="no"/>
<table>
<c:forEach items="${list.rows}" var="row"> 
  <c:set var="photo" value="${row.PHOTO}"/>
<%
  TopicIF photo = (TopicIF) pageContext.getAttribute("photo");
  ContextUtils.setSingleValue("photo", pageContext, photo);
%>
<tr><td>
<a href="photo.jsp?id=<tolog:id var="photo"/>"><img src="<%= pageContext.getServletContext().getInitParameter("photo-server") %><tolog:id var="photo"/>;thumb" border="0"></a>

<td valign=top><span style="font-size: 75%"><tolog:out var="photo"/><br>
<tolog:if query="ph:taken-at($PLACE : op:Place, %photo% : op:Image)?">
  <a href="place.jsp?id=<tolog:id var="PLACE"/>"><tolog:out var="PLACE"/></a><br>
</tolog:if>
<tolog:if query="ph:taken-during($EVENT : op:Event, %photo% : op:Image)?">
  <a href="event.jsp?id=<tolog:id var="EVENT"/>"><tolog:out var="EVENT"/></a><br>
</tolog:if>
<tolog:out query="ph:time-taken(%photo%, $DATE)?"/><br>
<tolog:if query="ph:vote-score(%photo%, $AVG)?">
  <tolog:out var="AVG"/><br>
</tolog:if>

</c:forEach>

</table>

<tolog:out var="paging" escape="no"/>
</template:put>
</template:insert>
</tolog:context>
