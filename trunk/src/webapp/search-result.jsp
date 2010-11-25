<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>
<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<%
  String search = StringUtils.transcodeUTF8(request.getParameter("search"));
%>
<tolog:set var="search"><%= search %></tolog:set>
<tolog:set var="topicmap" query="topicmap($TM)?"/>
<%
  request.setAttribute("filter", new FilterContext(pageContext));
%>

<template:insert template='template.jsp'>
<template:put name='title'>Search result</template:put>

<template:put name="body">

<form method=get action=search-result.jsp>
<input name=search size=50 style="font-size: 140%" value="<%= search %>">
<input type=submit value=Search style="font-size: 140%">
</form>

<c:if test="${filter.set}">
  <p>Filtered by: <b><c:out value="${filter.label}"/></b>
    (<a href="unset.jsp?attr=filter">Remove filter</a>)
  </p>
</c:if>

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
  FilteredList list = new FilteredList(pageContext, query, "$REL desc", "TOPIC",
                                       "event");
  request.setAttribute("list", list);
%>

<c:set var="pagelink">?search=<%= search %>&</c:set>
<%@ include file="paging.jsp"%>

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
<td>
<%--
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
--%>

</table>


</template:put>
</template:insert>
</tolog:context>
