--
-- Contacts views
--
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_contacts` AS
  SELECT
    a.uuid AS id,
    ucase(iso2.field_country_iso2_value) AS country,
    NULL AS prefix,
    line1.field_contact_line_1_value AS firstName,
    NULL AS lastName,
    NULL AS `position`,
    line2.field_contact_line_2_value AS institution,
    NULL AS department,
    NULL AS type,
    addr.field_contact_address_value AS address,
    email.field_contact_email_value AS email,
    phone.field_contact_telephone_value AS phoneNumber,
    fax.field_contact_fax_value AS fax,
    1 AS `primary`,
    date_format(from_unixtime(a.created),'%Y-%m-%d %H:%i:%s') AS updated
  FROM cites.node a
  INNER JOIN `cites`.field_data_field_contact_actual country ON country.entity_id = a.nid
  INNER JOIN `cites`.field_data_field_country_iso2 iso2 ON country.field_contact_actual_target_id = iso2.entity_id
  LEFT JOIN `cites`.field_data_field_contact_line_1 line1 ON (line1.entity_id = a.nid AND line1.`language` = 'en')
  LEFT JOIN `cites`.field_data_field_contact_line_2 line2 ON (line2.entity_id = a.nid AND line2.`language` = 'en')
  LEFT JOIN `cites`.field_data_field_contact_address addr ON (addr.entity_id = a.nid AND addr.`language` = 'en')
  LEFT JOIN `cites`.field_data_field_contact_email email ON (email.entity_id = a.nid AND email.`language` = 'en')
  LEFT JOIN `cites`.field_data_field_contact_telephone phone ON (phone.entity_id = a.nid AND phone.`language` = 'en')
  LEFT JOIN `cites`.field_data_field_contact_fax fax ON (fax.entity_id = a.nid AND fax.`language` = 'en')
    WHERE a.`type` = 'cites_contact'
    GROUP BY a.uuid;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_contacts_treaties` AS
  SELECT
    concat(a.uuid,'-cites') AS id,
    a.uuid AS contact_id,
    'cites' AS treaty
  FROM cites.node a
    WHERE a.`type` = 'cites_contact';

--
-- National reports
--
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_country_reports` AS
  SELECT
    a.uuid AS id,
    'cites' AS treaty,
    ucase(h.field_country_iso3_value) AS country,
    f.field_report_date_value AS submission,
    CAST(concat('http://cites.org/node/', a.nid) AS CHAR) AS url,
    date_format(from_unixtime(a.created),'%Y-%m-%d %H:%i:%s') AS updated
  FROM `cites`.node a
    INNER JOIN `cites`.field_data_field_report_date f ON f.entity_id = a.nid
    INNER JOIN `cites`.field_data_field_report_country g ON g.entity_id = a.nid
    INNER JOIN `cites`.field_data_field_country_iso3 h ON g.field_report_country_target_id = h.entity_id
    WHERE a.`type` = 'biennial_report'
  GROUP BY a.uuid;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_country_reports_title` AS
  SELECT
    concat(a.uuid,'-',b.`language`) AS id,
    a.uuid AS country_report_id,
    b.`language` AS `language`,
    b.title_field_value AS title
  FROM `cites`.node a
    INNER JOIN `cites`.field_data_title_field b ON (a.nid = b.entity_id AND a.`type` = 'biennial_report')
  ORDER BY b.`language`;

-- informea_country_reports_documents
CREATE OR REPLACE DEFINER =`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_country_reports_documents` AS
  SELECT
    CAST(CONCAT(ra.language, '-', n.nid) AS CHAR) AS id,
    n.uuid AS country_report_id,
    CONCAT('sites/default/files/', REPLACE(f2.uri, 'public://', '')) AS diskPath,
    CONCAT('http://www.cites.org/sites/default/files/', REPLACE(f2.uri, 'public://', '')) AS url,
    f2.filemime AS mimeType,
    ra.language AS `language`,
    f2.filename AS filename
  FROM `cites`.node n
    INNER JOIN `cites`.field_data_field_report_attachment ra ON n.nid = ra.entity_id
    INNER JOIN `cites`.file_managed f2 ON f2.fid = ra.field_report_attachment_fid
  WHERE
    n.status = 1
    AND n.type = 'biennial_report'
  ORDER BY ra.language;


--
-- Decisions
--
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions` AS
  SELECT
    a.uuid AS id,
    CAST(concat('http://www.cites.org/node/', a.nid) AS CHAR) AS link,
    lcase(b1.name) AS `type`,
    'active' AS `status`,
    d.field_document_no_value AS number,
    'cites' AS treaty,
    date_format(from_unixtime(a.created),'%Y-%m-%d %H:%i:%s') AS published,
    date_format(from_unixtime(a.changed),'%Y-%m-%d %H:%i:%s') AS updated,
    g1.uuid AS meetingId,
    NULL AS meetingTitle,
    NULL AS meetingUrl
  FROM `cites`.node a
  INNER JOIN `cites`.field_data_field_document_type b ON b.entity_id = a.nid
  INNER JOIN `cites`.taxonomy_term_data b1 ON b.field_document_type_tid = b1.tid
  LEFT JOIN  `cites`.field_data_field_document_status c ON c.entity_id = a.nid
  LEFT JOIN  `cites`.taxonomy_term_data c1 ON c.field_document_status_tid = c1.tid
  LEFT JOIN  `cites`.field_data_field_document_no d ON d.entity_id = a.nid
  LEFT JOIN  `cites`.field_data_field_document_cop_meeting g ON g.entity_id = a.nid
  INNER JOIN `cites`.node g1 ON g.field_document_cop_meeting_target_id = g1.nid
    WHERE a.`type` = 'document'
      AND lcase(b1.name) IN ('decision', 'resolution')
      AND (isnull(c1.name) OR (c1.name <> 'Invalid'))
  GROUP BY a.uuid;


CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_content` AS
  SELECT
    concat(a.uuid,b.`language`) AS id,
    a.uuid AS decision_id,
    b.`language` AS `language`,
    b.body_value AS content
  FROM `cites`.node a
  LEFT JOIN `cites`.field_data_body b ON b.entity_id = a.nid
  INNER JOIN `cites`.field_data_field_document_type t ON t.entity_id = a.nid
  INNER JOIN `cites`.taxonomy_term_data t1 ON t.field_document_type_tid = t1.tid
    WHERE a.`type` = 'document'
      AND lcase(t1.name) = 'decision';

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_documents` AS
  SELECT
    CONCAT(a.uuid, '-', f2.fid, '-', c.`language`) AS id,
    a.uuid  AS decision_id,
    CONCAT('sites/default/files/', REPLACE(f2.uri, 'public://', ''))      AS diskPath,
    CONCAT('http://www.cites.org/sites/default/files/', REPLACE(f2.uri, 'public://', '')) AS url,
    f2.filemime AS mimeType,
    c.`language` AS LANGUAGE,
    f2.filename  AS filename
  FROM `cites`.node a
    INNER JOIN `cites`.field_data_field_document_type b ON a.nid = b.entity_id
    INNER JOIN `cites`.field_data_field_document_files c ON a.nid = c.entity_id
    INNER JOIN `cites`.file_managed f2 ON f2.fid = c.field_document_files_fid
  WHERE
    a.`status` = 1
    AND a.`type` = 'document';

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_keywords` AS
  SELECT
    NULL AS id,
    NULL AS decision_id,
    NULL AS namespace,
    NULL AS term
  LIMIT 0;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_longtitle` AS
  SELECT
    NULL AS id,
    NULL AS decision_id,
    NULL AS `language`,
    NULL AS long_title
  LIMIT 0;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_summary` AS
  SELECT
    NULL AS id,
    NULL AS decision_id,
    NULL AS `language`,
    NULL AS summary
  LIMIT 0;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_title` AS
  SELECT
    concat(a.uuid, '-', b.`language`) AS id,
    a.uuid AS decision_id,
    b.`language` AS `language`,
    b.title_field_value AS title
  FROM `cites`.node a
  INNER JOIN `cites`.field_data_title_field b ON b.entity_id = a.nid
  INNER JOIN `cites`.field_data_field_document_type t ON t.entity_id = a.nid
  INNER JOIN `cites`.taxonomy_term_data t1 ON t.field_document_type_tid = t1.tid
    WHERE a.`type` = 'document'
      AND lcase(t1.name) IN ('decision','resolution')
    ORDER BY b.`language`;

--
-- Meetings
--
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_meetings` AS
  SELECT
    a.uuid AS id,
    'cites' AS treaty,
    concat('http://cites.org/eng/cop/index.php') AS url,
    mdates.field_meeting_date_value AS start,
    mdates.field_meeting_date_value2 AS `end`,
    NULL AS repetition,
    NULL AS kind,
    lcase(tt.name) AS `type`,
    NULL AS access,
    NULL AS status,
    NULL AS imageUrl,
    NULL AS imageCopyright,
    loc.field_meeting_location_value AS location,
    city.field_meeting_city_value AS city,
    iso2.field_country_iso2_value AS country,
    NULL AS latitude,
    NULL AS longitude,
    date_format(from_unixtime(a.changed),'%Y-%m-%d %H:%i:%s') AS updated
  FROM `cites`.node a
    INNER JOIN `cites`.field_data_field_meeting_date mdates ON a.nid = mdates.entity_id
    INNER JOIN `cites`.field_data_field_meeting_type t ON a.nid = t.entity_id
    INNER JOIN `cites`.taxonomy_term_data tt ON t.field_meeting_type_tid = tt.tid
    LEFT JOIN  `cites`.field_data_field_meeting_location loc ON a.nid = loc.entity_id
    LEFT JOIN  `cites`.field_data_field_meeting_city city ON a.nid = city.entity_id
    LEFT JOIN  `cites`.field_data_field_meeting_country cnt ON a.nid = cnt.entity_id
    LEFT JOIN  `cites`.field_data_field_country_iso2 iso2 ON cnt.field_meeting_country_target_id = iso2.entity_id
      WHERE a.`type` = 'meeting'
      GROUP BY a.uuid;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_meetings_description` AS
  SELECT
    concat(a.uuid, b.`language`) AS id,
    a.uuid AS meeting_id,
    b.`language` AS `language`,
    b.body_value AS description
  FROM `cites`.node a
  INNER JOIN `cites`.field_data_body b ON (a.nid = b.entity_id AND a.`type` = 'meeting')
    WHERE b.body_value IS NOT NULL
      AND trim(b.body_value) <> '';

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_meetings_title` AS
  SELECT
    concat(a.uuid, b.`language`) AS id,
    a.uuid AS meeting_id,
    b.`language` AS `language`,
    b.title_field_value AS title
  FROM `cites`.node a
    INNER JOIN `cites`.field_data_title_field b ON (a.nid = b.entity_id AND a.`type` = 'meeting');
