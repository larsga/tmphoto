<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>

<template:insert template='template.jsp'>
<template:put name='title'>
Hidden page
</template:put>

<template:put name="body">

<p>Sorry, but you need to <a href="login.jsp">log in</a> to see this
page.

</template:put>

</template:insert>

