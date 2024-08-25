@AbapCatalog.sqlViewName: 'ZV_DELIVERY_DATA'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Delivery Data'
define view ZI_DELIVERY_DATA 
as select from I_DeliveryDocumentItem as ditem
{

key ditem.DeliveryDocument,
key ditem.DeliveryDocumentItem,
ditem.Material,
ditem.MaterialByCustomer,
ditem.Product,
ditem.BaseUnit,
ditem.DeliveryDocumentItemText,
ditem.HigherLevelItem,
ditem.HigherLvlItmOfBatSpltItm,
ditem.ActualDeliveryQuantity,
ditem.OriginalDeliveryQuantity,
ditem.DeliveryQuantityUnit,
ditem.ActualDeliveredQtyInBaseUnit,
ditem.ItemGrossWeight,
ditem.ItemNetWeight,
ditem.ItemWeightUnit,
ditem.ItemVolume,
ditem.ItemVolumeUnit,
ditem.Plant,
ditem.DistributionChannel
 
}
