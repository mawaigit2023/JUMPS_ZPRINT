@AbapCatalog.sqlViewName: 'ZV_DC_DISP'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'DC note display data'
define view ZI_DC_NOTE_DISP
  as select distinct from I_OperationalAcctgDocItem as dc
{

  key dc.CompanyCode,
  key dc.AccountingDocument,
  key dc.FiscalYear,
  key dc.PostingDate,
      dc.DocumentDate

}
