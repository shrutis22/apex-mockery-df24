public inherited sharing class DAO {
  private static DAO daoIns;

  public static DAO getInstance() {
    if (daoIns == null) {
      daoIns = new DAO();
    }
    return daoIns;
  }

  @TestVisible
  private static void mockInstance(DAO mockObj) {
    daoIns = mockObj;
  }

  public Database.SaveResult doInsert(
    SObject record,
    Schema.SObjectType sObjectType
  ) {
    return Database.insert(record);
  }

  public Database.SaveResult[] doInsert(
    List<SObject> records,
    Schema.SObjectType sObjectType
  ) {
    return Database.insert(records);
  }

  public Database.SaveResult doUpdate(
    SObject record,
    Schema.SObjectType sObjectType
  ) {
    return Database.update(record);
  }

  public Database.SaveResult[] doUpdate(
    List<SObject> records,
    Schema.SObjectType sObjectType
  ) {
    return Database.update(records);
  }

  public List<Database.UpsertResult> doUpsert(
    SObject[] records,
    SObjectField sObjField
  ) {
    return Database.upsert(records, sObjField);
  }

  public Database.DeleteResult doDelete(Id recordId) {
    return Database.delete(recordId);
  }

  public Database.DeleteResult[] doDelete(List<Id> recordIds) {
    return Database.delete(recordIds);
  }

  public List<SObject> doQuery(
    String query,
    Map<String, Object> binds,
    AccessLevel accessLevel
  ) {
    return Database.queryWithBinds(query, binds, accessLevel);
  }
}
