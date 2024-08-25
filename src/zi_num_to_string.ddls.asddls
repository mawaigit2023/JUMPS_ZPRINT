@AbapCatalog.sqlViewName: 'ZV_NUM2STRING'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Number to string'
@Metadata.allowExtensions: true
define root view ZI_NUM_TO_STRING as select from zsd_num2string as NUM
{
    key NUM.num as Num,
    NUM.word as Word
}
