<%@ page language="java" 
    import="
    java.io.*,
    java.util.*,
    net.ontopia.topicmaps.entry.*,
    net.ontopia.topicmaps.core.*,
    net.ontopia.topicmaps.nav2.core.*,
    net.ontopia.topicmaps.nav2.utils.*" 
%>
<%@ taglib uri='http://psi.ontopia.net/jsp/taglib/logic'    prefix='logic'    %>
<logic:context>
<%
// avoid caching
response.setHeader("Cache-control", "no-cache");

// retrieve configuration
String id = "metadata.xtm";
NavigatorApplicationIF navApp = NavigatorUtils.getNavigatorApplication(pageContext);
NavigatorConfigurationIF navConf = navApp.getConfiguration();
TopicMapRepositoryIF repository = navApp.getTopicMapRepository();
TopicMapReferenceIF ref = repository.getReferenceByKey(id);

if (ref.isOpen()) ref.close();
ref.open();
%>
<p>Topic map is reloaded.</p>
</logic:context>
