@AbapCatalog.sqlViewName: 'ZV_SINST_PRINT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Invoice Print List'
define view ZI_SHIP_INST_PRINT as select distinct from ZI_PACK_LIST_DATA as pack
{

  key pack.pack_num,
  key pack.vbeln,
  key pack.erdate
      
}
