@AbapCatalog.sqlViewName: 'ZV_PO_DATA'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Data'
define view ZI_PO_DATA 
as select from I_PurchaseOrderItemAPI01 as ekpo

left outer join I_PurchaseOrderAPI01 as ekko
on ekpo.PurchaseOrder = ekko.PurchaseOrder

left outer join I_ProductDescription as makt
on makt.Product = ekpo.Material and makt.Language = 'E'
{
 
 key ekpo.PurchaseOrder,
 key ekpo.PurchaseOrderItem,
 ekpo.OrderQuantity,
 ekpo.OverdelivTolrtdLmtRatioInPct,
 ekpo.Material,
 ekpo.Plant, 
 ekko.Customer,
 ekko.Supplier,
 ekko.ValidityStartDate,
 ekko.ValidityEndDate,
 makt.ProductDescription,
 ekpo.OrderPriceUnit,
 ekpo.NetAmount,
 ekpo.BaseUnit
 
// ekpo.MaterialGroup,
// ekpo.Material,
// ekpo.MaterialType,
// ekpo.SupplierMaterialNumber,
// ekpo.StorageLocation,
// ekpo.PurchaseOrderQuantityUnit,
// ekpo.NetPriceQuantity,
// ekpo.OrderPriceUnit,
// ekpo.ItemVolumeUnit,
// ekpo.ItemWeightUnit,
// ekpo.NetAmount,
// ekpo.GrossAmount,
// ekpo.OrderQuantity,
// ekpo.OrderPriceUnitToOrderUnitNmrtr,
// ekpo.OrdPriceUnitToOrderUnitDnmntr,
// ekpo.OverallLimitAmount,

    
}
where 
ekpo.PurchasingDocumentDeletionCode = '' and 
ekpo.IsCompletelyDelivered  = ''


