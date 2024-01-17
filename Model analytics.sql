-- public."ModelAnalytic_Alerts" source

CREATE OR REPLACE VIEW public."ModelAnalytic_Alerts"
AS SELECT c.id,
    c.date_created,
    c.case_type_value,
    p.value AS "Process type",
    c.case_id,
    c.current_stage,
    c.current_stage_name,
        CASE
            WHEN c.consolidation_id = s.customer_id THEN s.customer_value
            WHEN c.consolidation_id = s.branch_id THEN s.branch_value
            ELSE ''::character varying
        END AS consolidatedon,
    u.username AS "Assigned To",
    c.date_changed,
    c.status_value,
    c.due_date,
    ( SELECT count(*) - 1 AS count
           FROM generate_series(c.due_date::timestamp with time zone, CURRENT_DATE::timestamp with time zone, '1 day'::interval) g(g)
          WHERE EXTRACT(isodow FROM g.g) < 6::numeric) AS "OverDue",
    ( SELECT count(*) + 1
           FROM generate_series(c.date_created, CURRENT_DATE::timestamp with time zone, '1 day'::interval) g(g)
          WHERE EXTRACT(isodow FROM g.g) < 6::numeric) AS "Case Aging",
    date_trunc('minute'::text, c.date_created) - date_trunc('minute'::text, c.date_changed) AS touched
   FROM fdm_case c
     LEFT JOIN fdm_entity ON c.consolidation_id = fdm_entity.id
     LEFT JOIN fdm_alert a ON a.case_id = c.id
     LEFT JOIN fdm_event e ON a.event_ptr_id = e.id
     LEFT JOIN fdm_user u ON u.id = c.assigned_to_id
     LEFT JOIN fdm_manualevent s ON e.id = s.event_ptr_id
     LEFT JOIN fdm_processtype p ON p.id = e.process_type_id
  WHERE p.value::text ~~ '%Alert%'::text
  ORDER BY c.date_changed DESC;