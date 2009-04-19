<%
  response.setStatus(404);
%>
<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>

<template:insert template='template.jsp'>
<template:put name='title'>
No such <%= request.getParameter("what") %>
</template:put>

<template:put name="body">

<p>No such <%= request.getParameter("what") %> found in the topic map.
There are two possibilities:

<ul>
  <li>It used to exist, but now it has been deleted.
  <li>The ID at the end of the address is wrong.
</ul>

<p>Sorry.

</template:put>

</template:insert>
