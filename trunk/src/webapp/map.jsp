<%@ include file="declarations.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<tolog:set var="place" reqparam="id"/>
<c:set var="place" scope="session"/>
<c:set var="person" scope="session" value=""/>
<c:set var="category" scope="session" value=""/>
<c:set var="filter" scope="session" value=""/>

<template:insert template='template.jsp'>
<template:put name='title'>
  Map
</template:put>

<template:put name="body">

<p><a href="places.jsp">Tree</a>

<%
  if (gmapkey != null) {
%>
<div id="map" style="width: 100%; height: 720px"></div>

<script src="http://maps.google.com/maps?file=api&amp;v=1&amp;key=<%= gmapkey %>" type="text/javascript"></script>    
<script type="text/javascript">

    // the place icon
    var placeicon = new GIcon();
    placeicon.image = 'http://www.garshol.priv.no/tmphoto/resources/blue-dot.gif';
//'http://www.garshol.priv.no/tmphoto/images/green-dot.gif';
    placeicon.iconSize = new GSize(9, 9);
    placeicon.iconAnchor = new GPoint(5, 5);
    placeicon.infoWindowAnchor = new GPoint(9, 2);
    placeicon.infoShadowAnchor = new GPoint(18, 25);

    // opens info window for marker
    function marker_clicked(marker) {
      if (!marker)
        return;
      // have to clone the nodes, because GMap appears to discard them
      // when the window is closed
      element = document.getElementById(marker.popupid).cloneNode(true);
      element.style.display = '';
      map.openInfoWindow(marker.getPoint(), element);
    }

    // adds a place marker to the map
    function add_place(x, y, name, popupid, icon) { 
      marker = new GMarker(new GPoint(x, y), icon);
      marker.popupid = popupid;
      GEvent.addListener(map, 'click', marker_clicked);
      map.addOverlay(marker);
    }

    // creating the map
    var map = new GMap(document.getElementById('map'));
    map.addControl(new GLargeMapControl());
    map.addControl(new GScaleControl());
    <tolog:choose>
    <tolog:when var="place">
      <tolog:if query="ph:latitude(%place%, $LAT),
                       ph:longitude(%place%, $LONG)?">
        map.centerAndZoom(new GPoint(<tolog:out var="LONG"/>, 
                                     <tolog:out var="LAT"/>), 8);
      </tolog:if>
    </tolog:when>
    <tolog:otherwise>
      map.centerAndZoom(new GPoint(50, 40), 15);
    </tolog:otherwise>
    </tolog:choose>
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
            placeicon);
  </script>
  <div style="display: none; font-family: Arial; font-size: 10pt; width: 200px" 
     id="<tolog:id var="PLACE"/>">
  <b><tolog:out var="PLACE"/></b><br>
  <tolog:if var="dc:description(%PLACE%, $DESC)?">
    <tolog:out var="DESC"/><br>
  </tolog:if>
  <a href="place.jsp?id=<tolog:id var="PLACE"/>">Pictures</a>
  </div>
</tolog:foreach>
<% } /* if gmapkey not set */ else { %>
  <p>No Google Maps key set, so cannot display map.
<% } %>

</template:put>

</template:insert>
</tolog:context>
