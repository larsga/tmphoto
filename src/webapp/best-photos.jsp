<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>

<template:insert template='template.jsp'>
<template:put name='title'>
The best photos
</template:put>

<template:put name="body">

<p>This page shows the photos with the highest average scores,
computed from all votes by all users. Feel free to record your own
votes (click on the photo to do so), for example if you disagree with
the rankings here. All votes are welcome.</p>

<%
  int n = 1;
  if (request.getParameter("n") != null)
    n = Integer.parseInt(request.getParameter("n"));
  int offset = (n - 1) * 50;
  int pages = ScoreManager.getPhotosWithVotesCount() / 50;
  if (pages > 10)
    pages = 10;
%>

<tolog:set var="paging">
<%
  if (pages > 1) {
%>
<p>
<%
    if (n > 1) {
%>
      <a href="best-photos.jsp?n=<%= n-1 %>"><img src="nav_prev.gif" border="0"></a>
<%
    }
    for (int ix = 1; ix <= pages; ix++) {
      if (ix == n) {
%>
        <b><%= ix %></b>
<%
      } else {
%>
        <a href="best-photos.jsp?n=<%= ix %>"><%= ix %></a>
<%
      }
    }
    if (n < pages) {
%>
      <a href="best-photos.jsp?n=<%= n+1 %>"><img src="nav_next.gif" border="0" alt="Next"></a>
<%
    }
  }  
%>
</tolog:set>

<tolog:out var="paging" escape="false"/>
<table>
<%
  Iterator it = ScoreManager.getBestPhotos(offset).iterator();
  while (it.hasNext()) {
    ScoreManager.PhotoInList data = (ScoreManager.PhotoInList) it.next();
    pageContext.setAttribute("photodata", data);
    String query = "$T = " + data.getPhotoId() + "?";
%>
<tolog:set var="photo" query="<%= query %>"/>

<tolog:query name="check">
  ph:time-taken(%photo%, $TIME),
  ph:taken-at(%photo% : op:Image, $PLACE : op:Place)
  <tolog:if var="nouser">,
    not(ph:hide(%photo% : ph:hidden)),
    not(ph:hide($PLACE : ph:hidden)),
    not(ph:depicted-in(%photo% : ph:depiction, $PERSON : ph:depicted),
        ph:hide($PERSON : ph:hidden))
  </tolog:if>?
</tolog:query>
<tolog:if query="check">
<tr><td>
<a href="photo.jsp?id=<tolog:id var="photo"/>"><img src="<%= pageContext.getServletContext().getInitParameter("photo-server") %><tolog:id var="photo"/>;thumb" border="0"></a>

<td valign=top><span style="font-size: 75%"><tolog:out var="photo"/><br>

<a href="place.jsp?id=<tolog:id var="PLACE"/>"><tolog:out var="PLACE"/></a><br>
<tolog:out query="ph:time-taken(%photo%, $DATE)?"/><br>
Score: <c:out value="${photodata.score}"/><br>
Votes: <c:out value="${photodata.votes}"/><br>
</tolog:if>

<% } %>
</table>

<tolog:out var="paging" escape="false"/>
</template:put>
</template:insert>
</tolog:context>
