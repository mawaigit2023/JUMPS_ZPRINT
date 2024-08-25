@AbapCatalog.sqlViewName: 'ZV_DC_NOTE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'DC Note'
define view ZI_DC_NOTE
  as select from    I_OperationalAcctgDocItem as dc
    left outer join I_JournalEntry            as bkpf on  bkpf.AccountingDocument = dc.AccountingDocument
                                                      and bkpf.CompanyCode        = dc.CompanyCode
                                                      and bkpf.FiscalYear         = dc.FiscalYear
{

  key dc.CompanyCode,
  key dc.AccountingDocument,
  key dc.FiscalYear,
  key dc.AccountingDocumentItem,
      dc.FinancialAccountType,
      dc.ChartOfAccounts,
      dc.AccountingDocumentItemType,
      dc.PostingKey,
      dc.Material,
      dc.Product,
      dc.Plant,
      dc.PostingDate,
      dc.DocumentDate,
      dc.DebitCreditCode,
      dc.TaxCode,
      dc.TaxItemGroup,
      dc.TransactionTypeDetermination, //CGST, SGST code
      dc.GLAccount,
      dc.Customer,
      dc.Supplier,
      dc.PurchasingDocument,
      dc.PurchasingDocumentItem,
      dc.PurchaseOrderQty,
      dc.ProfitCenter,
      dc.DocumentItemText,
      dc.AmountInCompanyCodeCurrency,
      dc.AmountInTransactionCurrency,

      dc.CashDiscountBaseAmount,
      dc.NetPaymentAmount,

      dc.AssignmentReference,
      dc.InvoiceReference,
      dc.InvoiceReferenceFiscalYear,
      dc.InvoiceItemReference,


      dc.Quantity,
      dc.BaseUnit,
      dc.MaterialPriceUnitQty,
      dc.TaxBaseAmountInTransCrcy,

      dc.ClearingAccountingDocument,
      dc.ClearingDate,
      dc.ClearingCreationDate,
      dc.ClearingJournalEntryFiscalYear,
      dc.ClearingDocFiscalYear,
      dc.ClearingItem,
      dc.HouseBank,
      dc.BPBankAccountInternalID,
      dc.HouseBankAccount,
      dc.IN_HSNOrSACCode,

      bkpf.DocumentReferenceID


}
