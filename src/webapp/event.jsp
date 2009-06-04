<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>
<%@ include file="remove-filter.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:set var="event"     reqparam="id"/>
<tolog:choose>
  <tolog:when var="event"> </tolog:when>
  <tolog:otherwise>
    <jsp:forward page="nosuch.jsp">
      <jsp:param name="what" value="event"/>
    </jsp:forward>
  </tolog:otherwise>
</tolog:choose>
<c:set var="place" scope="session"/>
<c:set var="person" scope="session" value=""/>
<c:set var="category" scope="session" value=""/>
<tolog:set var="filter"></tolog:set>
<c:if test='${sessionScope["filter"] != null && sessionScope["filter"] != ""}'>
  <tolog:query name="lookup">
    $T = <c:out value='${sessionScope["filter"]}'/>?
  </tolog:query>
  <tolog:set var="filter" query='lookup'/>
</c:if>
<tolog:if var="nouser">
  <tolog:if query="ph:hide(%event% : ph:hidden)?">
    <jsp:forward page="hidden.jsp"/>
  </tolog:if>
</tolog:if>
<tolog:set var="topicmap" query="topicmap($TM)?"/>
<%
 String sortby = request.getParameter("sort");
 if (sortby == null)
   sortby = "time";
%>

<template:insert template='template.jsp'>
<template:put name='title'>
<tolog:out var="event"/>
</template:put>

<template:put name="body">

<tolog:if var="filter">
  <p>Filtered by: <b><tolog:out var="filter"/></b>
    (<a href="unset.jsp?attr=filter">Remove filter</a>)
  </p>
</tolog:if>

<p>
<tolog:if query="dc:description(%event%, $DESC)?">
  <tolog:out var="DESC"/>
</tolog:if>
<tolog:choose>
  <tolog:when query="ph:start-date(%event%, $DATE),
                    ph:end-date(%event%, $DATE)?">
    On <tolog:out var="DATE"/>.
  </tolog:when>
  <tolog:otherwise>
    <tolog:if query="ph:start-date(%event%, $DATE)?">
      From <tolog:out var="DATE"/>
    </tolog:if>
    <tolog:if query="ph:end-date(%event%, $DATE)?">
      to <tolog:out var="DATE"/>.
    </tolog:if>
  </tolog:otherwise>
</tolog:choose>
</p>

<tolog:if query='subject-identifier(%event%, $PSI),
                 str:starts-with($PSI, "http://psi.ontopedia.net")?'>
  <p>&#x03a8; <a href="<tolog:out var="PSI"/>"><tolog:out var="PSI"/></a></p>
</tolog:if>

<tolog:if query="not(ph:is-processed(%event% : ph:processed))?">
  <p><b>Note:</b> We haven't finished processing the photos from this event
  yet, so there will be duplicates, poor photos, red eyes, and whatnot.</p>
</tolog:if>

<p>Sort by:
<% if (sortby.equals("time")) { %>
  <b>Time</b> | <a href="event.jsp?id=<%= request.getParameter("id") 
                         %>&sort=score">Score</a>
<% } else { %>
  <a href="event.jsp?id=<%= request.getParameter("id") %>">Time</a> | <b>Score</b>
<% } %>

<!-- PICTURES -->
<table width="100%">
<tr><td>

<tolog:set var="query">
  ph:taken-during(%event% : op:Event, $PHOTO : op:Image),
  ph:time-taken($PHOTO, $TIME),
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
                                       "event");
  request.setAttribute("list", list);
%>

<c:set var="pagelink">event.jsp?id=<tolog:id var="event"/><%
  if (sortby.equals("score")) { %>&sort=score<% } %></c:set>
<%@ include file="paging.jsp"%>

<tolog:out var="paging" escape="no"/>
<table>
<c:forEach items="${list.rows}" var="row"> 
  <c:set var="photo" value="${row.PHOTO}"/>
<%--  <tr><td><a href="photo.jsp?id=<tolog:id var="PHOTO"/><tolog:if var="catfilter">&cat=<tolog:id var="catfilter"/></tolog:if>"
            ><tolog:out var="PHOTO"/></a>
      <td><tolog:out var="TIME"/>
      <td><a href="place.jsp?id=<tolog:id var="PLACE"/>"
            ><tolog:out var="PLACE"/></a>--%>

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
<tolog:if query="ph:vote-score(%photo%, $AVG)?">
  <tolog:out var="AVG"/><br>
</tolog:if>


</c:forEach>
</table>
<tolog:out var="paging" escape="no"/>


<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<td>
<!-- TMRAP CONTENT -->
<%--
  try {
    TopicIF event = (TopicIF) ContextUtils.getSingleValue("event", pageContext);
    Collection servers = new ArrayList();
    servers.add(tmrap_url);
    TMRAP tmrap = new TMRAP(servers);
    Collection model = tmrap.query(event);
    pageContext.setAttribute("servers", model);
    pageContext.setAttribute("pages", tmrap.getAllPages(model));
%>
<c:if test="${not empty pages}">
<p><b>Blog entries:</b></p>

<ul>
<c:forEach items="${pages}" var="page">
  <li><a href="<c:out value="${page.URI}"/>"
    ><c:out value="${page.name}" escapeXml="false"/></a><br>
</c:forEach>
</ul>
</c:if>
<%
  } catch (java.io.IOException e) {
    out.write("<p><b>TMRAP error: </b> " + e + "</p>");
  }
--%>

<!-- FILTERS -->
<c:forEach items="${list.filters}" var="filter">
<table width="100%" class=filterbox><tr><td>
<p><b>Filter by <tolog:out var="filter.type"/></b></p>
<td align=right><a href="javascript:swap('<tolog:oid var="filter.type"/>')"
                  ><b id="link<tolog:oid var="filter.type"/>">+</b></a>

<tr><td colspan=2><div class="hidden"
        id="f<tolog:oid var="filter.type"/>">
<table width="100%">
<c:forEach items="${filter.topics}" var="counter">
<tr><td>
<a href="set-filter.jsp?id=<tolog:id var="counter.topic"/>" rel="nofollow"
          ><tolog:out var="counter.topic"/></a>
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
