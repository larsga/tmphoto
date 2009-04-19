<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:if var="nouser">
  <jsp:forward page="hidden.jsp"/>
</tolog:if>

<template:insert template='template.jsp'>
<template:put name='title'>
Recent votes
</template:put>

<template:put name="body">

<table>
<%
  Iterator it = ScoreManager.getRecentVotes().iterator();
  while (it.hasNext()) {
    ScoreManager.PhotoInList data = (ScoreManager.PhotoInList) it.next();
    pageContext.setAttribute("photodata", data);
    String query = "$T = " + data.getPhotoId() + "?";

    try {
%>
<tolog:set var="photo" query="<%= query %>"/>
<tr><td>
<a href="photo.jsp?id=<tolog:id var="photo"/>"><img src="<%= pageContext.getServletContext().getInitParameter("photo-server") %><tolog:id var="photo"/>;thumb" border="0"></a>

<td valign=top><span style="font-size: 75%"><tolog:out var="photo"/><br>
Score: <c:out value="${photodata.score}"/><br>
User: <c:out value="${photodata.user}"/>
<%
    } catch (net.ontopia.topicmaps.nav2.core.NavigatorRuntimeException e) {
      // means the photo was deleted
      // guess no output is needed
    }
 } %>
</table>

</template:put>
</template:insert>
</tolog:context>
