<%@ include file="declarations.jsp"%>
<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>

<template:insert template='template.jsp'>
<template:put name='title'>Search</template:put>

<template:put name="body">

<p>What are you looking for?</p>

<form method=get action=search-result.jsp>
<input name=search size=50 style="font-size: 140%">
<input type=submit value=Search style="font-size: 140%">
</form>
</template:put>
</template:insert>
</tolog:context>
