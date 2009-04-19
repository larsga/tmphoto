<%@ include file="declarations.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<tolog:set var="photo" reqparam="id"/>
<%
  String number = request.getParameter("number"); 
%>
<tolog:set var="time" query="occ:last-modified-at(%photo%, $DATE)?"/>

<template:insert template='template.jsp'>
<template:put name='title'>
  <tolog:out var="photo"/> + <%= number %>
</template:put>

<template:put name="body">
<tolog:query name="next">
  instance-of($PHOTO, ph:photo),
  <tolog:if var="nouser">
    not(ph:hide($PHOTO : ph:photo)),
    not(ph:depicted-in($PHOTO : ph:photo, $PERSON : ph:object),
        ph:hide($PERSON : ph:photo)),
    not(ph:taken-at($PHOTO : ph:photo, $PLACE : ph:location),
        ph:hide($PLACE : ph:photo)),
  </tolog:if>
  occ:last-modified-at($PHOTO, $DATE),
  $DATE >= %time%
  order by $DATE limit <%= number %>?
</tolog:query>

<%
  List imgs = new ArrayList();
%>
<tolog:foreach query="next">
<%
  imgs.add(ContextUtils.getSingleValue("PHOTO", pageContext));
%>
</tolog:foreach>


<table>
<%
  int ix = 0;
  while (ix < imgs.size()) {
    int end = ix + 3;
%>
<tr>
<%
    for (; ix < imgs.size() && ix < end; ix++) {
      ContextUtils.setSingleValue("PHOTO", pageContext, imgs.get(ix));
%>
<td><a href="photo.jsp?id=<tolog:id var="PHOTO"/>"><img src="<%= pageContext.getServletContext().getInitParameter("photo-server") %><tolog:id var="PHOTO"/>;thumb" border="0" alt="<tolog:out var="PHOTO"/>"></a>
<%
    }
  } 
%>
</table>

</template:put>

</template:insert>
</tolog:context>
