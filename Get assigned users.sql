-- public."PBIAssigned" source

CREATE OR REPLACE VIEW public."PBIAssigned"
AS SELECT DISTINCT ON (c.case_id) c.case_id,
    c.id,
    c.date_created,
    c.due_date,
    c.date_changed,
    c.case_type_value AS "Case type",
    p.value AS "Process type",
    c.current_stage,
    c.current_stage_name,
        CASE
            WHEN c.consolidation_id = s.customer_id THEN s.customer_value
            WHEN c.consolidation_id = s.branch_id THEN s.branch_value
            ELSE ''::character varying
        END AS consolidatedon,
    u.username AS "Assigned To",
    c.status_value,
    ad."timestamp",
    ad.changes
   FROM fdm_case c
     LEFT JOIN fdm_entity ON c.consolidation_id = fdm_entity.id
     LEFT JOIN fdm_alert a ON a.case_id = c.id
     LEFT JOIN fdm_event e ON a.event_ptr_id = e.id
     LEFT JOIN fdm_user u ON u.id = c.assigned_to_id
     LEFT JOIN fdm_manualevent s ON e.id = s.event_ptr_id
     LEFT JOIN fdm_processtype p ON p.id = e.process_type_id
     LEFT JOIN auditlog_logentry ad ON ad.object_pk::text = c.id::text
  WHERE ad.changes ~~ '%"assigned_to": ["None"%'::text
  ORDER BY c.case_id, ad."timestamp" DESC;