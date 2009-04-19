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
Categories
</template:put>

<template:put name="body">

<p><table>
<tolog:foreach query='
  select $CATEGORY, count($PHOTO) from
    instance-of($CATEGORY, op:Category),
    ph:in-category($CATEGORY : ph:categorization, $PHOTO : ph:categorized)
  order by $CATEGORY?'>

  <tr><td><a href="category.jsp?id=<tolog:id var="CATEGORY"/>"
            ><tolog:out var="CATEGORY"/></a>
      <td><tolog:out var="PHOTO"/>
</tolog:foreach>
</table>

</template:put>

</template:insert>
</tolog:context>
