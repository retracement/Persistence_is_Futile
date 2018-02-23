/************************************************************
*   All scripts contained within are Copyright © 2015 of    *
*   SQLCloud Limited, whether they are derived or actual    *
*   works of SQLCloud Limited or its representatives        *
*************************************************************
*   All rights reserved. No part of this work may be        *
*   reproduced or transmitted in any form or by any means,  *
*   electronic or mechanical, including photocopying,       *
*   recording, or by any information storage or retrieval   *
*   system, without the prior written permission of the     *
*   copyright owner and the publisher.                      *
************************************************************/
-- Run the whole script in one go
USE BORG
GO

IF EXISTS(SELECT 1 FROM sys.server_event_sessions 
          WHERE name='log_flush_start')
    DROP EVENT SESSION log_flush_start 
    ON SERVER;
GO

/**********************/
/* Drop Database Borg */
/**********************/
USE master
GO
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'Borg')
BEGIN
	ALTER DATABASE [Borg] 
		SET READ_ONLY WITH ROLLBACK IMMEDIATE;
		DROP DATABASE Borg;
END

--IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'Borg')
--BEGIN
--	ALTER DATABASE [Borg] 
--		SET READ_ONLY WITH ROLLBACK IMMEDIATE;
--		DROP DATABASE Borg;
--END

/************************/
/* Create Database Borg */
/************************/
USE master
GO
--CREATE DATABASE Borg
--GO
CREATE DATABASE [Borg]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Borg', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\Borg.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Borg_log', FILENAME = N'C:\slowdisk\Log\Borg_log.ldf' , SIZE = 1GB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [Borg] SET RECOVERY SIMPLE
ALTER DATABASE [Borg] SET AUTO_CREATE_STATISTICS OFF;
GO


USE Borg
GO
CREATE TABLE Fleet (id INT, name CHAR(7000), cubic_size INT, class VARCHAR(20));
GO
CREATE TABLE Assimilations (id INT IDENTITY, assimilation_date datetime DEFAULT getdate(), NewBorg INT, Details CHAR (50));
GO

/*******************************/
/* Create Procedure Logrecords */
/*******************************/
USE Borg
GO
IF OBJECT_ID('dbo.vw_logrecords ','V') IS NULL
	EXEC ('CREATE VIEW dbo.vw_logrecords AS SELECT ''stub object'' ''stub object''')
GO
ALTER VIEW dbo.vw_logrecords 
AS
SELECT
[Current LSN],[Operation],[Context],[Transaction ID],[AllocUnitName],[Log Record Fixed Length],
[Log Record Length],[Num Transactions],[Number of Locks],[Lock Information],[Description]
	FROM    sys.fn_dblog(NULL, NULL)
GO



/************************/
/* Create Table Species */
/************************/
USE [Borg]
GO
CREATE TABLE Species
	(id INT IDENTITY PRIMARY KEY CLUSTERED NOT NULL,
	[Name] VARCHAR(20) NOT NULL,
	Description VARCHAR(MAX)
	INDEX [idxName] NONCLUSTERED ([Name])
	)
GO

INSERT INTO dbo.Species ([name], [description]) VALUES
('Aaamazzarite','Aaamazzarites, also called Therbians, are a hairless species with pale yellow skin. Aaamazzara orbits Epsilon Serpentis in the Alpha Quadrant. It is 70.3 light years away from Earth. Everything on the planet is bio-chemically produced from their mouths, including clothing and furniture. They are members of the United Federation of Planets.'),
('Acamarian','Acamarians are a generally peaceful race with a history of violent clan wars. Physically, they can be distinguished by a vertical crease in the center of the forehead. A splinter group, known as the Gatherers, composed of members of various Acamarian clans who opposed the peace treaty for about 100 years, was eventually repatriated into Acamarian society.'),
('Bajoran','The Bajorans are a humanoid species with characteristic nose creases. They live on the planet Bajor. They are a deeply spiritual people, who worship The Prophets. They are enemies of the Cardassians, who occupied Bajor and treated the Bajorans as slaves in the early 24th century.'),
('Benzite','Benzites are a humanoid race from the planet Benzar and members of the United Federation of Planets.
Benzites possess smooth, hairless skin; it may range in color from bluish-purple to green-blue. A thick protrusion of the Benzite skull extends down over the face, displaying a prominent nasal lobe and brow. Two fish-like barbels droop down from above the upper lip. Benzites are highly resistant to poisons and other noxious substances. They can digest and derive nutrition from almost any organic compound. All Benzites from the same geostructure are physically similar, so much so that they are indistinguishable to a non-Benzite.'),
('Betazoid','Betazed'),
('Cardassian','The Cardassians are enemies of the United Federation of Planets and are mentioned in Star Trek: Deep Space Nine, Star Trek: The Next Generation, and Star Trek: Voyager. They have noticeable ridges along their foreheads and necks and a crest on their foreheads, earning them the nickname, Spoonheads. Their government is a military dictatorship.'),
('Changeling','A race of fluid shapeshifters, who founded the Dominion by genetically engineering organisms to operate the military and logistics. These organisms call them the Founders. The Founders refer to most humanoid species as "solids".'),
('Denobulans','Denobulans are a Humanoid species who hail from the planet of Denobula of the Denobula Triaxa system. Denobulans only require 144 hours of sleep per year although some Denobulans, such as doctor Phlox of the Enterprise NX-01, can sleep as little as 48 hours per year. It is customary for adult Denobulans to have three spouses each. Denobulans also have ridges running their forehead, cheeks, and spine.'),
('Edosian','Edosians (aka Edoans) are a race of sentient tripedal beings. Edosians have an orange complexion, two yellow eyes, three arms and three dog-like legs. Navigator Lieutenant Arex was introduced in Star Trek: The Animated Series, but his planet of origin, Edos, was mentioned only in background material.[1] Passing references to Edosian flora and fauna have been made in episodes of Star Trek: Deep Space Nine and Star Trek: Enterprise. In some tie-in novels and short stories, Arex is mentioned as actually being a Triexian, with the Edosians being a near-identical race.'),
('El-Aurian','El-Aurians (referred to as a Race of Listeners by Dr. Tolian Soran, the El-Aurian antagonist in Star Trek Generations) are a humanoid race first introduced in the second season of Star Trek: The Next Generation with the character of Guinan. The species was named in the Star Trek: Deep Space Nine episode "Rivals".

El-Aurians appear outwardly identical to humans, and have a variety of ethnic types, with both dark- and light-skinned members of the race being shown on various Star Trek movies and television episodes. They can live well over 700 years. They are considered a race of listeners and often appear patient and wise.

The El-Aurian homeworld was located in the Delta Quadrant and was destroyed by the Borg in the mid-23rd century. Few survived, and those who did were scattered throughout the galaxy. Some of the refugees came to the United Federation of Planets and it has been noted that this is likely an analogy for the spread of Africans around the Earth via colonialism and slavery.'),
('Ferengi','The Ferengi are a mysterious race who care only about profit.'),
('Jem''Hadar','The Jem''Hadar are an alien race genetically engineered by the Dominion.'),
('Kzinti','A cat-like race introduced in Star Trek: The Animated Series. Kzinti society is a male dominate race of warriors (they prefer to use the term "Heros") led by the Patriarch. Kzinti Heros have much in common with Klingon warriors, in that they highly value courage, fighting prowess, and consider personal honor of highest priority. The one racial "flaw" that Kzinti have is overconfidence, which manifests itself in a tendency to attack before they are truly ready. This is because they believe that combat, with the removal of all challenge and risk (i.e. certain success), lessens the honor gained in battle. Kzinti Heros place great pride in the scars they receive in battle, they also respect valiant and fierce opponents of other races, ensuring the bodies of these impressive alien warriors are stuffed and placed on honorable memorial display on Kzin, (the Kzinti home world).

Kzinti male are larger than their more docile females and humans They somewhat resemble a bipedal, barrel-chested, tiger-furred "tabby". Their tails are naked (rat like) and their ears have spines (resembling a section of a parasol.).'),
('Ocampa','A race native to the Delta Quadrant with a lifespan of only nine years.'),
('Orion','Orions are a green-skinned, humanoid alien species in the Star Trek universe. An Orion was first portrayed as an illusion in the original Star Trek pilot, but wasn''t seen in the broadcast series until this original pilot was incorporated into a two-part episode (episodes 11 and 12) in the first season. Orions have also been portrayed in Star Trek: The Animated Series, Star Trek: Deep Space Nine, Star Trek: Voyager and Star Trek: Enterprise. Rachel Nichols played Orion Starfleet cadet Gaila in the 2009 Star Trek film.'''),
('Romulan','Romulans are humanoid extraterrestrials that appear in every Star Trek television series, where members of their race often serve as antagonists.
They prominently feature in the film Star Trek Nemesis.'),
('Tellarite','The Tellarites appeared in "Journey to Babel". They have an odd facial appearance, represented by the actors wearing converted pig masks.'),
('Thasians','The Thasians are a psionically powerful, non-corporeal species, native to the planet Thasus. Until the 23rd century, the Federation had never encountered the Thasians and thus believed them to be a myth. They appeared in "Charlie X" on the Original Series.'),
('Tholian','The Tholians are an extremely xenophobic, non-humanoid hermaphroditic species with a propensity for precision. In Star Trek episode "The Tholian Web",Spock make the remark when fired upon by the Tholians: "The renowned Tholian punctuality". They first appear in the original series episode, "The Tholian Web". Tholian biology required high temperatures around 480 Kelvin (207 °C, 404 °F). They could tolerate lower temperatures for a brief period of time; if they were exposed to temperatures around 380 Kelvin or less, their carapace would crack. This was painful or distressing; a Tholian subjected to such a temperature regime could be coerced to cooperate. In temperatures even lower, a Tholian would freeze solid and shatter. (ENT: "Future Tense", "In a Mirror, Darkly")'),
('Tribble','Tribbles are a petlike species who hate Klingons.')
