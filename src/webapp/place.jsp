<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>
<%@ include file="remove-filter.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:set var="place" reqparam="id"/>
<tolog:choose>
  <tolog:when var="place">
    <%-- because tree widget used to use object IDs, lots of search engines
         have references to non-topic objects. so we have to verify. --%>
    <% if (!(ContextUtils.getSingleValue("place", pageContext)
             instanceof TopicIF)) { %>
      <jsp:forward page="nosuch.jsp">
        <jsp:param name="what" value="place"/>
      </jsp:forward>
    <% } %>
  </tolog:when>
  <tolog:otherwise>
    <jsp:forward page="nosuch.jsp">
      <jsp:param name="what" value="place"/>
    </jsp:forward>
  </tolog:otherwise>
</tolog:choose>
<tolog:set var="topicmap" query="topicmap($TM)?"/>
<c:set var="place" scope="session"><tolog:id var="place"/></c:set>
<c:set var="person" scope="session" value="${null}"/>
<c:set var="category" scope="session" value="${null}"/>
<%
 request.setAttribute("filter", new FilterContext(pageContext));

 String sortby = request.getParameter("sort");
 if (sortby == null)
   sortby = "time";
%>

<template:insert template='template.jsp'>
<template:put name='title'>
Photos from <tolog:out var="place"/>
</template:put>

<template:put name="body">

<!-- LEFT COLUMN -->
<table width="100%"><tr><td>

<c:if test="${filter.set}">
  <p>Filtered by: <b><c:out value="${filter.label}"/></b>
    (<a href="unset.jsp?attr=filter">Remove filter</a>)
  </p>
</c:if>

<tolog:if query="op:located_in($PAR : op:Container, %place% : op:Containee)?">
<p>In: <a href="place.jsp?id=<tolog:id var="PAR"/>"
                   ><tolog:out var="PAR"/></a>
</tolog:if>

<tolog:if query="dc:description(%place%, $DESC)?">
  <p><tolog:out var="DESC"/></p>
</tolog:if>

<tolog:if query='subject-identifier(%place%, $PSI),
                 { str:starts-with($PSI, "http://psi.ontopedia.net") |
                   str:starts-with($PSI, "http://psi.oasis-open.org") |
                   str:starts-with($PSI, "http://dbpedia.org") |
                   str:starts-with($PSI, "http://sws.geonames.org") } ?'>
  <p>&#x03a8; <a href="<tolog:out var="PSI"/>"><tolog:out var="PSI"/></a></p>
</tolog:if>

<tolog:query name="subplaces">
  op:located_in(%place% : op:Container, $P : op:Containee)
  <tolog:if var="nouser">
                  , not(ph:hide($P : ph:hidden))
  </tolog:if>
  order by $P?
</tolog:query>
<tolog:if query="subplaces">
<ul>
  <tolog:foreach query="subplaces">
    <li><a href="place.jsp?id=<tolog:id var="P"/>"
          ><tolog:out var="P"/></a>
  </tolog:foreach>
</ul>
</tolog:if>

<p>Sort by:
<% if (sortby.equals("time")) { %>
  <b>Time</b> | <a href="place.jsp?id=<%= request.getParameter("id") 
                         %>&sort=score">Score</a>
<% } else { %>
  <a href="event.jsp?id=<%= request.getParameter("id") %>">Time</a> | <b>Score</b>
<% } %>

<tolog:set var="query">
  /* #OPTION: optimizer.reorder = false */
  { $PLACE = %place% |
    located-in(%place%, $PLACE) },
  ph:taken-at($PLACE : op:Place, $PHOTO : op:Image),
  ph:time-taken($PHOTO, $TIME)
  <% if (sortby.equals("score")) { %>
    , ph:vote-score($PHOTO, $AVG)
  <% } %>
  <tolog:if var="nouser">
    ,
    not(ph:hide($PLACE : ph:hidden)),
    not(ph:hide($PHOTO : ph:hidden)),
    not(ph:depicted-in($PHOTO : ph:depiction, $PERSON : ph:depicted),
        ph:hide($PERSON : ph:hidden)),
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
                                       "place");
  request.setAttribute("list", list);
%>

<c:set var="pagelink">place.jsp?id=<tolog:id var="place"/><%
  if (sortby.equals("score")) { %>&sort=score<% } %>&</c:set>
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

</c:forEach>
</table>
<tolog:out var="paging" escape="no"/>

<!-- RIGHT COLUMN -->
<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<td width="30%">

<%
  if (gmapkey != null) {
%>
<tolog:if query="ph:latitude(%place%, $LAT),
                 ph:longitude(%place%, $LONG)?">
<div id="map" style="width: 100%; height: 200px"></div>

<script src="http://maps.googleapis.com/maps/api/js?key=<%= gmapkey %>&sensor=false" type="text/javascript"></script>
<script type="text/javascript">

    // the place icon
    var placeicon = 'http://www.garshol.priv.no/tmphoto/resources/blue-dot.gif';

    // the highlighted place icon
    var blueicon = 'http://www.garshol.priv.no/tmphoto/resources/green-dot.gif';

    // opens info window for marker
    function marker_clicked(marker) {
      if (!marker)
        return;
      // have to clone the nodes, because GMap appears to discard them
      // when the window is closed
      element = document.getElementById(marker.popupid).cloneNode(true);
      element.style.display = '';
      infowindow.content = element;
      infowindow.open(map, marker);
    }

    var infowindow = new google.maps.InfoWindow({ content: '' });

    // adds a place marker to the map
    function add_place(x, y, name, popupid, icon) { 
      var marker = new google.maps.Marker({
        position: new google.maps.LatLng(y, x),
	map: map,
	title: name,
	icon: icon
      });
      marker.popupid = popupid;
      google.maps.event.addListener(marker, 'click', function() {
        marker_clicked(marker);
      });
    }

    // creating the map
    var map = new google.maps.Map(document.getElementById('map'), {
      <tolog:if query="ph:latitude(%place%, $LAT),
                       ph:longitude(%place%, $LONG)?">
        center: new google.maps.LatLng(<tolog:out var="LAT"/>, 
                                       <tolog:out var="LONG"/>),
        zoom: 6
      </tolog:if>
    });
</script>
<tolog:foreach query="
  instance-of($PLACE, op:Place),
  ph:latitude($PLACE, $LAT),
  ph:longitude($PLACE, $LONG) order by $PLACE?">
  <script type="text/javascript">
  add_place(<tolog:out var="LONG"/>,
            <tolog:out var="LAT"/>,
            '<tolog:out var="PLACE"/>',
            '<tolog:id var="PLACE"/>',
    <tolog:choose>
      <tolog:when query="%place% = %PLACE%?">
            blueicon);
      </tolog:when>
      <tolog:otherwise>
            placeicon);
      </tolog:otherwise>
    </tolog:choose>
  </script>
  <div style="display: none; font-family: Arial; font-size: 8pt; width: 50px" 
     id="<tolog:id var="PLACE"/>">
  <b><tolog:out var="PLACE"/></b><br>
  <tolog:if var="dc:description(%PLACE%, $DESC)?">
    <tolog:out var="DESC"/><br>
  </tolog:if>
  <a href="place.jsp?id=<tolog:id var="PLACE"/>">Pictures</a>
  </div>
</tolog:foreach>
</tolog:if>
<% } // if gmapkey not set %>

<br>
<!-- TMRAP CONTENT -->
<%
  if (tmrap_url != null) {
    String varname = "place";
%>
  <%@ include file="tmrap.jsp"%>
<% } %>

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

<!-- DONE -->
</table>
</template:put>

<tolog:if var="filter">
  <template:put name="headertags">
    <meta name="robots" content="noindex,nofollow">
  </template:put>
</tolog:if>
</template:insert>
</tolog:context>
