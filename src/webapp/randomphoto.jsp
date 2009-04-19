<tolog:query name="allphotos">
select $PHOTO from
  instance-of($PHOTO, op:Photo)
  <tolog:if var="nouser">,
    not(ph:hide($PHOTO : ph:hidden)),
    not(ph:taken-at($PHOTO : op:Image, $PLACE : op:Place),
        ph:hide($PLACE : ph:hidden)),
    not(ph:taken-during($PHOTO : op:Image, $EVENT : op:Event),
        ph:hide($EVENT : ph:hidden)),
    not(ph:depicted-in($PHOTO : ph:depiction, $PERSON : ph:depicted),
        ph:hide($PERSON : ph:hidden))
  </tolog:if>?
</tolog:query>
<tolog:set var="photos" query="allphotos"/>

<%
  TopicIF photo = SelectRandomly.selectAtRandom("photos", pageContext);
  ContextUtils.setSingleValue("photo", pageContext, photo);
%>

<a href="photo.jsp?id=<tolog:id var="photo"/>">
<img src="<%= photo_url %><tolog:id var="photo"/>;thumb" border=0>
</a>
<td valign=top><span style="font-size: 75%"><tolog:out var="photo"/><br>
<tolog:if query="ph:taken-at($PLACE : op:Place, %photo% : op:Image)?">
  <a href="place.jsp?id=<tolog:id var="PLACE"/>"><tolog:out var="PLACE"/></a><br>
</tolog:if>
<tolog:if query="ph:taken-during($EVENT : op:Event, %photo% : op:Image)?">
  <a href="event.jsp?id=<tolog:id var="EVENT"/>"><tolog:out var="EVENT"/></a><br>
</tolog:if>
<tolog:out query="ph:time-taken(%photo%, $DATE)?"/><br>
</span>
