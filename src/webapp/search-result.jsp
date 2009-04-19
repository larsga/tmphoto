<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>
<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<%
  String search = StringUtils.transcodeUTF8(request.getParameter("search"));
  String x = request.getParameter("n");
  int n = 1;
  if (x != null)
    n = Integer.parseInt(x);
%>
<tolog:set var="search"><%= search %></tolog:set>
<tolog:set var="topicmap" query="topicmap($TM)?"/>
<tolog:set var="filter"  reqparam="filter"/>

<template:insert template='template.jsp'>
<template:put name='title'>Search result</template:put>

<template:put name="body">

<form method=get action=search-result.jsp>
<input name=search size=50 style="font-size: 140%" value="<%= search %>">
<input type=submit value=Search style="font-size: 140%">
</form>

<tolog:set var="query">
  select $TOPIC, $REL from
    value-like($OBJ, %search%, $REL),
    { topic-name($TOPIC, $OBJ) | occurrence($TOPIC, $OBJ) }
  <tolog:if var="nouser">
    ,
    not(ph:hide($TOPIC : ph:hidden)),
    not(ph:taken-at($TOPIC : op:Image, $PLACE : op:Place),
        ph:hide($PLACE : ph:hidden)),
    not(ph:depicted-in($TOPIC : ph:depiction, $PERSON : ph:depicted),
        ph:hide($PERSON : ph:hidden)),
    not(ph:taken-during($TOPIC : op:Image, $EVENT : op:Event),
        ph:hide($EVENT : ph:hidden))
  </tolog:if>
</tolog:set>

<%
  String query = (String) ContextUtils.getSingleValue("query", pageContext);
  String sort = "$REL desc";
  FilteredList list = new FilteredList(pageContext, query, sort, "TOPIC",
                                       null);
  request.setAttribute("list", list);
  request.setAttribute("pages", list.getPageList());
%>

<%-- ================================================================= --%>
<tolog:set var="paging">
<c:if test="${pages.morePages}">
<c:if test="${pages.showBackButton}">
  <a href="?search=<%= search %>&n=<%= n-1 %>"><img src="resources/nav_prev.gif" border="0"></a>
</c:if>
<c:forEach items="${pages.pages}" var="page">
  <c:choose>
    <c:when test="${page.current}">
      <b><c:out value="${page.pageNumber}"/></b>
    </c:when>
    <c:otherwise>
      <a href="?search=<%= search %>&n=<c:out value="${page.pageNumber}"/>"><c:out value="${page.pageNumber}"/></a>
    </c:otherwise>
  </c:choose>
</c:forEach>
<c:if test="${pages.showNextButton}">
  <a href="?search=<%= search %>&n=<%= n+1 %>"><img src="resources/nav_next.gif" border="0"></a>
</c:if>
</c:if>
</tolog:set>
<%-- ================================================================= --%>

<table width="100%"><tr><td>

<tolog:out var="paging" escape="no"/>
<table>
<c:forEach items="${list.rows}" var="row">
  <tolog:query name="q1">
    $T = @<c:out value="${row.TOPIC.objectId}"/>?
  </tolog:query>
  <%--tolog:set var="topic" value="${row.TOPIC}"/--%>
  <tolog:set var="topic" query="q1"/>

  <tolog:choose>
    <tolog:when query="instance-of(%topic%, op:Image)?">
      <tr><td><a href="photo.jsp?id=<tolog:id var="topic"/>"
                ><tolog:out var="topic"/></a>
          <td>Photo
    </tolog:when>
    <tolog:when query="instance-of(%topic%, op:Person)?">
      <tr><td><b><a href="person.jsp?id=<tolog:id var="topic"/>"
                ><tolog:out var="topic"/></a></b>
          <td>Person
    </tolog:when>
    <tolog:when query="instance-of(%topic%, op:Event)?">
      <tr><td><b><a href="event.jsp?id=<tolog:id var="topic"/>"
                ><tolog:out var="topic"/></a></b>
          <td>Event
            <tolog:if query="ph:start-date(%topic%, $DATE)?">
              starting <tolog:out var="DATE"/>
            </tolog:if>
    </tolog:when>
    <tolog:when query="instance-of(%topic%, op:Place)?">
      <tr><td><b><a href="place.jsp?id=<tolog:id var="topic"/>"
                ><tolog:out var="topic"/></a></b>
          <td>Place
            <tolog:if query="op:located_in(%topic% : op:Containee, $P : op:Container)?">
              in <a href="place.jsp?id=<tolog:id var="P"/>"
                   ><tolog:out var="P"/></a>
            </tolog:if>
    </tolog:when>
    <tolog:when query="instance-of(%topic%, op:Category)?">
      <tr><td><b><a href="category.jsp?id=<tolog:id var="topic"/>"
                ><tolog:out var="topic"/></a></b>
          <td>Category
    </tolog:when>
    <tolog:otherwise>
      <tr><td>???
    </tolog:otherwise>
  </tolog:choose>
</c:forEach>
</table>
<tolog:out var="paging" escape="no"/>

<!-- FILTERS -->
<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<td align=right>

<script>
function swap(id) {
  var elem = document.getElementById("f" + id);
  var link = document.getElementById("link" + id);
  var text = link.children[0].childNodes[0];
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
<td align=right><a id="link<tolog:oid var="filter.type"/>"
                   href="javascript:swap('<tolog:oid var="filter.type"/>')"
                  ><b>+</b></a>

<tr><td colspan=2 style="display: none" 
        id="f<tolog:oid var="filter.type"/>">
<table width="100%">
<c:forEach items="${filter.topics}" var="counter">
<tr><td>
<a href="?search=<%= search %>&filter=<tolog:id var="counter.topic"/>"
          ><tolog:out var="counter.topic"/></a>
    <td><tolog:out var="counter.count"/>
</c:forEach>
</table>
</table>
</c:forEach>

</table>


</template:put>
</template:insert>
</tolog:context>
