CREATE TABLE `lmh` (
departureAerodromeIcaoId varchar(6) CHARACTER SET ascii NOT NULL DEFAULT '',               -- 1
arrivalAerodromeIcaoId varchar(6) CHARACTER SET ascii NOT NULL DEFAULT '',		   -- 2
aircraftId varchar(10) CHARACTER SET ascii NOT NULL DEFAULT '',				   -- 3
aircraftOperatorIcaoId varchar(10) CHARACTER SET ascii NOT NULL DEFAULT '',		   -- 4
aircraftTypeIcaoId varchar(10) CHARACTER SET ascii NOT NULL DEFAULT '',			   -- 5
aobt bigint(12) unsigned NOT NULL, 							   -- 6
ifpsId varchar(12) CHARACTER SET ascii NOT NULL DEFAULT '',				   -- 7
iobt bigint(12) unsigned NOT NULL, 							   -- 8
cobt bigint(12) unsigned NOT NULL DEFAULT 0, 						   -- 17
eobt bigint(12) unsigned NOT NULL, 							   -- 18
lobt bigint(12) unsigned NOT NULL, 							   -- 19
tactId int(8) UNSIGNED NOT NULL DEFAULT 0,						   -- 23
samCtot bigint(12) unsigned NOT NULL, 							   -- 24
samSent enum('Y','N') CHARACTER SET ascii NOT NULL DEFAULT 'N',				   -- 25
slotForced varchar(10) CHARACTER SET ascii NOT NULL DEFAULT 'N',        	           -- 28
mostPenalizingRegulationId varchar(10) CHARACTER SET ascii NOT NULL DEFAULT '',		   -- 29
lastReceivedAtfmMessageTitle varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',	  -- 32
lastReceivedMessageTitle varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',		  -- 33
lastSentAtfmMessageTitle varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',		  -- 34
manualExemptionReason varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',		  -- 35
readyForImprovement enum('Y','N') CHARACTER SET ascii NOT NULL DEFAULT 'N',		  -- 37
readyToDepart enum('Y','N') CHARACTER SET ascii NOT NULL DEFAULT 'N',			  -- 38
revisedTaxiTime int(6) UNSIGNED NOT NULL DEFAULT 0,					  -- 39
toBeSentSlotMessageTitle varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',		  -- 42
toBeSentProposalMessageTitle varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',	  -- 43
lastSentSlotMessageTitle varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',		  -- 44
lastSentProposalMessageTitle varchar(128) CHARACTER SET ascii NOT NULL DEFAULT '',	  -- 45
lastSentSlotMessage bigint(12) unsigned NOT NULL, 					  -- 46
lastSentProposalMessage bigint(12) unsigned NOT NULL, 					  -- 47
ifpsRegistrationMark varchar(60) CHARACTER SET ascii NOT NULL DEFAULT '',		  -- 58
flightType varchar(6) CHARACTER SET ascii NOT NULL DEFAULT '',				  -- 59
cdmStatus varchar(4) CHARACTER SET ascii NOT NULL DEFAULT '',				  -- 61
cdmEarlyTtot bigint(12) unsigned NOT NULL, 						  -- 62
cdmAoTtot bigint(12) unsigned NOT NULL, 						  -- 63
cdmAtcTtot bigint(12) unsigned NOT NULL, 						  -- 64
cdmSequencedTtot bigint(12) unsigned NOT NULL, 						  -- 65
cdmTaxiTime int(8) UNSIGNED NOT NULL DEFAULT 0,					          -- 66
cdmOffBlockTimeDiscrepancy enum('Y','N') CHARACTER SET ascii NOT NULL DEFAULT 'N',	  -- 67
cdmDepartureProcedureId varchar(40) CHARACTER SET ascii NOT NULL DEFAULT '',		  -- 68
cdmAircraftTypeId varchar(40) CHARACTER SET ascii NOT NULL DEFAULT '',			  -- 69
cdmRegistrationMark varchar(40) CHARACTER SET ascii NOT NULL DEFAULT '',		  -- 70
cdmNoSlotBefore bigint(12) unsigned NOT NULL, 						  -- 71
cdmDepartureStatus varchar(4) CHARACTER SET ascii NOT NULL DEFAULT '',			  -- 72
ftfmEetFirList varchar(512) CHARACTER SET ascii NOT NULL DEFAULT '',			  -- 74
ftfmEetPtList varchar(512) CHARACTER SET ascii NOT NULL DEFAULT '',			  -- 76
ftfmAiracCycleReleaseNumber int(4) UNSIGNED NOT NULL DEFAULT 0,			          -- 77
-- ftfmEnvBaselineNumber int(6) UNSIGNED NOT NULL DEFAULT 0,				  -- 78
ftfmDepartureRunway varchar(12) CHARACTER SET ascii NOT NULL DEFAULT '',		  -- 79
ftfmArrivalRunway varchar(12) CHARACTER SET ascii NOT NULL DEFAULT '',			  -- 80
ftfmReqFlightlevelSpeedList varchar(512) CHARACTER SET ascii NOT NULL DEFAULT '',	  -- 82
ftfmConsumedFuel  int(6) NOT NULL DEFAULT 0,						  -- 83
ftfmRouteCharges  int(6) NOT NULL DEFAULT 0,						  -- 84
ftfmAllFtPointProfile json  NOT NULL,					                  -- 86
rtfmAiracCycleReleaseNumber int(4) UNSIGNED NOT NULL DEFAULT 0,			          -- 91
-- rtfmEnvBaselineNumber int(6) UNSIGNED NOT NULL DEFAULT 0,				  -- 92
rtfmDepartureRunway varchar(12) CHARACTER SET ascii NOT NULL DEFAULT '',		  -- 93
rtfmArrivalRunway varchar(12) CHARACTER SET ascii NOT NULL DEFAULT '',			  -- 94
rtfmReqFlightlevelSpeedList varchar(512) CHARACTER SET ascii NOT NULL DEFAULT '',	  -- 96
rtfmConsumedFuel  int(6) NOT NULL DEFAULT 0,						  -- 97
rtfmRouteCharges  int(6) NOT NULL DEFAULT 0,						  -- 98
rtfmAllFtPointProfile json  NOT NULL,					                 -- 100
ctfmAiracCycleReleaseNumber int(4) UNSIGNED NOT NULL DEFAULT 0,			         -- 105
-- ctfmEnvBaselineNumber int(6) UNSIGNED NOT NULL DEFAULT 0,				 -- 106
ctfmDepartureRunway varchar(12) CHARACTER SET ascii NOT NULL DEFAULT '',		 -- 107
ctfmArrivalRunway varchar(12) CHARACTER SET ascii NOT NULL DEFAULT '',			 -- 108
ctfmReqFlightlevelSpeedList varchar(512) CHARACTER SET ascii NOT NULL DEFAULT '',	 -- 110
ctfmConsumedFuel  int(6) NOT NULL DEFAULT 0,						 -- 111
ctfmRouteCharges  int(6) NOT NULL DEFAULT 0,						 -- 112
ctfmAllFtPointProfile json  NOT NULL,					                 -- 114
aircraftidIATA varchar(20) CHARACTER SET ascii NOT NULL DEFAULT '',			 -- 165
  PRIMARY KEY (`ifpsId`),
  KEY `tactId` (`tactId`),
  KEY `aircraftId` (`aircraftId`),
  KEY `departureAerodromeIcaoId` (`departureAerodromeIcaoId`),
  KEY `arrivalAerodromeIcaoId` (`arrivalAerodromeIcaoId`),
  KEY `aircraftOperatorIcaoId` (`aircraftOperatorIcaoId`),
  KEY `aobt` (`aobt`),
  KEY `lastReceivedAtfmMessageTitle` (`lastReceivedAtfmMessageTitle`),
  KEY `ftfmDepartureRunway` (`ftfmDepartureRunway`),
  KEY `aircraftidIATA` (`aircraftidIATA`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii;
