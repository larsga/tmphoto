<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>
<%
  String user = request.getParameter("user");
%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>

<template:insert template='template.jsp'>
<template:put name='title'>
<%= user %>'s favourites
</template:put>

<template:put name="body">

<p>This page shows the photos that <%= user %> have rated the highest.</p>

<%
  int n = 1;
  if (request.getParameter("n") != null)
    n = Integer.parseInt(request.getParameter("n"));
  int offset = (n - 1) * 50;
  int pages = 10; // shit
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
      <a href="?user=<%= user %>&n=<%= n-1 %>"><img src="nav_prev.gif" border="0"></a>
<%
    }
    for (int ix = 1; ix <= pages; ix++) {
      if (ix == n) {
%>
        <b><%= ix %></b>
<%
      } else {
%>
        <a href="?user=<%= user %>&n=<%= ix %>"><%= ix %></a>
<%
      }
    }
    if (n < pages) {
%>
      <a href="?user=<%= user %>&n=<%= n+1 %>"><img src="nav_next.gif" border="0" alt="Next"></a>
<%
    }
  }  
%>
</tolog:set>

<tolog:out var="paging" escape="false"/>
<table>
<%
  Iterator it = ScoreManager.getUserFavourites(user, offset).iterator();
  while (it.hasNext()) {
    ScoreManager.PhotoInList data = (ScoreManager.PhotoInList) it.next();
    pageContext.setAttribute("photodata", data);
    String query = "$T = " + data.getPhotoId() + "?";
%>
<tolog:set var="photo" query="<%= query %>"/>

<tolog:query name="check">
  occ:last-modified-at(%photo%, $TIME),
  ph:taken-at(%photo% : ph:photo, $PLACE : ph:location)
  <tolog:if var="nouser">,
  not(ph:hide(%photo% : ph:photo)),
  not(ph:hide($PLACE : ph:photo)),
  not(ph:depicted-in(%photo% : ph:photo, $PERSON : ph:object),
      ph:hide($PERSON : ph:photo))
  </tolog:if>?
</tolog:query>
<tolog:if query="check">
<tr><td>
<a href="photo.jsp?id=<tolog:id var="photo"/>"><img src="<%= pageContext.getServletContext().getInitParameter("photo-server") %><tolog:id var="photo"/>;thumb" border="0"></a>

<td valign=top><span style="font-size: 75%"><tolog:out var="photo"/><br>

<a href="place.jsp?id=<tolog:id var="PLACE"/>"><tolog:out var="PLACE"/></a><br>
<tolog:out query="occ:last-modified-at(%photo%, $DATE)?"/><br>
Score: <c:out value="${photodata.score}"/><br>
</tolog:if>

<% } %>
</table>

<tolog:out var="paging" escape="false"/>
</template:put>
</template:insert>
</tolog:context>
