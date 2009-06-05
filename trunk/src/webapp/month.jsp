<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:set var="month"><%= request.getParameter("month") %></tolog:set>
<tolog:set var="filter"  reqparam="filter"/>
<tolog:set var="topicmap" query="topicmap($TM)?"/>
<%
  String x = request.getParameter("n");
  int n = 1;
  if (x != null)
    n = Integer.parseInt(x);
%>
<c:set var="place" scope="session"/>
<c:set var="person" scope="session" value=""/>
<c:set var="category" scope="session" value=""/>
<c:set var="filter" scope="session" value=""/>

<template:insert template='template.jsp'>
<template:put name='title'>
<tolog:out var="month"/>
</template:put>

<template:put name="body">

<tolog:if var="filter">
  <p>Filtered by: <b><tolog:out var="filter"/></b>
    (<a href="?month=<tolog:out var="month"/>">Remove filter</a>)
  </p>
</tolog:if>

<!-- PICTURES -->
<table width="100%">
<tr><td>

<tolog:set var="query">
  ph:time-taken($PHOTO, $TIME),
  str:starts-with($TIME, %month%),
  ph:taken-at($PHOTO : op:Image, $PLACE : op:Place)
  <tolog:if var="nouser">
  ,
  not(ph:hide($PHOTO : ph:hidden)),
  not(ph:hide($PLACE : ph:hidden)),
  not(ph:depicted-in($PHOTO : ph:depiction, $PERSON : ph:depicted),
      ph:hide($PERSON : ph:hidden))
  </tolog:if>
</tolog:set>

<%
  String query = (String) ContextUtils.getSingleValue("query", pageContext);
  String sort = "$TIME";
  FilteredList list = new FilteredList(pageContext, query, sort, "PHOTO",
                                       "event");
  request.setAttribute("list", list);
  int pages = (list.getRowCount() / 50) + 1;
%>
<tolog:set var="paging">
<%
  if (pages > 1) {
%>
<p>
<%
    if (n > 1) {
%>
      <a href="month.jsp?month=<tolog:out var="month"/>&n=<%= n-1 %>"><img src="nav_prev.gif" border="0"></a>
<%
    }
    for (int ix = 1; ix <= pages; ix++) {
      if (ix == n) {
%>
        <b><%= ix %></b>
<%
      } else {
%>
        <a href="month.jsp?month=<tolog:out var="month"/>&n=<%= ix %>"><%= ix %></a>
<%
      }
    }
    list.setSlice((n-1) * 50, n * 50);
    if (n < pages) {
%>
      <a href="month.jsp?month=<tolog:out var="month"/>&n=<%= n+1 %>"><img src="nav_next.gif" border="0" alt="Next"></a>
<%
    }
  }  
%>
</tolog:set>

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
<tolog:out query="ph:time-taken(%photo%, $DATE)?"/><br>

</c:forEach>
</table>
<tolog:out var="paging" escape="no"/>


<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<td>
<!-- FILTERS -->
<c:forEach items="${list.filters}" var="filter">
<table width="100%" class=filterbox><tr><td>
<p><b>Filter by <tolog:out var="filter.type"/></b></p>
<td align=right><a href="javascript:swap('<tolog:oid var="filter.type"/>')"
                  ><b id="link<tolog:oid var="filter.type"/>">+</b></a>

<tr><td colspan=2 style="display: none" 
        id="f<tolog:oid var="filter.type"/>">
<table width="100%">
<c:forEach items="${filter.topics}" var="counter">
<tr><td>
<a href="month.jsp?month=<tolog:out var="month"/>&filter=<tolog:id var="counter.topic"/>" rel="nofollow"
          ><tolog:out var="counter.topic"/></a>
    <td><tolog:out var="counter.count"/>
</c:forEach>
</table>
</table>
</c:forEach>


</table>
</template:put>

<tolog:if var="filter">
  <template:put name="headertags">
    <meta name="robots" content="noindex,nofollow">
  </template:put>
</tolog:if>
</template:insert>
</tolog:context>
