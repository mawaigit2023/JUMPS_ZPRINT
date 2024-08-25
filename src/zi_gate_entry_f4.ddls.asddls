@AbapCatalog.sqlViewName: 'ZV_GATE_ENTRY_F4'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate entry F4'
define view ZI_GATE_ENTRY_F4 as select distinct from ZI_GATE_ENTRY_REPORT as ge
{
  
 key ge.gentry_num,
 key ge.gentry_year
  
}
