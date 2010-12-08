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
Photos by year
</template:put>

<template:put name="body">

<table>
<tr><th>Year  <th>Photos
<tolog:query name="years">
  select $YEAR, count($PHOTO) from
    instance-of($PHOTO, op:Image),
    ph:time-taken($PHOTO, $SDATE),
    year($SDATE, $YEAR)
  order by $YEAR desc?
</tolog:query>
<tolog:foreach query='years'>
  <tr><td><a href="year.jsp?year=<tolog:out var="YEAR"/>"
            ><tolog:out var="YEAR"/></a>
      <td><tolog:out var="PHOTO"/>
</tolog:foreach>
</table>

</template:put>

</template:insert>
</tolog:context>
