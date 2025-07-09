SELECT 
    OBJECT_SCHEMA_NAME(d.referencing_id) AS referencing_schema_name,
    OBJECT_NAME(d.referencing_id) AS referencing_object_name,
    o.type_desc AS Referencing_Object_Type,
    d.referencing_class_desc,
    d.referenced_class_desc,
    d.referenced_entity_name
FROM 
    sys.sql_expression_dependencies d
JOIN 
    sys.objects o ON d.referencing_id = o.object_id
WHERE 
    d.referenced_entity_name = 'TYPE_INSURANCE_PREMIUM_RATE_DETL';
