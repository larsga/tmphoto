<%!

public class FilteredList {
  private TopicMapIF topicmap;
  private String query;
  private String sort;
  private String main;
  private ContextTag contextTag;
  private Map filters;
  private TopicIF filter;
  private List rows;
  private int pageno;
  private int pagecount;

  public FilteredList(PageContext pageContext, String query, String sort,
                      String main, String var) 
    throws InvalidQueryException {
    this.query = query;
    this.sort  = sort;
    this.main  = main;
    this.topicmap = (TopicMapIF) 
      ContextUtils.getSingleValue("topicmap", pageContext);
    this.filter = (TopicIF) ContextUtils.getSingleValue("filter", pageContext);
    this.contextTag = FrameworkUtils.getContextTag(pageContext);
    this.filters = new HashMap();
    this.rows = build();
    this.pagecount = (getRowCount() / 50) + 1;
    this.pageno = 1;
    if (pageContext.getRequest().getParameter("n") != null)
      this.pageno = Integer.parseInt(pageContext.getRequest().getParameter("n"));
    if (pageno > pagecount)
      this.pageno = 1;

    weed();
    setSlice((pageno-1) * 50, pageno * 50);
  }

  public Collection getFilters() { 
    return filters.values();
  }

  public int getRowCount() {
    return rows.size();
  } 

  public boolean getHasMultiplePages() {
    return pagecount > 1;
  }

  public List getRows() {
    return rows;
  }

  private void setSlice(int start, int end) {
    if (end > rows.size())
      end = rows.size();
    rows = rows.subList(start, end);
  }

  public PageList getPageList() {
    return new PageList(pageno, pagecount);
  }

  private List build() throws InvalidQueryException {
    List rows = new ArrayList();

    // build initial list
    String fullquery = query;
    if (sort != null)
      fullquery += " order by " + sort;
    fullquery += "?";

    ContextManagerIF contextManager = contextTag.getContextManager();
    QueryProcessorIF proc = QueryUtils.getQueryProcessor(topicmap);
    QueryResultIF result = proc.execute(fullquery, 
                        new ContextManagerScopingMapWrapper(contextManager),
                        contextTag.getDeclarationContext());
    int mainix = result.getIndex(main);
    while (result.next()) {
      if (!filter((TopicIF) result.getValue(mainix)))
        continue;
      Map row = new HashMap();
      for (int ix = 0; ix < result.getWidth(); ix++)
        row.put(result.getColumnName(ix), result.getValue(ix));
      rows.add(row);
    }

    return rows;
  }

  private boolean filter(TopicIF topic) {
    boolean result = (filter == null);
    Iterator it = topic.getRoles().iterator();
    while (it.hasNext()) {
      AssociationRoleIF role = (AssociationRoleIF) it.next();
      AssociationIF assoc = role.getAssociation();
      Iterator it2 = assoc.getRoles().iterator();
      AssociationRoleIF role2 = null;
      while (it2.hasNext()) {
        AssociationRoleIF tmp = (AssociationRoleIF) it2.next();
        if (tmp != role) {
          role2 = tmp;
          break;
        }
      }

      TopicIF player = null;
      if (role2 != null)
        player = role2.getPlayer();

      if (filter == null) {
        if (player != null)
          addToIndex(role.getType(), assoc.getType(), player);
      } else if (filter == player)
        result = true;
    }
    return result;
  }

  private void addToIndex(TopicIF roletype, TopicIF assoctype, TopicIF player){
    String key = getKey(roletype, assoctype, player);
    Filter filter = (Filter) filters.get(key);
    if (filter == null) {
      filter = new Filter(roletype, assoctype);
      filters.put(key, filter);
    }
    filter.addTopic(player);
  }

  private void weed() {
    // make another pass to remove useless filters/counters
    Iterator it = filters.values().iterator();
    while (it.hasNext()) {
      Filter f = (Filter) it.next();
      f.weedOutCounters(this);
      if (f.isEmpty() || f.getType() == null)
        it.remove();
    }
  }

  private String getKey(TopicIF roletype, TopicIF assoctype, TopicIF player){
    //return roletype.getObjectId() + "$" + assoctype.getObjectId();
    Iterator it = player.getTypes().iterator();
    if (it.hasNext()) {
      TopicIF type = (TopicIF) it.next();
      return type.getObjectId();
    } else
      return "null";
  }
}

public class Filter {
  private TopicIF roletype;
  private TopicIF assoctype;
  private Map topics;
  private TopicIF type;

  public Filter(TopicIF roletype, TopicIF assoctype) {
    this.roletype = roletype;
    this.assoctype = assoctype;
    this.topics = new HashMap();
  }

  public boolean isEmpty() {
    return topics.isEmpty();
  }

  public List getTopics() {
    ArrayList list = new ArrayList(topics.values());
    Collections.sort(list);
    return list;
  }

  public TopicIF getRoleType() {
    return roletype;
  }

  public TopicIF getAssociationType() {
    return assoctype;
  }

  public TopicIF getType() {
    return type;
  }

  public void addTopic(TopicIF topic) {
    // update count
    Counter c = (Counter) topics.get(topic);
    if (c == null) {
      c = new Counter(topic);
      topics.put(topic, c);
    }
    c.count();

    // update type
    if (type == null && !topic.getTypes().isEmpty())
      type = (TopicIF) topic.getTypes().iterator().next();
  }

  public void weedOutCounters(FilteredList list) {
    Iterator it = topics.values().iterator();
    while (it.hasNext()) {
      Counter c = (Counter) it.next();
      if (c.getCount() >= list.getRowCount())
        it.remove();
    }
  }
}

public static class Counter implements Comparable {
  private static Comparator comp;
  private TopicIF topic;
  private int count;

  { // static initializer
    StringifierIF strify = TopicStringifiers.getDefaultStringifier();
    comp = TopicComparators.getCaseInsensitiveComparator(strify);
  }

  public Counter(TopicIF topic) {
    this.topic = topic;
  }

  public void count() {
    count++;
  }   

  public int getCount() {
    return count;
  }

  public TopicIF getTopic() {
    return topic;
  }

  public int compareTo(Object other) {
    Counter oc = (Counter) other;
    return comp.compare(topic, oc.getTopic());
  }
}

public static class PageList {
  private int curpageno;
  private int pagecount;
  private List pages;

  public PageList(int curpageno, int pagecount) {
    this.curpageno = curpageno;
    this.pagecount = pagecount;
    this.pages = new ArrayList(pagecount);
    for (int ix = 1; ix <= pagecount; ix++)
      pages.add(new Page(ix, ix == curpageno));
  }

  public boolean getMorePages() {
    return pagecount > 1;
  }

  public boolean getShowBackButton() {
    return curpageno > 1;
  }

  public int getPrevious() {
    return curpageno - 1;
  }

  public boolean getShowNextButton() {
    return curpageno < pagecount;
  }

  public int getNext() {
    return curpageno + 1;
  }

  public List getPages() {
    return pages;
  }
}

public static class Page {
  private int pageno;
  private boolean current;

  public Page(int pageno, boolean current) {
    this.pageno = pageno;
    this.current = current;
  }

  public boolean getCurrent() {
    return current;
  }

  public int getPageNumber() {
    return pageno;
  }
}
%>
