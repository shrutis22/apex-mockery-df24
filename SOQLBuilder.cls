public class SOQLBuilder {
  public enum Aggregate {
    COUNT,
    COUNT_DISTINCT,
    SUM,
    MIN,
    MAX
  }

  private final String NO_FIELDS_PROVIDED = 'No fields provided to query';

  private final String SECURITY_ENFORCED_CLAUSE = ' WITH SECURITY_ENFORCED';
  private final String SOQL_SELECT = 'SELECT ';
  private final String SOQL_FROM = ' FROM ';
  private final String SOQL_WHERE = ' WHERE ';
  private final String SOQL_GROUPBY = ' GROUP BY ';
  private final String SOQL_ORDERBY = ' ORDER BY ';
  private final String SOQL_LIMIT = ' LIMIT ';
  private final String SOQL_OFFSET = ' OFFSET ';
  private final String SOQL_FOR_UPDATE = ' FOR UPDATE';
  private final String SOQL_FOR_VIEW = ' FOR VIEW';
  private final String SOQL_FOR_REFERENCE = ' FOR REFERENCE';

  private Schema.SObjectType sObjectType;
  private List<String> fieldStrings = new List<String>();
  private List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
  private List<Schema.FieldSet> fieldSets = new List<Schema.FieldSet>();
  private Boolean securityEnforced = false;
  private String whereClause;
  private String orderClause;
  private String groupClause;
  private Integer rowLimit;
  private Integer rowOffset;
  private Boolean forUpdate = false;
  private Boolean forView = false;
  private Boolean forReference = false;

  private Map<String, Object> binds = new Map<String, Object>();
  private Set<String> aggregates = new Set<String>();

  public SOQLBuilder(Schema.SObjectType sObjectType) {
    this.sObjectType = sObjectType;
  }

  public SOQLBuilder addAggregate(
    Aggregate aggregate,
    String field,
    String alias
  ) {
    this.aggregates.add(this.getAggregateExpression(aggregate, field, alias));
    return this;
  }

  public List<String> getAggregates() {
    return new List<String>(this.aggregates);
  }

  public String getAggregateExpression(
    Aggregate aggregate,
    String field,
    String alias
  ) {
    return String.format(
      '{0}({1}) {2}',
      new List<Object>{ aggregate.name(), field, alias }
    );
  }

  public SOQLBuilder selectField(String field) {
    return this.selectFields(new List<String>{ field });
  }

  public SOQLBuilder selectFields(List<String> fields) {
    this.fieldStrings.addAll(fields);
    return this;
  }

  public List<String> getFields() {
    return this.fieldStrings;
  }

  public SOQLBuilder selectField(Schema.SObjectField sObjectField) {
    return this.selectFields(new List<Schema.SObjectField>{ sObjectField });
  }

  public SOQLBuilder selectFields(List<Schema.SObjectField> sObjectFields) {
    this.fields.addAll(sObjectFields);
    return this;
  }

  public List<Schema.SObjectField> getSObjectFields() {
    return this.fields;
  }

  public SOQLBuilder selectField(Schema.FieldSet fieldSet) {
    return this.selectFields(new List<Schema.FieldSet>{ fieldSet });
  }

  public SOQLBuilder selectFields(List<Schema.FieldSet> fieldSets) {
    this.fieldSets.addAll(fieldSets);
    return this;
  }

  public List<Schema.FieldSet> getFieldSets() {
    return this.fieldSets;
  }

  public Schema.SObjectType getSObjectType() {
    return this.sObjectType;
  }

  public SOQLBuilder setWhereClause(String whereClause) {
    this.whereClause = whereClause;
    return this;
  }

  public String getWhereClause() {
    return this.whereClause;
  }

  public SOQLBuilder setSecurityEnforced(Boolean securityEnforced) {
    this.securityEnforced = securityEnforced;
    return this;
  }

  public Boolean getSecurityEnforced() {
    return this.securityEnforced;
  }

  public SOQLBuilder setForUpdate(Boolean forUpdate) {
    this.forUpdate = forUpdate;
    return this;
  }

  public Boolean getForUpdate() {
    return this.forUpdate;
  }

  public SOQLBuilder setForView(Boolean forView) {
    this.forView = forView;
    return this;
  }

  public Boolean getForView() {
    return this.forView;
  }

  public SOQLBuilder setForReference(Boolean forReference) {
    this.forReference = forReference;
    return this;
  }

  public Boolean getForReference() {
    return this.forReference;
  }

  public SOQLBuilder setRowLimit(Integer rowLimit) {
    this.rowLimit = rowLimit;
    return this;
  }

  public Integer getRowLimit() {
    return this.rowLimit;
  }

  public SOQLBuilder setOrderClause(String orderClause) {
    this.orderClause = orderClause;
    return this;
  }

  public String getOrderClause() {
    return this.orderClause;
  }

  public SOQLBuilder setGroupClause(String groupClause) {
    this.groupClause = groupClause;
    return this;
  }

  public String getGroupClause() {
    return this.groupClause;
  }

  public SOQLBuilder setOffset(Integer rowOffset) {
    this.rowOffset = rowOffset;
    return this;
  }

  public Integer getOffset() {
    return this.rowOffset;
  }

  public SOQLBuilder setBindVariable(String key, Object value) {
    this.binds.put(key, value);
    return this;
  }

  public Map<String, Object> getBinds() {
    return this.binds;
  }

  private String getBaseQuery() {
    set<String> fieldStrings = new Set<String>();
    for (Schema.SObjectField field : this.getSObjectFields()) {
      Schema.DescribeFieldResult iDescribe = field.getDescribe();
      fieldStrings.add(iDescribe.getName().toLowerCase());
    }
    for (String field : this.getFields()) {
      fieldStrings.add(field?.toLowerCase());
    }
    for (Schema.FieldSet fieldSet : this.getFieldSets()) {
      for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
        fieldStrings.add(fsm.getFieldPath().toLowerCase());
      }
    }
    fieldStrings.addAll(this.getAggregates());

    if (fieldStrings.size() == 0) {
      throw new QueryException(NO_FIELDS_PROVIDED);
    }

    String baseQuery =
      SOQL_SELECT +
      String.join(new List<String>(fieldStrings), ',') +
      SOQL_FROM +
      this.getSObjectType().getDescribe().getName();

    return baseQuery;
  }

  /**
   * @description Returns the query predicate based on the various clauses
   * (i.e. WHERE, ORDER BY, LIMIT, OFFSET)
   * @param SOQLBuilder SOQLBuilder object representing query details
   */
  private String getPredicate() {
    String predicateString = '';
    if (!String.isBlank(this.getWhereClause()))
      predicateString += SOQL_WHERE + this.getWhereClause();
    if (!String.isBlank(this.getGroupClause()))
      predicateString += SOQL_GROUPBY + this.getGroupClause();
    if (!String.isBlank(this.getOrderClause()))
      predicateString += SOQL_ORDERBY + this.getOrderClause();
    if (this.getSecurityEnforced())
      predicateString += SECURITY_ENFORCED_CLAUSE;
    if (this.getRowLimit() != null)
      predicateString += SOQL_LIMIT + String.valueOf(this.getRowLimit());
    if (this.getOffset() != null)
      predicateString += SOQL_OFFSET + String.valueOf(this.getOffset());
    if (this.getForReference())
      predicateString += SOQL_FOR_REFERENCE;
    if (this.getForView())
      predicateString += SOQL_FOR_VIEW;
    if (this.getForUpdate())
      predicateString += SOQL_FOR_UPDATE;
    return predicateString;
  }

  /**
   * @description Returns the fully formed query defined by all inputs to the DAO
   * base class, including fields, where clause, order clause, row limits, etc...
   * @param SOQLBuilder SOQLBuilder object representing query details
   */
  public String getQuery() {
    String queryString = this.getBaseQuery();
    queryString += this.getPredicate();
    system.debug(queryString);
    return queryString;
  }

  public Boolean equals(Object ref) {
    SOQLBuilder refSoql = (SOQLBuilder) ref;
    return this.getQuery() == refSoql.getQuery();
  }

  public override String toString() {
    return this.getQuery();
  }
}
