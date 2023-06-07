SELECT
    table_profile.sensitivity_score.score as sensitivity_score,
    table_profile.data_risk_level.score as risk_score,
    table_profile.encryption_status as encryption_status,
    CONCAT(
        CASE
            WHEN STRING_AGG(info_types.info_type.name) IS NULL THEN ''
            ELSE STRING_AGG(info_types.info_type.name)
        END,
        CASE
            WHEN STRING_AGG(other_info_types.info_type.name) IS NULL THEN ''
            ELSE STRING_AGG(other_info_types.info_type.name)
        END
    ) as info_types,
    table_profile.profile_last_generated.seconds as ts_seconds,
    table_profile.profile_last_generated.nanos as ts_nanos
FROM
    `jayoleary-670-2023042614091300.central_dlp_data.dlp_data_profiles_latest_v1`
    LEFT OUTER JOIN UNNEST(table_profile.predicted_info_types) AS info_types
    LEFT OUTER JOIN UNNEST(table_profile.other_info_types) AS other_info_types
WHERE
    table_profile.dataset_id = 'customer_data_product'
    and table_profile.table_id = 'customer_data'
    and table_profile.dataset_project_id = 'jayoleary-670-2023042614091300'
group by
    sensitivity_score,
    risk_score,
    encryption_status,
    ts_seconds,
    ts_nanos