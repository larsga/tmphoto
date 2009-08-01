<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:set var="year"><%= request.getParameter("year") %></tolog:set>
<tolog:set var="topicmap" query="topicmap($TM)?"/>
<%
 request.setAttribute("filter", new FilterContext(pageContext));

 String sortby = request.getParameter("sort");
 if (sortby == null)
   sortby = "time";
%>

<template:insert template='template.jsp'>
<template:put name='title'>
<tolog:out var="year"/>
</template:put>

<template:put name="body">

<c:if test="${filter.set}">
  <p>Filtered by: <b><c:out value="${filter.label}"/></b>
    (<a href="unset.jsp?attr=filter">Remove filter</a>)
  </p>
</c:if>

<p>Sort by:
<% if (sortby.equals("time")) { %>
  <b>Time</b> | <a href="year.jsp?year=<tolog:out var="year"/>&sort=score">Score</a>
<% } else { %>
  <a href="year.jsp?year=<tolog:out var="year"/>">Time</a> | <b>Score</b>
<% } %></p>

<!-- PICTURES -->
<table width="100%">
<tr><td>

<tolog:set var="query">
  ph:time-taken($PHOTO, $TIME),
  str:starts-with($TIME, %year%),
  ph:taken-at($PHOTO : op:Image, $PLACE : op:Place)
  <% if (sortby.equals("score")) { %>
    , ph:vote-score($PHOTO, $AVG)
  <% } %>
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
  String sort;
  if (sortby.equals("time"))
    sort = "$TIME";
  else
    sort = "$AVG desc";
  FilteredList list = new FilteredList(pageContext, query, sort, "PHOTO",
                                       "year");
  request.setAttribute("list", list);
%>

<c:set var="pagelink">year.jsp?year=<tolog:out var="year"/><%
  if (sortby.equals("score")) { %>&sort=score<% } %></c:set>
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

<tr><td colspan=2><div class="hidden"
        id="f<tolog:oid var="filter.type"/>">
<table width="100%">
<c:forEach items="${filter.counters}" var="counter">
<tr><td>
<a href="set-filter.jsp?id=<tolog:out var="counter.id"/>" rel="nofollow"
          ><tolog:out var="counter.label"/></a>
    <td><tolog:out var="counter.count"/>
</c:forEach>
</table>
</div>
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
