<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>
<%@ include file="remove-filter.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:set var="topicmap" query="topicmap($TM)?"/>
<tolog:set var="person"  reqparam="id"/>
<tolog:choose>
  <tolog:when var="person"> </tolog:when>
  <tolog:otherwise>
    <jsp:forward page="nosuch.jsp">
      <jsp:param name="what" value="person"/>
    </jsp:forward>
  </tolog:otherwise>
</tolog:choose>
<%
 request.setAttribute("filter", new FilterContext(pageContext));

 String sortby = request.getParameter("sort");
 if (sortby == null)
   sortby = "time";
%>

<tolog:if var="nouser">
  <tolog:if query="ph:hide(%person% : ph:hidden)?">
    <jsp:forward page="hidden.jsp"/>
  </tolog:if>
</tolog:if>
<c:set var="person" scope="session"><tolog:id var="person"/></c:set>
<c:set var="place" scope="session" value=""/>
<c:set var="category" scope="session" value=""/>

<template:insert template='template.jsp'>
<template:put name='title'>
<tolog:out var="person"/>
</template:put>

<template:put name="body">

<c:if test="${filter.set}">
  <p>Filtered by: <b><c:out value="${filter.label}"/></b>
    (<a href="unset.jsp?attr=filter">Remove filter</a>)
  </p>
</c:if>

<tolog:if query="dc:description(%person%, $DESC)?">
  <p><tolog:out var="DESC"/></p>
</tolog:if>

<tolog:if query="subject-identifier(%person%, $PSI)?">
  <p>&#x03a8; <a href="<tolog:out var="PSI"/>"><tolog:out var="PSI"/></a></p>
</tolog:if>

<p>Sort by:
<% if (sortby.equals("time")) { %>
  <b>Time</b> | <a href="person.jsp?id=<%= request.getParameter("id") 
                         %>&sort=score">Score</a>
<% } else { %>
  <a href="person.jsp?id=<%= request.getParameter("id") %>">Time</a> | <b>Score</b>
<% } %>

<!-- PICTURES -->
<p>
<table width="100%">
<tr><td>

<tolog:set var="query">
  ph:depicted-in(%person% : ph:depicted, $PHOTO : ph:depiction),
  ph:time-taken($PHOTO, $TIME),
  ph:taken-at($PHOTO : op:Image, $PLACE : op:Place)
  <% if (sortby.equals("score")) { %>
    , ph:vote-score($PHOTO, $AVG)
  <% } %>
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
  String query = (String) ContextUtils.getSingleValue("query", pageContext);
  String sort;
  if (sortby.equals("time"))
    sort = "$TIME desc";
  else
    sort = "$AVG desc";
  FilteredList list = new FilteredList(pageContext, query, sort, "PHOTO",
                                       "person");
  request.setAttribute("list", list);
%>

<c:set var="pagelink">person.jsp?id=<tolog:id var="person"/><%
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

<!-- FILTERS -->
<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<td>

<%--tolog:if var="nouser">
  <p>Is this you? And would you rather not see this page exposed to the
  entire internet? If so, send me an email, and I'll hide it.</p>
</tolog:if--%>

<tolog:set var="fquery">
  using ph for i"http://psi.garshol.priv.no/tmphoto/"
  <tolog:choose>
    <tolog:when var="nouser">
      ph:hide(%topic% : ph:hidden)?
    </tolog:when>
    <tolog:otherwise>
      ph:hide(%topic% : ph:hide)? <%-- meaningless --%>
    </tolog:otherwise>
  </tolog:choose>
</tolog:set>
<%
  String fquery = (String) ContextUtils.getSingleValue("fquery", pageContext);
%>

<portlets:related topic="person" var="headings"
                  excludeAssociations="ph:hide ph:depicted-in dc:creator"
                  filterQuery='<%= fquery %>'>
<c:if test="${!empty headings}">

<table width="100%" class=filterbox><tr><td>
  <ul>
    <c:forEach items="${headings}" var="heading">
      <li><b><c:out value="${heading.title}"/></b>
        <ul>
          <c:forEach items="${heading.children}" var="assoc">
            <li><a href="person.jsp?id=<tolog:id var="assoc.player"/>"><tolog:out var="assoc.player"/></a>
          </c:forEach>
        </ul>
    </c:forEach>
  </ul>
</table>
</c:if>
</portlets:related>

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
