<%!

public class FilterContext {
  private TopicIF topic;
  private String date;

  public FilterContext(PageContext pageContext) {
    String filter = (String)
      pageContext.getAttribute("filter", PageContext.SESSION_SCOPE);
    if (filter == null || filter.equals(""))
      return;

    if (filter.startsWith("topic:")) {
      TopicMapIF topicmap = (TopicMapIF) 
        ContextUtils.getSingleValue("topicmap", pageContext);
      LocatorIF base = topicmap.getStore().getBaseAddress();
      LocatorIF itemid = base.resolveAbsolute("#" + filter.substring(6));
      topic = (TopicIF) topicmap.getObjectByItemIdentifier(itemid);
    } else if (filter.startsWith("date:"))
      date = filter.substring(5);
    else
      throw new RuntimeException("Unknown filter type: '" + filter + "'");
  }

  public boolean getSet() {
    return topic != null || date != null;
  }

  public String getLabel() {
    if (topic != null)
      return TopicStringifiers.toString(topic);
    else
      return date;
  }

  public TopicIF getTopic() {
    return topic;
  }

  public String getDate() {
    return date;
  }
}

public class FilteredList {
  private TopicMapIF topicmap;
  private String query;
  private String sort;
  private String main;
  private ContextTag contextTag;
  private Map filters;
  private FilterContext context;
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
    this.context = (FilterContext) pageContext.getRequest().getAttribute("filter");
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
    boolean result = !context.getSet();
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

      if (!context.getSet()) {
        if (player != null)
          addToIndex(role.getType(), assoc.getType(), player);
      } else if (context.getTopic() == player)
        result = true;
    }

    it = topic.getOccurrences().iterator();
    while (it.hasNext()) {
      OccurrenceIF occ = (OccurrenceIF) it.next();
      if (!isDate(occ.getValue()))
        continue;

      if (!context.getSet())
        addToIndex(occ.getType(), occ.getValue());
      else if (context.getDate() != null && 
               matchesDate(occ.getValue(), context.getDate()))
        result = true;
    }

    return result;
  }

  private boolean matchesDate(String realdate, String filterdate) {
    if (filterdate.endsWith(":xx:xx"))
      filterdate = filterdate.substring(0, 13);
    else if (filterdate.endsWith(":xx"))
      filterdate = filterdate.substring(0, 16);

    return realdate.startsWith(filterdate);
  }

  private boolean isDate(String value) {
    // FIXME: this won't do...
    if (value.length() < 10)
      return false;
    return ((value.charAt(0) == '1' || value.charAt(0) == '2') &&
            (value.charAt(1) >= '0' && value.charAt(1) <= '9'));
  }

  private void addToIndex(TopicIF roletype, TopicIF assoctype, TopicIF player) {
    String key = getKey(roletype, assoctype, player);
    AssociationFilter filter = (AssociationFilter) filters.get(key);
    if (filter == null) {
      filter = new AssociationFilter(roletype, assoctype);
      filters.put(key, filter);
    }
    filter.addTopic(player);
  }

  private void addToIndex(TopicIF occtype, String value) {
    String key = getKey(occtype, value);
    DateFilter filter = (DateFilter) filters.get(key);
    if (filter == null) {
      filter = new DateFilter(occtype);
      filters.put(key, filter);
    }
    filter.addDate(value);
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

  private String getKey(TopicIF roletype, TopicIF assoctype, TopicIF player) {
    Iterator it = player.getTypes().iterator();
    if (it.hasNext()) {
      TopicIF type = (TopicIF) it.next();
      return type.getObjectId();
    } else
      return "null";
  }

  private String getKey(TopicIF occtype, String value) {
    return occtype.getObjectId();
  }
}

public abstract class Filter {
  protected Map counters;

  public Filter() {
    this.counters = new HashMap();
  }

  public boolean isEmpty() {
    return counters.isEmpty();
  }

  public List getCounters() {
    ArrayList list = new ArrayList(counters.values());
    Collections.sort(list);
    return list;
  }

  public void weedOutCounters(FilteredList list) {
    Iterator it = counters.values().iterator();
    while (it.hasNext()) {
      Counter c = (Counter) it.next();
      if (c.getCount() >= list.getRowCount())
        it.remove();
    }
  }

  public abstract TopicIF getType();
}

public class AssociationFilter extends Filter {
  private TopicIF roletype;
  private TopicIF assoctype;
  private TopicIF type;

  public AssociationFilter(TopicIF roletype, TopicIF assoctype) {
    this.roletype = roletype;
    this.assoctype = assoctype;
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
    Counter c = (Counter) counters.get(topic);
    if (c == null) {
      c = new TopicCounter(topic);
      counters.put(topic, c);
    }
    c.count();

    // update type
    if (type == null && !topic.getTypes().isEmpty())
      type = (TopicIF) topic.getTypes().iterator().next();
  }
}

public class DateFilter extends Filter {
  private TopicIF occtype;
  private List dates; // simple list of date strings

  public DateFilter(TopicIF occtype) {
    this.occtype = occtype;
    this.dates = new ArrayList();
  }

  public TopicIF getType() {
    return occtype;
  }

  /**
   * Adds a datetime actually found in the topic map. This is later weeded
   * to produce the values used for filtering.
   */
  public void addDate(String value) {
    dates.add(value);
  }

  public void weedOutCounters(FilteredList list) {
    int[] lengths = new int[] { 16, 13, 10, 7, 4};
    // 16: 2009-01-01 12:00
    // 13: 2009-01-01 12
    // 10: 2009-01-01
    // 7: 2009-01
    // 4: 2009

    Map prevcounters = null;
    for (int length = 0; length < lengths.length; length++) {
      prevcounters = counters;
      counters = new HashMap();
      for (int ix = 0; ix < dates.size(); ix++) {
        String date = (String) dates.get(ix);
        if (date.length() >= lengths[length])
          date = date.substring(0, lengths[length]);
        addValue(date);
      }
      if (counters.size() < 15)
        break;
    }

    if (counters.size() == 1)
      counters = prevcounters;
  }

  /**
   * Adds a weeded value to potentially be used for filtering. Potentially
   * because we might reduce the lengths to get fewer values.
   */
  private void addValue(String value) {
    // 2009-01-01 12 and 2009-01-01 12:00 is kind of awkward, so we pad these
    // with (:xx)?:xx
    if (value.length() == 13)
      value += ":xx:xx";
    else if (value.length() == 16)
      value += ":xx";

    // update count
    Counter c = (Counter) counters.get(value);
    if (c == null) {
      c = new StringCounter("date", value);
      counters.put(value, c);
    }
    c.count();
  }
}

public static abstract class Counter implements Comparable {
  protected int count;

  public void count() {
    count++;
  }   

  public int getCount() {
    return count;
  }

  public abstract String getId();
  public abstract String getLabel();
}

public static class TopicCounter extends Counter {
  private static StringifierIF strify;
  private TopicIF topic;

  { // static initializer
    strify = TopicStringifiers.getDefaultStringifier();
  }

  public TopicCounter(TopicIF topic) {
    this.topic = topic;
  }

  public String getId() {
    Iterator it = topic.getItemIdentifiers().iterator();
    while (it.hasNext()) {
      LocatorIF loc = (LocatorIF) it.next();
      String uri = loc.getAddress();
      int pos = uri.indexOf('#');
      if (pos == -1)
        continue;
      return "topic:" + uri.substring(pos + 1);
    }
    return "topic:" + topic.getObjectId();
  }

  public String getLabel() {
    return strify.toString(topic);
  }

  public int compareTo(Object other) {
    TopicCounter oc = (TopicCounter) other;
    return getLabel().compareTo(oc.getLabel());
  }
}

public static class StringCounter extends Counter {
  private String prefix;
  private String string;

  public StringCounter(String prefix, String string) {
    this.prefix = prefix;
    this.string = string;
  }

  public String getLabel() {
    return string;
  }

  public String getId() {
    return prefix + ":" + string;
  }

  public int compareTo(Object other) {
    StringCounter oc = (StringCounter) other;
    return string.compareTo(oc.string);
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
