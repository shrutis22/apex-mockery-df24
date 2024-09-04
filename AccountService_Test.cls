@isTest
private class AccountService_Test {
  @isTest
  static void whenCopyAddressToContacts_WithMocking() {
    Account testAccRec = new Account(
      Id = Mock.generateFakeId(Account.SObjectType),
      ShippingStreet = '1663 Liberty Drive'
    );
    Contact testConRec1 = new Contact(
      FirstName = 'Test',
      LastName = 'Contact 1',
      AccountId = testAccRec.Id
    );
    Contact testConRec2 = new Contact(
      FirstName = 'Test',
      LastName = 'Contact 2',
      AccountId = testAccRec.Id
    );

    // Arrange
    Mock daoMock = Mock.forType(DAO.class);
    DAO.mockInstance((DAO) daoMock.stub);

    MethodSpy querySpy = daoMock.spyOn('doQuery');
    querySpy.whenCalledWith(
        Argument.containsQuery('FROM Contact'),
        Argument.any(),
        Argument.any()
      )
      .thenReturn(new List<Contact>{ testConRec1, testConRec2 });

    MethodSpy contactDoUpdateSpy = daoMock.spyOn('doUpdate');
    contactDoUpdateSpy.whenCalledWith(
        Argument.any(),
        Argument.sObjectType(Contact.SObjectType)
      )
      .thenReturn(
        new List<Database.SaveResult>{
          Mock.generateFakeSaveResult(Contact.SObjectType)
        }
      );

    // Act
    AccountService service = new AccountService();
    List<Contact> updatedContacts = service.copyAddressToContacts(
      new List<Account>{ testAccRec }
    );

    //Assert
    Expect.that(querySpy).hasBeenCalledTimes(1);
    Expect.that(contactDoUpdateSpy).hasBeenCalledTimes(1);
    Assert.areEqual(updatedContacts.size(), 2);
  }

  @isTest
  static void whenCopyAddressToContacts_WithoutMocking() {
    Account testAccRec = new Account(
      Name = 'Test Account',
      ShippingStreet = '1663 Liberty Drive'
    );
    insert testAccRec;

    Contact testConRec1 = new Contact(
      FirstName = 'Test',
      LastName = 'Contact 1',
      AccountId = testAccRec.Id
    );
    Contact testConRec2 = new Contact(
      FirstName = 'Test',
      LastName = 'Contact 2',
      AccountId = testAccRec.Id
    );
    insert new List<Contact>{ testConRec1, testConRec2 };

    AccountService service = new AccountService();
    List<Contact> updatedContacts = service.copyAddressToContacts(
      new List<Account>{ testAccRec }
    );

    Assert.areEqual(updatedContacts.size(), 2);
  }
}
