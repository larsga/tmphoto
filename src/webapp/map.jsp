<%@ include file="declarations.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<tolog:set var="place" reqparam="id"/>
<c:set var="place" scope="session" value="${null}"/>
<c:set var="person" scope="session" value="${null}"/>
<c:set var="category" scope="session" value="${null}"/>
<c:set var="filter" scope="session" value="${null}"/>

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

<script src="http://maps.googleapis.com/maps/api/js?key=<%= gmapkey %>&sensor=false" type="text/javascript"></script>
<script type="text/javascript">

    // the place icon
    var placeicon = 'http://www.garshol.priv.no/tmphoto/resources/blue-dot.gif';

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
    <tolog:choose>
    <tolog:when var="place">
      <tolog:if query="ph:latitude(%place%, $LAT),
                       ph:longitude(%place%, $LONG)?">
        center: new google.maps.LatLng(<tolog:out var="LAT"/>, 
                                       <tolog:out var="LONG"/>),
        zoom: 15
      </tolog:if>
    </tolog:when>
    <tolog:otherwise>
      center: new google.maps.LatLng(50, 40),
      zoom: 2
    </tolog:otherwise>
    </tolog:choose>
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
