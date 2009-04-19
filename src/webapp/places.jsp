<%@ include file="declarations.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>
<c:set var="place" scope="session"/>
<c:set var="person" scope="session" value=""/>
<c:set var="category" scope="session" value=""/>
<c:set var="filter" scope="session" value=""/>

<template:insert template='template.jsp'>
<template:put name='title'>
  Places
</template:put>

<template:put name="body">

<tolog:set var="query">
  op:located_in(%parent% : op:Container, $CHILD : op:Containee)
  <tolog:if var="nouser">
    , not(ph:hide($CHILD : ph:hidden))
  </tolog:if>
  order by $CHILD?
</tolog:set>

<p><a href="map.jsp">Map</a>

<p>
<portlets:tree
  topquery="select $TOP from
              instance-of($TOP, op:Place),
              not(op:located_in($OTHER : op:Container, $TOP : op:Containee))
            order by $TOP?"
  query='<%= (String) ContextUtils.getSingleValue("query", pageContext) %>'
  ownpage="places.jsp?"
  nodepage="place.jsp?"
/>

<!-- FIXME: a random photo would be nice here, too -->

</template:put>

</template:insert>
</tolog:context>
