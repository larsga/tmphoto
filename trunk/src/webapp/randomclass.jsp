<%!

static class SelectRandomly {

  public static TopicIF selectAtRandom(String variable,
                                       PageContext pageContext) {
    List topics = new ArrayList(ContextUtils.getValue(variable, pageContext));
    Random rnd = new Random();
    int ix = rnd.nextInt(topics.size());
    return (TopicIF) topics.get(ix);
  }

  public static int count(String variable, PageContext pageContext) {
    List topics = new ArrayList(ContextUtils.getValue(variable, pageContext));
    return topics.size();
  }

}
%>
