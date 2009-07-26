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
Events
</template:put>

<template:put name="body">

<p>
<tolog:query name="years">
  /* #OPTION: optimizer.reorder = false */
  select $YEAR from
    instance-of($EVENT, op:Event),
    <tolog:if var="nouser">
      not(ph:hide($EVENT : ph:hidden)),
    </tolog:if>
    ph:start-date($EVENT, $SDATE),
    year($SDATE, $YEAR)
  order by $YEAR desc?
</tolog:query>
<tolog:foreach query='years' separator=" | ">
  <a href="#y<tolog:out var="YEAR"/>"><tolog:out var="YEAR"/></a>
</tolog:foreach>

<table>
<tolog:query name="events">
  select $EVENT, $SDATE, $EDATE, $YEAR, count($PHOTO) from
    instance-of($EVENT, op:Event),
    <tolog:if var="nouser">
      not(ph:hide($EVENT : ph:hidden)),
    </tolog:if>
    { ph:start-date($EVENT, $SDATE) },
    { ph:end-date($EVENT, $EDATE) },
    { year($SDATE, $YEAR) | not(year($SDATE, $YEAR)) },
    ph:taken-during($PHOTO : op:Image, $EVENT : op:Event)
  order by $YEAR desc, $SDATE desc?
</tolog:query>
<tolog:foreach query='events' groupBy="YEAR">

  <tr><td colspan=2>
    <h2 style="margin-top: 12pt">
    <tolog:choose> 
      <tolog:when var="YEAR">
        <a name="y<tolog:out var="YEAR"/>"><tolog:out var="YEAR"/></a>
      </tolog:when>
      <tolog:otherwise>
        No date
      </tolog:otherwise>
    </tolog:choose>
    </h2>

  <tolog:foreach>
    <tr <tolog:if query="not(ph:is-processed(%EVENT% : ph:processed))?">
         class=unprocessed
        </tolog:if>>
        <td><a href="event.jsp?id=<tolog:id var="EVENT"/>"
              ><tolog:out var="EVENT"/></a>
      <tolog:choose>
        <tolog:when var="SDATE">
          <td><tolog:out var="SDATE"/> - <tolog:out var="EDATE"/>
        </tolog:when>
        <tolog:otherwise>
          <td>No date
        </tolog:otherwise>
      </tolog:choose>
      <td>&nbsp;&nbsp;&nbsp;<tolog:out var="PHOTO"/>    
  </tolog:foreach>
</tolog:foreach>
</table>

</template:put>

</template:insert>
</tolog:context>
