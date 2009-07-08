<%@ page language="java" 
           import="net.ontopia.topicmaps.query.utils.TologSpy" %>
<style>th, .event { vertical-align: top; text-align: left } td { vertical-align: top; text-align: right }</style>
<%
TologSpy.setIsRecording(true);
TologSpy.generateReport(out);
%>
