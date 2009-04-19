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
People
</template:put>

<template:put name="body">

<tolog:query name="initial-query">
  select $INITIAL from
    instance-of($PERSON, op:Person),
    <tolog:if var="nouser">
    not(ph:hide($PERSON : ph:hidden)),
    </tolog:if>
    topic-name($PERSON, $TN), value($TN, $NAME),
    str:substring($INITIAL, $NAME, 0, 1) 
  order by $INITIAL?
</tolog:query>

<p>
<tolog:foreach query='initial-query' separator=" | ">
  <a href="#<tolog:out var="INITIAL"/>"><tolog:out var="INITIAL"/></a>
</tolog:foreach>

<table>

<tolog:query name="people-query">
  select $INITIAL, $PERSON, count($PHOTO) from
    instance-of($PERSON, op:Person),
    <tolog:if var="nouser">
    not(ph:hide($PERSON : ph:hidden)),
    </tolog:if>
    topic-name($PERSON, $TN), value($TN, $NAME),
    str:substring($INITIAL, $NAME, 0, 1),
    ph:depicted-in($PERSON : ph:depicted, $PHOTO : ph:depiction) 
  order by $INITIAL, $PERSON?
</tolog:query>

<tolog:foreach query='people-query' groupBy="INITIAL">

  <tr><td colspan=2><p><h2><a name="<tolog:out var="INITIAL"/>"
         ><tolog:out var="INITIAL"/></a></h2>

  <tolog:foreach>
    <tr><td><a href="person.jsp?id=<tolog:id var="PERSON"/>"
              ><tolog:out var="PERSON"/></a>&nbsp;&nbsp;&nbsp;
      <td><tolog:out var="PHOTO"/>
  </tolog:foreach>
</tolog:foreach>
</table>

</template:put>

</template:insert>
</tolog:context>
