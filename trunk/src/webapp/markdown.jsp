<%@ include file="declarations.jsp"%>
<%@ include file="randomclass.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>

<template:insert template='template.jsp'>
<template:put name='title'>
  Formatting comments
</template:put>

<template:put name="body">

<%-- LEFT-HAND CELL --%>
<table width="100%"><tr><td>

<p>Comments are written in 
<a href="http://daringfireball.net/projects/markdown/syntax">Markdown</a>
format, so if you are familiar with that you need read no further.</p>

<p>Some examples of formatting:</p>

<table>
<tr><th>Result <td> <th>Syntax
<tr><td><a href="http://example.org/">An example</a> 
    <td>&nbsp;&nbsp;&nbsp;
    <td>[An example](http://example.org/)
<tr><td><em>italics</em> <td>&nbsp;&nbsp;&nbsp;<td>*italics*
<tr><td><strong>bold</strong> <td>&nbsp;&nbsp;&nbsp;<td>**bold**
</table>

<p>There is more, but I think this should suffice for most comments.

<%-- RIGHT-HAND CELL --%>
<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<td>
<table align=right>
<tr><td>
<%@ include file="randomphoto.jsp"%>

<tr><td colspan=2>&nbsp;
</table>

</table> <%-- END --%>
</template:put>

</template:insert>
</tolog:context>
