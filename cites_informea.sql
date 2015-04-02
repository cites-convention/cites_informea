--
-- Contacts views
--
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_contacts` AS
  SELECT
    `a`.`uuid` AS `id`,
    ucase(`iso2`.`field_country_iso2_value`) AS `country`,
    NULL AS `prefix`,
    `line1`.`field_contact_line_1_value` AS `firstName`,
    NULL AS `lastName`,
    NULL AS `position`,
    `line2`.`field_contact_line_2_value` AS `institution`,
    NULL AS `department`,
    `addr`.`field_contact_address_value` AS `address`,
    `email`.`field_contact_email_value` AS `email`,
    `phone`.`field_contact_telephone_value` AS `phoneNumber`,
    `fax`.`field_contact_fax_value` AS `fax`,
    1 AS `primary`,
    date_format(from_unixtime(`a`.`created`),'%Y-%m-%d %H:%i:%s') AS `updated`
  FROM `cites`.`node` `a`
  INNER JOIN `cites`.`field_data_field_contact_actual` `country` on `country`.`entity_id` = `a`.`nid`
  INNER JOIN `cites`.`field_data_field_country_iso2` `iso2` on `country`.`field_contact_actual_target_id` = `iso2`.`entity_id`
  LEFT JOIN `cites`.`field_data_field_contact_line_1` `line1` on (`line1`.`entity_id` = `a`.`nid` and `line1`.`language` = 'en')
  LEFT JOIN `cites`.`field_data_field_contact_line_2` `line2` on (`line2`.`entity_id` = `a`.`nid` and `line2`.`language` = 'en')
  LEFT JOIN `cites`.`field_data_field_contact_address` `addr` on (`addr`.`entity_id` = `a`.`nid` and `addr`.`language` = 'en')
  LEFT JOIN `cites`.`field_data_field_contact_email` `email` on (`email`.`entity_id` = `a`.`nid` and `email`.`language` = 'en')
  LEFT JOIN `cites`.`field_data_field_contact_telephone` `phone` on (`phone`.`entity_id` = `a`.`nid` and `phone`.`language` = 'en')
  LEFT JOIN `cites`.`field_data_field_contact_fax` `fax` on (`fax`.`entity_id` = `a`.`nid` and `fax`.`language` = 'en')
    WHERE `a`.`type` = 'cites_contact'
    GROUP BY `a`.`uuid`;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_contacts_treaties` AS
  SELECT
    concat(`a`.`uuid`,'-cites') AS `id`,
    `a`.`uuid` AS `contact_id`,
    'cites' AS `treaty`
  FROM `cites`.`node` `a`
    WHERE `a`.`type` = 'cites_contact';
--
-- National reports
--
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_country_reports` AS
  SELECT
    `a`.`uuid` AS `id`,
    'cites' AS `treaty`,
    ucase(`h`.`field_country_iso3_value`) AS `country`,
    `f`.`field_report_date_value` AS `submission`,
    concat('http://cites.org/node/',`a`.`nid`) AS `url`,
    date_format(from_unixtime(`a`.`created`),'%Y-%m-%d %H:%i:%s') AS `updated`
  FROM `cites`.`node` `a`
  INNER JOIN `cites`.`field_data_field_report_date` `f` on `f`.`entity_id` = `a`.`nid`
  INNER JOIN `cites`.`field_data_field_report_country` `g` on `g`.`entity_id` = `a`.`nid`
  INNER JOIN `cites`.`field_data_field_country_iso3` `h` on `g`.`field_report_country_target_id` = `h`.`entity_id`
    WHERE `a`.`type` = 'biennial_report'
    GROUP BY `a`.`uuid`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_country_reports_title` AS
  SELECT
    concat(`a`.`uuid`,'-',`b`.`language`) AS `id`,
    `a`.`uuid` AS `country_report_id`,
    `b`.`language` AS `language`,
    `b`.`title_field_value` AS `title`
  FROM `cites`.`node` `a`
  INNER JOIN `cites`.`field_data_title_field` `b` on (`a`.`nid` = `b`.`entity_id` and `a`.`type` = 'biennial_report');

--
-- Decisions
--
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions` AS
  SELECT
    `a`.`uuid` AS `id`,
    concat('http://www.cites.org/node/',`a`.`nid`) AS `link`,
    lcase(`b1`.`name`) AS `type`,
    'active' AS `status`,`d`.
    `field_document_no_value` AS `number`,
    'cites' AS `treaty`,
    date_format(from_unixtime(`a`.`created`),'%Y-%m-%d %H:%i:%s') AS `published`,
    date_format(from_unixtime(`a`.`changed`),'%Y-%m-%d %H:%i:%s') AS `updated`,
    `g1`.`uuid` AS `meetingId`,
    NULL AS `meetingTitle`,
    NULL AS `meetingUrl`
  FROM `cites`.`node` `a`
  INNER JOIN `cites`.`field_data_field_document_type` `b` on `b`.`entity_id` = `a`.`nid`
  INNER JOIN `cites`.`taxonomy_term_data` `b1` on `b`.`field_document_type_tid` = `b1`.`tid`
  LEFT JOIN  `cites`.`field_data_field_document_status` `c` on `c`.`entity_id` = `a`.`nid`
  LEFT JOIN  `cites`.`taxonomy_term_data` `c1` on `c`.`field_document_status_tid` = `c1`.`tid`
  LEFT JOIN  `cites`.`field_data_field_document_no` `d` on `d`.`entity_id` = `a`.`nid`
  LEFT JOIN  `cites`.`field_data_field_document_cop_meeting` `g` on `g`.`entity_id` = `a`.`nid`
  INNER JOIN `cites`.`node` `g1` on `g`.`field_document_cop_meeting_target_id` = `g1`.`nid`
    WHERE `a`.`type` = 'document'
      AND lcase(`b1`.`name` in ('decision', 'resolution')
      AND (isnull(`c1`.`name`) or (`c1`.`name` <> 'Invalid'))
  GROUP BY `a`.`uuid`;


CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_content` AS
  SELECT
    concat(`a`.`uuid`,`b`.`language`) AS `id`,
    `a`.`uuid` AS `decision_id`,
    `b`.`language` AS `language`,
    `b`.`body_value` AS `content`
  FROM `cites`.`node` `a`
  LEFT JOIN `cites`.`field_data_body` `b` on `b`.`entity_id` = `a`.`nid`
  INNER JOIN `cites`.`field_data_field_document_type` `t` on `t`.`entity_id` = `a`.`nid`
  INNER JOIN `cites`.`taxonomy_term_data` `t1` on `t`.`field_document_type_tid` = `t1`.`tid`
    WHERE `a`.`type` = 'document'
      AND lcase(`t1`.`name`) = 'decision';

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_documents` AS
  SELECT  NULL AS `id`,NULL AS `decision_id`,NULL AS `diskPath`,NULL AS `url`,NULL AS `mimeType`,NULL AS `language`,NULL AS `filename` limit 0;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_keywords` AS
  SELECT NULL AS `id`,NULL AS `decision_id`,NULL AS `namespace`,NULL AS `term` limit 0;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_longtitle` AS
  SELECT NULL AS `id`,NULL AS `decision_id`,NULL AS `language`,NULL AS `long_title` limit 0;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_summary` AS
  SELECT NULL AS `id`,NULL AS `decision_id`,NULL AS `language`,NULL AS `summary` limit 0;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_decisions_title` AS
  SELECT
    concat(`a`.`uuid`,'-',`b`.`language`) AS `id`,
    `a`.`uuid` AS `decision_id`,
    `b`.`language` AS `language`,
    `b`.`title_field_value` AS `title`
  FROM `cites`.`node` `a`
  INNER JOIN `cites`.`field_data_title_field` `b` on `b`.`entity_id` = `a`.`nid`
  INNER JOIN `cites`.`field_data_field_document_type` `t` on `t`.`entity_id` = `a`.`nid`
  INNER JOIN `cites`.`taxonomy_term_data` `t1` on `t`.`field_document_type_tid` = `t1`.`tid`
    WHERE `a`.`type` = 'document'
      AND lcase(`t1`.`name`) in ('decision','resolution')
      AND `b`.`language` = 'en')
    ORDER BY `b`.`language`;

--
-- Meetings
--
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_meetings` AS
  SELECT
    `a`.`uuid` AS `id`,'cites' AS `treaty`,
    concat('http://cites.org/eng/cop/index.php') AS `url`,
    `mdates`.`field_meeting_date_value` AS `start`,
    `mdates`.`field_meeting_date_value2` AS `end`,
    NULL AS `repetition`,
    NULL AS `kind`,
    lcase(`tt`.`name`) AS `type`,
    NULL AS `access`,
    NULL AS `status`,
    NULL AS `imageUrl`,
    NULL AS `imageCopyright`,
    `loc`.`field_meeting_location_value` AS `location`,
    `city`.`field_meeting_city_value` AS `city`,
    `iso2`.`field_country_iso2_value` AS `country`,
    NULL AS `latitude`,
    NULL AS `longitude`,
    date_format(from_unixtime(`a`.`changed`),'%Y-%m-%d %H:%i:%s') AS `updated`
  FROM `cites`.`node` `a`
    INNER JOIN `cites`.`field_data_field_meeting_date` `mdates` on `a`.`nid` = `mdates`.`entity_id`
    INNER JOIN `cites`.`field_data_field_meeting_type` `t` on `a`.`nid` = `t`.`entity_id`
    INNER JOIN `cites`.`taxonomy_term_data` `tt` on `t`.`field_meeting_type_tid` = `tt`.`tid`
    LEFT JOIN  `cites`.`field_data_field_meeting_location` `loc` on `a`.`nid` = `loc`.`entity_id`
    LEFT JOIN  `cites`.`field_data_field_meeting_city` `city` on `a`.`nid` = `city`.`entity_id`
    LEFT JOIN  `cites`.`field_data_field_meeting_country` `cnt` on `a`.`nid` = `cnt`.`entity_id`
    LEFT JOIN  `cites`.`field_data_field_country_iso2` `iso2` on `cnt`.`field_meeting_country_target_id` = `iso2`.`entity_id`
      WHERE `a`.`type` = 'meeting'
      GROUP BY `a`.`uuid`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_meetings_description` AS
  SELECT
    concat(`a`.`uuid`,`b`.`language`) AS `id`,
    `a`.`uuid` AS `meeting_id`,
    `b`.`language` AS `language`,
    `b`.`body_value` AS `description`
  FROM `cites`.`node` `a`
  INNER JOIN `cites`.`field_data_body` `b` on (`a`.`nid` = `b`.`entity_id` AND `a`.`type` = 'meeting'
    WHERE `b`.`body_value` IS NOT NULL
      AND trim(`b`.`body_value`) <> '';

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informea_meetings_title` AS
  SELECT
    concat(`a`.`uuid`,`b`.`language`) AS `id`,
    `a`.`uuid` AS `meeting_id`,
    `b`.`language` AS `language`,
    `b`.`title_field_value` AS `title`
  FROM `cites`.`node` `a`
    INNER JOIN `cites`.`field_data_title_field` `b` on (`a`.`nid` = `b`.`entity_id` and `a`.`type` = 'meeting');