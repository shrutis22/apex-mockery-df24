public with sharing class AccountService {
  private DAO daoIns = DAO.getInstance();

  public List<Contact> copyAddressToContacts(List<Account> updatedAccounts) {
    SOQLBuilder builder = new SOQLBuilder(Contact.SObjectType)
      .selectFields(new List<String>{ 'AccountId' })
      .setWhereClause('AccountId = :updatedAccounts')
      .setBindVariable('updatedAccounts', updatedAccounts);

    List<Contact> childContacts = this.daoIns.doQuery(
      builder.getQuery(),
      builder.getBinds(),
      AccessLevel.USER_MODE
    );

    Map<Id, List<Contact>> accountIdToContacts = new Map<Id, List<Contact>>();
    for (Contact childContact : childContacts) {
      if (accountIdToContacts.containsKey(childContact.AccountId)) {
        accountIdToContacts.get(childContact.AccountId).add(childContact);
        continue;
      }

      accountIdToContacts.put(
        childContact.AccountId,
        new List<Contact>{ childContact }
      );
    }

    List<Contact> contactsToUpdate = new List<Contact>();
    for (Account updatedAccount : updatedAccounts) {
      if (!accountIdToContacts.containsKey(updatedAccount.Id)) {
        continue;
      }

      for (Contact childContact : accountIdToContacts.get(updatedAccount.Id)) {
        copyAddress(childContact, updatedAccount);
        contactsToUpdate.add(childContact);
      }
    }

    if (!contactsToUpdate.isEmpty()) {
      this.daoIns.doUpdate(contactsToUpdate, Contact.SObjectType);
      return contactsToUpdate;
    }

    return null;
  }

  private void copyAddress(Contact childContact, Account updatedAccount) {
    childContact.OtherStreet = updatedAccount.ShippingStreet;
    childContact.OtherCity = updatedAccount.ShippingCity;
    childContact.OtherState = updatedAccount.ShippingState;
    childContact.OtherCountry = updatedAccount.ShippingCountry;
    childContact.OtherPostalCode = updatedAccount.ShippingPostalCode;
  }
}
