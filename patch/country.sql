-- Load data into table
-- LOAD DATA LOCAL
-- INFILE 'GEODATASOURCE-CITIES-FREE.TXT'
-- INTO TABLE `world_cities_free`
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\r\n'
-- IGNORE 1 LINES;

-- Create table "country"
CREATE TABLE `country`(
	`cc_fips` VARCHAR(2),
	`cc_iso` VARCHAR(2),
	`tld` VARCHAR(3),
	`country_name` VARCHAR(100),
	INDEX `idx_cc_fips`(`cc_fips`),
	INDEX `idx_cc_iso`(`cc_iso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- Insert country data
INSERT INTO `country` VALUES
	('AA', 'AW', '.aw', 'Aruba'),
	('AC', 'AG', '.ag', 'Antigua and Barbuda'),
	('AE', 'AE', '.ae', 'United Arab Emirates'),
	('AF', 'AF', '.af', 'Afghanistan'),
	('AG', 'DZ', '.dz', 'Algeria'),
	('AJ', 'AZ', '.az', 'Azerbaijan'),
	('AL', 'AL', '.al', 'Albania'),
	('AM', 'AM', '.am', 'Armenia'),
	('AN', 'AD', '.ad', 'Andorra'),
	('AO', 'AO', '.ao', 'Angola'),
	('AQ', 'AS', '.as', 'American Samoa'),
	('AR', 'AR', '.ar', 'Argentina'),
	('AS', 'AU', '.au', 'Australia'),
	('AT', '-', '-', 'Ashmore and Cartier Islands'),
	('AU', 'AT', '.at', 'Austria'),
	('AV', 'AI', '.ai', 'Anguilla'),
	('AX', 'AX', '.ax', 'Åland Islands'),
	('AY', 'AQ', '.aq', 'Antarctica'),
	('BA', 'BH', '.bh', 'Bahrain'),
	('BB', 'BB', '.bb', 'Barbados'),
	('BC', 'BW', '.bw', 'Botswana'),
	('BD', 'BM', '.bm', 'Bermuda'),
	('BE', 'BE', '.be', 'Belgium'),
	('BF', 'BS', '.bs', 'Bahamas, The'),
	('BG', 'BD', '.bd', 'Bangladesh'),
	('BH', 'BZ', '.bz', 'Belize'),
	('BK', 'BA', '.ba', 'Bosnia and Herzegovina'),
	('BL', 'BO', '.bo', 'Bolivia'),
	('BM', 'MM', '.mm', 'Myanmar'),
	('BN', 'BJ', '.bj', 'Benin'),
	('BO', 'BY', '.by', 'Belarus'),
	('BP', 'SB', '.sb', 'Solomon Islands'),
	('BQ', '-', '-', 'Navassa Island'),
	('BR', 'BR', '.br', 'Brazil'),
	('BS', '-', '-', 'Bassas da India'),
	('BT', 'BT', '.bt', 'Bhutan'),
	('BU', 'BG', '.bg', 'Bulgaria'),
	('BV', 'BV', '.bv', 'Bouvet Island'),
	('BX', 'BN', '.bn', 'Brunei'),
	('BY', 'BI', '.bi', 'Burundi'),
	('CA', 'CA', '.ca', 'Canada'),
	('CB', 'KH', '.kh', 'Cambodia'),
	('CD', 'TD', '.td', 'Chad'),
	('CE', 'LK', '.lk', 'Sri Lanka'),
	('CF', 'CG', '.cg', 'Congo, Republic of the'),
	('CG', 'CD', '.cd', 'Congo, Democratic Republic of the'),
	('CH', 'CN', '.cn', 'China'),
	('CI', 'CL', '.cl', 'Chile'),
	('CJ', 'KY', '.ky', 'Cayman Islands'),
	('CK', 'CC', '.cc', 'Cocos (Keeling) Islands'),
	('CM', 'CM', '.cm', 'Cameroon'),
	('CN', 'KM', '.km', 'Comoros'),
	('CO', 'CO', '.co', 'Colombia'),
	('CQ', 'MP', '.mp', 'Northern Mariana Islands'),
	('CR', '-', '-', 'Coral Sea Islands'),
	('CS', 'CR', '.cr', 'Costa Rica'),
	('CT', 'CF', '.cf', 'Central African Republic'),
	('CU', 'CU', '.cu', 'Cuba'),
	('CV', 'CV', '.cv', 'Cape Verde'),
	('CW', 'CK', '.ck', 'Cook Islands'),
	('CY', 'CY', '.cy', 'Cyprus'),
	('DA', 'DK', '.dk', 'Denmark'),
	('DJ', 'DJ', '.dj', 'Djibouti'),
	('DO', 'DM', '.dm', 'Dominica'),
	('DQ', 'UM', '-', 'Jarvis Island'),
	('DR', 'DO', '.do', 'Dominican Republic'),
	('DX', '-', '-', 'Dhekelia Sovereign Base Area'),
	('EC', 'EC', '.ec', 'Ecuador'),
	('EG', 'EG', '.eg', 'Egypt'),
	('EI', 'IE', '.ie', 'Ireland'),
	('EK', 'GQ', '.gq', 'Equatorial Guinea'),
	('EN', 'EE', '.ee', 'Estonia'),
	('ER', 'ER', '.er', 'Eritrea'),
	('ES', 'SV', '.sv', 'El Salvador'),
	('ET', 'ET', '.et', 'Ethiopia'),
	('EU', '-', '-', 'Europa Island'),
	('EZ', 'CZ', '.cz', 'Czech Republic'),
	('FG', 'GF', '.gf', 'French Guiana'),
	('FI', 'FI', '.fi', 'Finland'),
	('FJ', 'FJ', '.fj', 'Fiji'),
	('FK', 'FK', '.fk', 'Falkland Islands (Islas Malvinas)'),
	('FM', 'FM', '.fm', 'Micronesia, Federated States of'),
	('FO', 'FO', '.fo', 'Faroe Islands'),
	('FP', 'PF', '.pf', 'French Polynesia'),
	('FQ', 'UM', '-', 'Baker Island'),
	('FR', 'FR', '.fr', 'France'),
	('FS', 'TF', '.tf', 'French Southern and Antarctic Lands'),
	('GA', 'GM', '.gm', 'Gambia, The'),
	('GB', 'GA', '.ga', 'Gabon'),
	('GG', 'GE', '.ge', 'Georgia'),
	('GH', 'GH', '.gh', 'Ghana'),
	('GI', 'GI', '.gi', 'Gibraltar'),
	('GJ', 'GD', '.gd', 'Grenada'),
	('GK', '-', '.gg', 'Guernsey'),
	('GL', 'GL', '.gl', 'Greenland'),
	('GM', 'DE', '.de', 'Germany'),
	('GO', '-', '-', 'Glorioso Islands'),
	('GP', 'GP', '.gp', 'Guadeloupe'),
	('GQ', 'GU', '.gu', 'Guam'),
	('GR', 'GR', '.gr', 'Greece'),
	('GT', 'GT', '.gt', 'Guatemala'),
	('GV', 'GN', '.gn', 'Guinea'),
	('GY', 'GY', '.gy', 'Guyana'),
	('GZ', '-', '-', 'Gaza Strip'),
	('HA', 'HT', '.ht', 'Haiti'),
	('HK', 'HK', '.hk', 'Hong Kong'),
	('HM', 'HM', '.hm', 'Heard Island and McDonald Islands'),
	('HO', 'HN', '.hn', 'Honduras'),
	('HQ', 'UM', '-', 'Howland Island'),
	('HR', 'HR', '.hr', 'Croatia'),
	('HU', 'HU', '.hu', 'Hungary'),
	('IC', 'IS', '.is', 'Iceland'),
	('ID', 'ID', '.id', 'Indonesia'),
	('IM', 'IM', '.im', 'Isle of Man'),
	('IN', 'IN', '.in', 'India'),
	('IO', 'IO', '.io', 'British Indian Ocean Territory'),
	('IP', '-', '-', 'Clipperton Island'),
	('IR', 'IR', '.ir', 'Iran'),
	('IS', 'IL', '.il', 'Israel'),
	('IT', 'IT', '.it', 'Italy'),
	('IV', 'CI', '.ci', 'Cote d\'Ivoire'),
	('IZ', 'IQ', '.iq', 'Iraq'),
	('JA', 'JP', '.jp', 'Japan'),
	('JE', 'JE', '.je', 'Jersey'),
	('JM', 'JM', '.jm', 'Jamaica'),
	('JN', 'SJ', '-', 'Jan Mayen'),
	('JO', 'JO', '.jo', 'Jordan'),
	('JQ', 'UM', '-', 'Johnston Atoll'),
	('JU', '-', '-', 'Juan de Nova Island'),
	('KE', 'KE', '.ke', 'Kenya'),
	('KG', 'KG', '.kg', 'Kyrgyzstan'),
	('KN', 'KP', '.kp', 'Korea, North'),
	('KQ', 'UM', '-', 'Kingman Reef'),
	('KR', 'KI', '.ki', 'Kiribati'),
	('KS', 'KR', '.kr', 'Korea, South'),
	('KT', 'CX', '.cx', 'Christmas Island'),
	('KU', 'KW', '.kw', 'Kuwait'),
	('KV', 'KV', '-', 'Kosovo'),
	('KZ', 'KZ', '.kz', 'Kazakhstan'),
	('LA', 'LA', '.la', 'Laos'),
	('LE', 'LB', '.lb', 'Lebanon'),
	('LG', 'LV', '.lv', 'Latvia'),
	('LH', 'LT', '.lt', 'Lithuania'),
	('LI', 'LR', '.lr', 'Liberia'),
	('LO', 'SK', '.sk', 'Slovakia'),
	('LQ', 'UM', '-', 'Palmyra Atoll'),
	('LS', 'LI', '.li', 'Liechtenstein'),
	('LT', 'LS', '.ls', 'Lesotho'),
	('LU', 'LU', '.lu', 'Luxembourg'),
	('LY', 'LY', '.ly', 'Libyan Arab'),
	('MA', 'MG', '.mg', 'Madagascar'),
	('MB', 'MQ', '.mq', 'Martinique'),
	('MC', 'MO', '.mo', 'Macau'),
	('MD', 'MD', '.md', 'Moldova, Republic of'),
	('MF', 'YT', '.yt', 'Mayotte'),
	('MG', 'MN', '.mn', 'Mongolia'),
	('MH', 'MS', '.ms', 'Montserrat'),
	('MI', 'MW', '.mw', 'Malawi'),
	('MJ', 'ME', '.me', 'Montenegro'),
	('MK', 'MK', '.mk', 'The Former Yugoslav Republic of Macedonia'),
	('ML', 'ML', '.ml', 'Mali'),
	('MN', 'MC', '.mc', 'Monaco'),
	('MO', 'MA', '.ma', 'Morocco'),
	('MP', 'MU', '.mu', 'Mauritius'),
	('MQ', 'UM', '-', 'Midway Islands'),
	('MR', 'MR', '.mr', 'Mauritania'),
	('MT', 'MT', '.mt', 'Malta'),
	('MU', 'OM', '.om', 'Oman'),
	('MV', 'MV', '.mv', 'Maldives'),
	('MX', 'MX', '.mx', 'Mexico'),
	('MY', 'MY', '.my', 'Malaysia'),
	('MZ', 'MZ', '.mz', 'Mozambique'),
	('NC', 'NC', '.nc', 'New Caledonia'),
	('NE', 'NU', '.nu', 'Niue'),
	('NF', 'NF', '.nf', 'Norfolk Island'),
	('NG', 'NE', '.ne', 'Niger'),
	('NH', 'VU', '.vu', 'Vanuatu'),
	('NI', 'NG', '.ng', 'Nigeria'),
	('NL', 'NL', '.nl', 'Netherlands'),
	('NM', '', '', 'No Man\'s Land'),
	('NO', 'NO', '.no', 'Norway'),
	('NP', 'NP', '.np', 'Nepal'),
	('NR', 'NR', '.nr', 'Nauru'),
	('NS', 'SR', '.sr', 'Suriname'),
	('NT', 'AN', '.an', 'Netherlands Antilles'),
	('NU', 'NI', '.ni', 'Nicaragua'),
	('NZ', 'NZ', '.nz', 'New Zealand'),
	('PA', 'PY', '.py', 'Paraguay'),
	('PC', 'PN', '.pn', 'Pitcairn Islands'),
	('PE', 'PE', '.pe', 'Peru'),
	('PF', '-', '-', 'Paracel Islands'),
	('PG', '-', '-', 'Spratly Islands'),
	('PK', 'PK', '.pk', 'Pakistan'),
	('PL', 'PL', '.pl', 'Poland'),
	('PM', 'PA', '.pa', 'Panama'),
	('PO', 'PT', '.pt', 'Portugal'),
	('PP', 'PG', '.pg', 'Papua New Guinea'),
	('PS', 'PW', '.pw', 'Palau'),
	('PU', 'GW', '.gw', 'Guinea-Bissau'),
	('QA', 'QA', '.qa', 'Qatar'),
	('RE', 'RE', '.re', 'Reunion'),
	('RI', 'RS', '.rs', 'Serbia'),
	('RM', 'MH', '.mh', 'Marshall Islands'),
	('RN', 'MF', '-', 'Saint Martin'),
	('RO', 'RO', '.ro', 'Romania'),
	('RP', 'PH', '.ph', 'Philippines'),
	('RQ', 'PR', '.pr', 'Puerto Rico'),
	('RS', 'RU', '.ru', 'Russia'),
	('RW', 'RW', '.rw', 'Rwanda'),
	('SA', 'SA', '.sa', 'Saudi Arabia'),
	('SB', 'PM', '.pm', 'Saint Pierre and Miquelon'),
	('SC', 'KN', '.kn', 'Saint Kitts and Nevis'),
	('SE', 'SC', '.sc', 'Seychelles'),
	('SF', 'ZA', '.za', 'South Africa'),
	('SG', 'SN', '.sn', 'Senegal'),
	('SH', 'SH', '.sh', 'Saint Helena'),
	('SI', 'SI', '.si', 'Slovenia'),
	('SL', 'SL', '.sl', 'Sierra Leone'),
	('SM', 'SM', '.sm', 'San Marino'),
	('SN', 'SG', '.sg', 'Singapore'),
	('SO', 'SO', '.so', 'Somalia'),
	('SP', 'ES', '.es', 'Spain'),
	('ST', 'LC', '.lc', 'Saint Lucia'),
	('SU', 'SD', '.sd', 'Sudan'),
	('SV', 'SJ', '.sj', 'Svalbard'),
	('SW', 'SE', '.se', 'Sweden'),
	('SX', 'GS', '.gs', 'South Georgia and the Islands'),
	('SY', 'SY', '.sy', 'Syrian Arab Republic'),
	('SZ', 'CH', '.ch', 'Switzerland'),
	('TD', 'TT', '.tt', 'Trinidad and Tobago'),
	('TE', '-', '-', 'Tromelin Island'),
	('TH', 'TH', '.th', 'Thailand'),
	('TI', 'TJ', '.tj', 'Tajikistan'),
	('TK', 'TC', '.tc', 'Turks and Caicos Islands'),
	('TL', 'TK', '.tk', 'Tokelau'),
	('TN', 'TO', '.to', 'Tonga'),
	('TO', 'TG', '.tg', 'Togo'),
	('TP', 'ST', '.st', 'Sao Tome and Principe'),
	('TS', 'TN', '.tn', 'Tunisia'),
	('TT', 'TL', '.tl', 'East Timor'),
	('TU', 'TR', '.tr', 'Turkey'),
	('TV', 'TV', '.tv', 'Tuvalu'),
	('TW', 'TW', '.tw', 'Taiwan'),
	('TX', 'TM', '.tm', 'Turkmenistan'),
	('TZ', 'TZ', '.tz', 'Tanzania, United Republic of'),
	('UG', 'UG', '.ug', 'Uganda'),
	('UK', 'GB', '.uk', 'United Kingdom'),
	('UP', 'UA', '.ua', 'Ukraine'),
	('US', 'US', '.us', 'United States'),
	('UV', 'BF', '.bf', 'Burkina Faso'),
	('UY', 'UY', '.uy', 'Uruguay'),
	('UZ', 'UZ', '.uz', 'Uzbekistan'),
	('VC', 'VC', '.vc', 'Saint Vincent and the Grenadines'),
	('VE', 'VE', '.ve', 'Venezuela'),
	('VI', 'VG', '.vg', 'British Virgin Islands'),
	('VM', 'VN', '.vn', 'Vietnam'),
	('VQ', 'VI', '.vi', 'Virgin Islands (US)'),
	('VT', 'VA', '.va', 'Holy See (Vatican City)'),
	('WA', 'NA', '.na', 'Namibia'),
	('WE', '-', '-', 'West Bank'),
	('WF', 'WF', '.wf', 'Wallis and Futuna'),
	('WI', 'EH', '.eh', 'Western Sahara'),
	('WQ', 'UM', '-', 'Wake Island'),
	('WS', 'WS', '.ws', 'Samoa'),
	('WZ', 'SZ', '.sz', 'Swaziland'),
	('YI', 'CS', '.yu', 'Serbia and Montenegro'),
	('YM', 'YE', '.ye', 'Yemen'),
	('ZA', 'ZM', '.zm', 'Zambia'),
	('ZI', 'ZW', '.zw', 'Zimbabwe');