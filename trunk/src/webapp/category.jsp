<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>
<%@ include file="remove-filter.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:set var="category"  reqparam="id"/>
<tolog:choose>
  <tolog:when var="category"> </tolog:when>
  <tolog:otherwise>
    <jsp:forward page="nosuch.jsp">
      <jsp:param name="what" value="category"/>
    </jsp:forward>
  </tolog:otherwise>
</tolog:choose>
<tolog:set var="topicmap" query="topicmap($TM)?"/>
<tolog:set var="filter"></tolog:set>
<c:if test='${sessionScope["filter"] != null && sessionScope["filter"] != ""}'>
  <tolog:query name="lookup">
    $T = <c:out value='${sessionScope["filter"]}'/>?
  </tolog:query>
  <tolog:set var="filter" query='lookup'/>
</c:if>
<c:set var="category" scope="session"><tolog:id var="category"/></c:set>
<c:set var="place" scope="session" value=""/>
<c:set var="person" scope="session" value=""/>
<%
 String sortby = request.getParameter("sort");
 if (sortby == null)
   sortby = "time";
%>

<template:insert template='template.jsp'>
<template:put name='title'>
<tolog:out var="category"/>

</template:put>

<template:put name="body">

<tolog:if var="filter">
  <p>Filtered by: <b><tolog:out var="filter"/></b>
    (<a href="unset.jsp?attr=filter">Remove filter</a>)
  </p>
</tolog:if>

<tolog:if query="dc:description(%category%, $DESC)?">
  <p><tolog:out var="DESC"/></p>
</tolog:if>

<p>Sort by:
<% if (sortby.equals("time")) { %>
  <b>Time</b> | <a href="category.jsp?id=<%= request.getParameter("id") 
                         %>&sort=score">Score</a>
<% } else { %>
  <a href="event.jsp?id=<%= request.getParameter("id") %>">Time</a> | <b>Score</b>
<% } %>

<!-- PICTURES -->
<p>
<table width="100%">
<tr><td>

<tolog:set var="query">
  ph:in-category(%category% : ph:categorization, $PHOTO : ph:categorized),
  ph:time-taken($PHOTO, $TIME),
  ph:taken-at($PHOTO : op:Image, $PLACE : op:Place)
  <% if (sortby.equals("score")) { %>
    , ph:vote-score($PHOTO, $AVG)
  <% } %>
  <tolog:if var="nouser">
  ,
  not(ph:hide($PHOTO : ph:hidden)),
  not(ph:depicted-in($PHOTO : ph:depiction, $PERSON : ph:depicted),
      ph:hide($PERSON : ph:hidden)),
  not(ph:taken-at($PHOTO : op:Image, $PLACE : op:Place),
      ph:hide($PLACE : ph:hidden)),
  not(ph:taken-during($PHOTO : op:Image, $EVENT : op:Event),
      ph:hide($EVENT : ph:hidden))
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
                                       "category");
  request.setAttribute("list", list);
%>

<c:set var="pagelink">category.jsp?id=<tolog:id var="category"/><%
  if (sortby.equals("score")) { %>&sort=score<% } %></c:set>
<%@ include file="paging.jsp"%>

<tolog:out var="paging" escape="no"/>
<table>
<c:forEach items="${list.rows}" var="row"> 
  <c:set var="photo" value="${row.PHOTO}"/>
<%
  TopicIF photo = (TopicIF) pageContext.getAttribute("photo");
  ContextUtils.setSingleValue("PHOTO", pageContext, photo);
%>
<tr><td>
<a href="photo.jsp?id=<tolog:id var="PHOTO"/>"><img src="<%= pageContext.getServletContext().getInitParameter("photo-server") %><tolog:id var="PHOTO"/>;thumb" border="0"></a>

<td valign=top><span style="font-size: 75%"><tolog:out var="PHOTO"/><br>
<tolog:if query="ph:taken-at($PLACE : op:Place, %PHOTO% : op:Image)?">
  <a href="place.jsp?id=<tolog:id var="PLACE"/>"><tolog:out var="PLACE"/></a><br>
</tolog:if>
<tolog:if query="ph:taken-during($EVENT : op:Event, %PHOTO% : op:Image)?">
  <a href="event.jsp?id=<tolog:id var="EVENT"/>"><tolog:out var="EVENT"/></a><br>
</tolog:if>
<tolog:out query="ph:time-taken(%PHOTO%, $DATE)?"/><br>
<tolog:if query="ph:vote-score(%PHOTO%, $AVG)?">
  <tolog:out var="AVG"/><br>
</tolog:if>

</c:forEach>
</table>
<tolog:out var="paging" escape="no"/>

<!-- FILTERS -->
<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<td>
<script>
function swap(id) {
  var elem = document.getElementById("f" + id);
  var link = document.getElementById("link" + id);
  var text = link.childNodes[0];
  if (elem.style.display == "none") {
    elem.style.display = "table-cell";    
    text.data = "-";
  } else {
    elem.style.display = "none";
    text.data = "+";
  }
}
</script>

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
<a href="set-filter.jsp?id=<tolog:id var="counter.topic"/>" rel="nofollow"
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
