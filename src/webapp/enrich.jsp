<%@ include file="declarations.jsp"%>
<%@ include file="filterclass.jsp"%>

<tolog:context topicmap="metadata.xtm">
<%@ include file="tolog.jsp"%>
<%@ include file="handleuser.jsp"%>

<template:insert template='template.jsp'>
<template:put name='title'>
Loading average scores
</template:put>

<template:put name="body">

<%
  TopicMapIF tm = ContextUtils.getTopicMap(request);
  ScoreManager.getAverageVotes(tm);
%>

<p>Topic map has been enriched with average vote occurrences.

</template:put>
</template:insert>
</tolog:context>
