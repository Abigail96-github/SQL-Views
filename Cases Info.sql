-- public."PBIReport" source

CREATE OR REPLACE VIEW public."PBIReport"
AS SELECT DISTINCT ON (c.case_id) c.case_id,
    c.date_created,
    c.case_type_value,
    c.id,
    s.date_occurence,
    p.value AS "Process type",
    c.current_stage,
    c.current_stage_name,
    ff.value AS "Fraud Channel",
    ff2.value AS "Fraud Process",
    ff3.value AS "Fraud Source",
    fc.value AS "Customer Type",
    fp.value AS "Province",
    s.total_fraud,
    s.bank_loss,
    s.bank_recovery,
    s.third_party_loss,
    s.third_party_recovery,
    s.customer_loss,
    s.reported_date,
        CASE
            WHEN c.consolidation_id = s.customer_id THEN s.customer_value
            WHEN c.consolidation_id = s.branch_id THEN s.branch_value
            ELSE ''::character varying
        END AS consolidatedon,
    u.username AS "Assigned To",
    c.date_changed,
    c.status_value,
    c.due_date,
    ( SELECT count(*) + 1
           FROM generate_series(c.date_created, CURRENT_DATE::timestamp with time zone, '1 day'::interval) g(g)
          WHERE EXTRACT(isodow FROM g.g) < 6::numeric) AS "Case Aging",
    ( SELECT num_days_between(add_business_days(s.reported_date, p.days_to_due_date), now()::date) AS num_days_between) AS "CaseOverDue",
    ( SELECT add_business_days(s.reported_date, p.days_to_due_date) AS add_business_days) AS "StartDate"
   FROM fdm_case c
     LEFT JOIN fdm_entity ON c.consolidation_id = fdm_entity.id
     LEFT JOIN fdm_alert a ON a.case_id = c.id
     LEFT JOIN fdm_event e ON a.event_ptr_id = e.id
     LEFT JOIN fdm_user u ON u.id = c.assigned_to_id
     LEFT JOIN fdm_manualevent s ON e.id = s.event_ptr_id
     LEFT JOIN fdm_processtype p ON p.id = e.process_type_id
     LEFT JOIN fdm_fraudchannel ff ON s.fraud_channel_id = ff.id
     LEFT JOIN fdm_fraudprocess ff2 ON s.fraud_process_id = ff2.id
     LEFT JOIN fdm_fraudsource ff3 ON s.fraud_source_id = ff3.id
     LEFT JOIN fdm_customertype fc ON s.customer_type_id = fc.id
     LEFT JOIN fdm_province fp ON s.province_id = fp.id
  WHERE c.due_date::character varying::text <> 'NULL'::text
  ORDER BY c.case_id, c.date_changed DESC;