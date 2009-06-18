<%@ include file="declarations.jsp"%>
<%
  String attr = null;
  if (request.getParameter("place") != null) attr = "place";
  if (request.getParameter("cat") != null) attr = "cat";
  if (request.getParameter("person") != null) attr = "person";
  if (attr != null) {
    String id = request.getParameter(attr);
    String sess = attr;
    if (attr.equals("cat")) sess = "category";
    session.setAttribute(sess, id);
    response.setHeader("Location", 
                       "http://www.garshol.priv.no/tmphoto/photo.jsp?id=" + 
                       request.getParameter("id"));
    response.sendError(HttpServletResponse.SC_MOVED_PERMANENTLY);
    return;
  }
%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:set var="photo" reqparam="id"/>
<tolog:choose>
  <tolog:when var="photo"> </tolog:when>
  <tolog:otherwise>
    <jsp:forward page="nosuch.jsp">
      <jsp:param name="what" value="photo"/>
    </jsp:forward>
  </tolog:otherwise>
</tolog:choose>
<c:set var="filter" scope="session" value=""/>

<c:choose>
  <c:when test='${sessionScope["place"] != "" && sessionScope["place"] != null}'>
    <tolog:query name="lookup">
      $T = <c:out value='${sessionScope["place"]}'/>?
    </tolog:query>
    <tolog:set var="place" query='lookup'/>
  </c:when>
  <c:when test='${sessionScope["person"] != "" && sessionScope["person"] != null}'>
    <tolog:query name="lookup">
      $T = <c:out value='${sessionScope["person"]}'/>?
    </tolog:query>
    <tolog:set var="person" query='lookup'/>
  </c:when>
  <c:when test='${sessionScope["category"] != "" && sessionScope["category"] != null}'>
    <tolog:query name="lookup">
      $T = <c:out value='${sessionScope["category"]}'/>?
    </tolog:query>
    <tolog:set var="cat" query='lookup'/>
  </c:when>
</c:choose>

<tolog:if var="nouser">
  <tolog:if query="{ ph:depicted-in(%photo% : ph:depiction, $PERSON : ph:depicted),
                     ph:hide($PERSON : ph:hidden)
                   | ph:hide(%photo% : ph:hidden)
                   | ph:taken-at(%photo% : op:Image, $PLACE : op:Place),
                     ph:hide($PLACE : ph:hidden)
                   | ph:taken-during(%photo% : op:Image, $EVENT : op:Event),
                     ph:hide($EVENT : ph:hidden) }?">
    <jsp:forward page="hidden.jsp"/>
  </tolog:if>
</tolog:if>


<template:insert template='template.jsp'>
<template:put name='title'>
  <tolog:out var="photo"/>
</template:put>

<template:put name="body">
<tolog:set var="time" query="ph:time-taken(%photo%, $DATE)?"/>

<%-- PREVIOUS --%>
<tolog:set var="previousq">
  ph:time-taken($PHOTO, $DATE),
  $DATE < %time%
  <tolog:if var="place"> ,
    ph:taken-at($PLACE : op:Place, $PHOTO : op:Image),
    { $PLACE = %place% | located-in(%place%, $PLACE) }
  </tolog:if>
  <tolog:if var="cat"> ,
    ph:in-category($PHOTO : ph:categorized, $TMP : ph:categorization),
    { %cat% = $TMP | broader-than(%cat%, $TMP) }
  </tolog:if>
  <tolog:if var="person"> ,
    ph:depicted-in($PHOTO : ph:depiction, %person% : ph:depicted)
  </tolog:if>
  <tolog:if var="nouser"> ,
  not(ph:hide($PHOTO : ph:hidden)),
  not(ph:depicted-in($PHOTO : ph:depiction, $PERSON : ph:depicted),
      ph:hide($PERSON : ph:hidden)),
  not(ph:taken-at($PHOTO : op:Image, $PLACE : op:Place),
      ph:hide($PLACE : ph:hidden)),
  not(ph:taken-during($PHOTO : op:Image, $EVENT : op:Event),
      ph:hide($EVENT : ph:hidden))
  </tolog:if>
order by $DATE desc limit 1?
</tolog:set>
<tolog:if query='<%= (String) ContextUtils.getSingleValue("previousq", pageContext) %>'>
  <a href="photo.jsp?id=<tolog:id var="PHOTO"/>"><img src="resources/nav_prev.gif" border="0"></a>
</tolog:if>

<%-- SEQUENCE --%>
<tolog:if var="place">
  <b><a href="place.jsp?id=<tolog:id var="place"/>"><tolog:out var="place"/></a></b>
  <a href="unset.jsp?attr=place"
    ><img src="resources/remove.gif" border=0></a>
</tolog:if>
<tolog:if var="cat">
  <b><a href="category.jsp?id=<tolog:id var="cat"/>"><tolog:out var="cat"/></a></b>
  <a href="unset.jsp?attr=category"
    ><img src="resources/remove.gif" border=0></a>
</tolog:if>
<tolog:if var="person">
  <b><a href="person.jsp?id=<tolog:id var="person"/>"><tolog:out var="person"/></a></b>
  <a href="unset.jsp?attr=person"
    ><img src="resources/remove.gif" border=0></a>
</tolog:if>

<%-- NEXT --%>
<tolog:query name="next">
  ph:time-taken($PHOTO, $DATE),
  $DATE > %time%
  <tolog:if var="place">,
    ph:taken-at($PLACE : op:Place, $PHOTO : op:Image),
    { $PLACE = %place% | located-in(%place%, $PLACE) }
  </tolog:if>
  <tolog:if var="cat"> ,
    ph:in-category($PHOTO : ph:categorized, $TMP : ph:categorization),
    { %cat% = $TMP | broader-than(%cat%, $TMP) }
  </tolog:if>
  <tolog:if var="person"> ,
    ph:depicted-in($PHOTO : ph:depiction, %person% : ph:depicted)
  </tolog:if>
  <tolog:if var="nouser"> ,
    not(ph:hide($PHOTO : ph:hidden)),
    not(ph:depicted-in($PHOTO : ph:depiction, $PERSON : ph:depicted),
        ph:hide($PERSON : ph:hidden)),
    not(ph:taken-at($PHOTO : op:Image, $PLACE : op:Place),
        ph:hide($PLACE : ph:hidden)),
    not(ph:taken-during($PHOTO : op:Image, $EVENT : op:Event),
        ph:hide($EVENT : ph:hidden))
  </tolog:if>
order by $DATE limit 1?
</tolog:query>
<tolog:if query="next">
  <tolog:set var="nextphoto">photo.jsp?id=<tolog:id var="PHOTO"/></tolog:set>

  <a title="next" href="<tolog:out var="nextphoto"/>"><img src="resources/nav_next.gif" border="0" alt="Next"></a>

  <%
    // this is for the remove button further down
    pageContext.setAttribute("next", ContextUtils.getSingleValue("PHOTO", pageContext));
  %>
</tolog:if>

<%-- PLACE --%>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<tolog:if query="ph:taken-at($PLACE : op:Place, %photo% : op:Image)?">
  <%--b>Place:</b--%>
  <a href="place.jsp?id=<tolog:id var="PLACE"/>"
    ><tolog:out var="PLACE"/></a>
</tolog:if>

<%-- EVENT --%>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<tolog:if query="ph:taken-during($EVENT : op:Event, %photo% : op:Image)?">
  <%--b>Event:</b--%>
  <a href="event.jsp?id=<tolog:id var="EVENT"/>"
    ><tolog:out var="EVENT"/></a>
</tolog:if>

<%-- TIME --%>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<tolog:out var="time"/>

<%-- BUTTON --%>
<tolog:if var="username">
<tolog:if query='%username% = "larsga"?'>
&nbsp;&nbsp;&nbsp;
<a href="delete-photo.jsp?id=<tolog:id var="photo"/><% if (pageContext.getAttribute("next") != null) { %>&photo=<tolog:id var="next"/><% } %>"
   onclick="return confirmDelete()"><img src="resources/remove.gif"></a>
</tolog:if>
</tolog:if>

<script>
  function openInfo(photoid) {
    window.open("<%= photo_url %>" + photoid + ";metadata",
      "infoWindow","menubar=0,resizable=0,width=450,height=500,scrollbars=1");
  }
</script>

<a href="javascript:openInfo('<tolog:id var="photo"/>')"><img src="resources/info.gif" border=0></a>

<br>
<%
  String id = request.getParameter("id");
  String scoreurl = "";
  double average = 0;
  int votes = 0;
  if (has_comments) {
    average = ScoreManager.getAverageScore(id);
    votes = ScoreManager.getVoteCount(id);
%>
<span title="Average vote, out of <%= votes %> votes is <%= average %>">
<%
  for (int stars = 0; stars < 5; stars++) { %>
    <img id=avgstar<%= stars %> src="resources/gray-star.png">
<%}%>
</span>
    
<% } else
    scoreurl = "http://www.garshol.priv.no/tmphoto/";
%>
&nbsp;&nbsp;&nbsp;
<span title="Please record your vote. 1 star is bad, 3 is average, 5 is really good">
<form method=post action="<%= scoreurl %>set-score.jsp" style="display: inline"
      name=voteform>
<input type=hidden name=id value="<%= id %>">
<input type=hidden name=score value="" id=score>
<img id="star1" src="resources/white-star.png"
     onmouseover="moveonto(1)" onmouseout="moveoff(1)" onclick="vote(1)">
<img id="star2" src="resources/white-star.png"
     onmouseover="moveonto(2)" onmouseout="moveoff(2)" onclick="vote(2)">
<img id="star3" src="resources/white-star.png"
     onmouseover="moveonto(3)" onmouseout="moveoff(3)" onclick="vote(3)">
<img id="star4" src="resources/white-star.png"
     onmouseover="moveonto(4)" onmouseout="moveoff(4)" onclick="vote(4)">
<img id="star5" src="resources/white-star.png"
     onmouseover="moveonto(5)" onmouseout="moveoff(5)" onclick="vote(5)">
</form>
</span>

<br>
<tolog:choose>
  <tolog:when var="username">
    <a href="<%= photo_url %><tolog:id var="photo"/>;full"
      ><img src="<%= photo_url %><tolog:id var="photo"/>" border=0></a>
  </tolog:when>
  <tolog:otherwise>
    <img src="<%= photo_url  %><tolog:id var="photo"/>">
  </tolog:otherwise>
</tolog:choose>

<p> </p>
<table>
<tr><td>
<tolog:if query="dc:description(%photo%, $DESC)?">
  <p><tolog:out var="DESC"/></p>
</tolog:if>

<td>
<tolog:if query="ph:depicted-in(%photo% : ph:depiction, $PERSON : ph:depicted)?">
<ul>
<tolog:foreach query="ph:depicted-in(%photo% : ph:depiction, $PERSON : ph:depicted)?">
  <li><a href="person.jsp?id=<tolog:id var="PERSON"/>"
        ><tolog:out var="PERSON"/></a>
</tolog:foreach>
</ul>
</tolog:if>

<tolog:if query="ph:in-category(%photo% : ph:categorized, $CAT : ph:categorization)?">
<ul>
<tolog:foreach query="ph:in-category(%photo% : ph:categorized, $CAT : ph:categorization)?">
  <li><a href="category.jsp?id=<tolog:id var="CAT"/>"
        ><tolog:out var="CAT"/></a>
</tolog:foreach>
</ul>
</tolog:if>

</table>

<script>
<% if (has_comments) { %>
  var votes = <%= votes %>;
  var average = <%= average %>;
  var userscore = <%= ScoreManager.getScore(id, (username != null ? username : "nobody")) %>;
<% } else { %>
  var userscore = 0.0;
<% } %>
  var photoid = "<tolog:id var="photo"/>";

function set_average_stars(avg) {
  var stars = 0;
  while (avg > 0) {
    if (avg > 0.9) {
      set_average_star(stars, "red");
      stars++;
      avg -= 1.0;
    } else if (avg > 0.1) {
      set_average_star(stars, "half-red");
      stars++;
      avg = 0;
    } else
      avg = 0;
  } 
  for (; stars < 5; stars++) {
    set_average_star(stars, "gray");
  }
}
function set_average_star(ix, color) {
  img = document.getElementById("avgstar" + ix);
  img.src = "resources/" + color + "-star.png"; 
}

function setstars(start, end, type) {
  for (var ix = start; ix <= end; ix++) {
    img = document.getElementById("star" + ix);
    img.src = "resources/" + type + "-star.png";
  }
}
function moveonto(number) {
  setstars(1, number, "yellow");
  setstars(number + 1, 5, "white");
}
function moveoff(number) {
  setstars(1, userscore, "yellow");
  setstars(userscore + 1, 5, "white");
}
function vote(number) {
  var xmlhttp = new XMLHttpRequest();
  xmlhttp.open("POST", "set-score.jsp?id=" + photoid + "&score=" + number, false);
  xmlhttp.send();
  if (xmlhttp.readyState == 4 &&
      xmlhttp.status == 200) {
    if (userscore == 0) {
      average = ((average * votes) + number) / (votes + 1);
      votes = votes + 1;
      userscore = number;
    } else {
      average = ((average * votes) + number - userscore) / votes;
      userscore = number;
    }
    set_average_stars(average);
  } else {
    alert("Problem: " + xmlhttp.readyState + ", " + xmlhttp.status);
  }
}
</script>

<script>
function confirmDelete() {
  return confirm('Are you sure you want to delete this photo?');
}
</script>
</template:put>

<template:put name="bodyattrs">
onload="moveoff(0); set_average_stars(average)"
</template:put>

<tolog:if var="place">
  <template:put name="headertags">
    <meta name="robots" content="noindex,nofollow">
  </template:put>
</tolog:if>
<tolog:if var="cat">
  <template:put name="headertags">
    <meta name="robots" content="noindex,nofollow">
  </template:put>
</tolog:if>
<tolog:if var="person">
  <template:put name="headertags">
    <meta name="robots" content="noindex,nofollow">
  </template:put>
</tolog:if>
</template:insert>
</tolog:context>
