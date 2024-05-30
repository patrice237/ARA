-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1:3306
-- Généré le : ven. 15 déc. 2023 à 22:24
-- Version du serveur : 8.0.31
-- Version de PHP : 8.0.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `ara`
--

DELIMITER $$
--
-- Procédures
--
DROP PROCEDURE IF EXISTS `Absence_Reglement_Adherent`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Absence_Reglement_Adherent` ()   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE nss_adherent VARCHAR(32);
    DECLARE dateEcheance_value DATE;
    DECLARE cur CURSOR FOR SELECT nss, dateEcheance FROM adherent;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO nss_adherent, dateEcheance_value;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        IF DATE_ADD(dateEcheance_value, INTERVAL 2 WEEK) < CURDATE() THEN
            DELETE FROM adherent WHERE nss = nss_adherent;
        END IF;
    END LOOP;

    CLOSE cur;
END$$

DROP PROCEDURE IF EXISTS `detecter_retardataire`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `detecter_retardataire` ()   BEGIN
INSERT INTO retard_adherent_cotisation (SELECT * FROM adherent WHERE adherent.dateEcheance <= CURRENT_DATE + INTERVAL 1 WEEK);
END$$

DROP PROCEDURE IF EXISTS `Enregistrer_Cotisation`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Enregistrer_Cotisation` (IN `nss_adherent` VARCHAR(32))   BEGIN

    DECLARE categorie_adherent INT;
    DECLARE date_echeance_adherent DATE;
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE montant_adherent INT;

    -- Déclaration du curseur
    DECLARE cur_adherents CURSOR FOR
        SELECT nss, cathegorie, dateEcheance
        FROM adherent
        WHERE nss = nss_adherent;

    -- Gestion des exceptions
 
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur_adherents;

    read_loop: LOOP
    
        FETCH cur_adherents INTO nss_adherent, categorie_adherent, date_echeance_adherent;

        -- Sortir de la boucle si aucune ligne n'est trouvée
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Calcul du montant
        SET montant_adherent = 50-categorie_adherent * 50;

        -- Insertion dans la table revenu_adherent
        INSERT INTO revenu_adherent (nss, montant, date)
        VALUES (nss_adherent, montant_adherent, CURRENT_DATE);
        
        UPDATE adherent
        SET dateEcheance = dateEcheance + INTERVAL 1 YEAR
        WHERE nss = nss_adherent;
    END LOOP;

    CLOSE cur_adherents;
END$$

DROP PROCEDURE IF EXISTS `Payement_Randonne`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Payement_Randonne` (IN `nssPersonne` VARCHAR(32), IN `p_numR` INT, IN `p_montant` INT)   BEGIN
    DECLARE estAdherent BOOLEAN;

    -- Vérifier si la personne est un adhérent
    SELECT COUNT(*) INTO estAdherent
    FROM adherent
    WHERE nss = nssPersonne;

    IF estAdherent THEN
        -- Afficher un message indiquant que l'adhérent ne doit pas payer
        SELECT 'Vous êtes adhérent, vous ne devez pas payer' AS Message;
    ELSE
        -- Enregistrer le paiement dans la table Revenu_Randonnee
        INSERT INTO revenu_randonné(nss, numR, montant, date)
        VALUES (nssPersonne, p_numR, p_montant, CURRENT_DATE());
        SELECT 'Paiement enregistré avec succès' AS Message;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `adherent`
--

DROP TABLE IF EXISTS `adherent`;
CREATE TABLE IF NOT EXISTS `adherent` (
  `nss` varchar(32) NOT NULL,
  `etatCivil` enum('Celibataire','Marié') NOT NULL,
  `cathegorie` float NOT NULL,
  `certificatMedical` varchar(32) NOT NULL,
  `dateCertificat` date NOT NULL,
  `dateEcheance` date NOT NULL,
  PRIMARY KEY (`nss`),
  KEY `nss` (`nss`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `adherent`
--

INSERT INTO `adherent` (`nss`, `etatCivil`, `cathegorie`, `certificatMedical`, `dateCertificat`, `dateEcheance`) VALUES
('10', 'Celibataire', 0.75, '0389', '2025-12-30', '2025-07-25'),
('11', 'Celibataire', 0.5, '9103', '2023-12-30', '2023-11-29'),
('12', 'Marié', 0.5, '0293', '2024-10-20', '2024-10-12'),
('16', 'Celibataire', 0, '0922', '2023-12-28', '2025-08-01'),
('20', 'Marié', 0.5, '3849', '2024-04-17', '2025-07-25');

--
-- Déclencheurs `adherent`
--
DROP TRIGGER IF EXISTS `Inserer_Revenu_Adherent`;
DELIMITER $$
CREATE TRIGGER `Inserer_Revenu_Adherent` AFTER INSERT ON `adherent` FOR EACH ROW INSERT INTO revenu_adherent (nss,montant, date)
    VALUES (NEW.nss, 50*(1-NEW.cathegorie), CURRENT_DATE)
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `association`
--

DROP TABLE IF EXISTS `association`;
CREATE TABLE IF NOT EXISTS `association` (
  `numAgrement` int NOT NULL AUTO_INCREMENT,
  `nom` varchar(32) NOT NULL,
  `dateCreation` date NOT NULL,
  `adresse` varchar(32) NOT NULL,
  `telephone` varchar(15) NOT NULL,
  `email` varchar(50) NOT NULL,
  PRIMARY KEY (`numAgrement`)
) ENGINE=InnoDB AUTO_INCREMENT=123456790 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `association`
--

INSERT INTO `association` (`numAgrement`, `nom`, `dateCreation`, `adresse`, `telephone`, `email`) VALUES
(123456789, 'Association des Randonneurs Aubo', '2020-08-18', '24 Place Leonard de Vinci, Troye', '0787175633', 'patrice.mbangue@utt.fr');

-- --------------------------------------------------------

--
-- Structure de la table `asuivi`
--

DROP TABLE IF EXISTS `asuivi`;
CREATE TABLE IF NOT EXISTS `asuivi` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nss` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `numFormation` int NOT NULL,
  `dateValidite` date NOT NULL,
  PRIMARY KEY (`id`),
  KEY `nssAdherent` (`nss`,`numFormation`),
  KEY `numFormation` (`numFormation`),
  KEY `nss` (`nss`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `asuivi`
--

INSERT INTO `asuivi` (`id`, `nss`, `numFormation`, `dateValidite`) VALUES
(3, '12', 1, '2026-02-15'),
(4, '16', 3, '2026-02-15'),
(5, '12', 4, '2025-12-19'),
(6, '16', 4, '2025-12-31');

-- --------------------------------------------------------

--
-- Structure de la table `bureau`
--

DROP TABLE IF EXISTS `bureau`;
CREATE TABLE IF NOT EXISTS `bureau` (
  `idBureau` int NOT NULL AUTO_INCREMENT,
  `nssResponsable` varchar(32) NOT NULL,
  PRIMARY KEY (`idBureau`),
  KEY `nssResponsable` (`nssResponsable`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `bureau`
--

INSERT INTO `bureau` (`idBureau`, `nssResponsable`) VALUES
(1, '10'),
(2, '16');

-- --------------------------------------------------------

--
-- Structure de la table `bureau_reunion`
--

DROP TABLE IF EXISTS `bureau_reunion`;
CREATE TABLE IF NOT EXISTS `bureau_reunion` (
  `id` int NOT NULL AUTO_INCREMENT,
  `idBureau` int NOT NULL,
  `numReunion` int NOT NULL,
  `date` date NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idBureau` (`idBureau`),
  KEY `numReunion` (`numReunion`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `bureau_reunion`
--

INSERT INTO `bureau_reunion` (`id`, `idBureau`, `numReunion`, `date`) VALUES
(1, 1, 1, '2023-10-10'),
(2, 1, 2, '2023-08-08'),
(3, 2, 3, '2023-12-26'),
(4, 2, 4, '2023-08-14');

-- --------------------------------------------------------

--
-- Structure de la table `estmembre`
--

DROP TABLE IF EXISTS `estmembre`;
CREATE TABLE IF NOT EXISTS `estmembre` (
  `idBureau` int NOT NULL,
  `nssAdherent` varchar(32) NOT NULL,
  `fonction` varchar(32) NOT NULL,
  PRIMARY KEY (`idBureau`,`nssAdherent`),
  KEY `idBureau` (`idBureau`),
  KEY `nssAdherent` (`nssAdherent`),
  KEY `nssAdherent_2` (`nssAdherent`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `estmembre`
--

INSERT INTO `estmembre` (`idBureau`, `nssAdherent`, `fonction`) VALUES
(1, '10', 'Président'),
(2, '16', 'Président');

-- --------------------------------------------------------

--
-- Structure de la table `formation`
--

DROP TABLE IF EXISTS `formation`;
CREATE TABLE IF NOT EXISTS `formation` (
  `numFormation` int NOT NULL AUTO_INCREMENT,
  `titre` varchar(255) NOT NULL,
  `dateDebut` date NOT NULL,
  `dateFin` date NOT NULL,
  PRIMARY KEY (`numFormation`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `formation`
--

INSERT INTO `formation` (`numFormation`, `titre`, `dateDebut`, `dateFin`) VALUES
(1, 'Secouriste', '2023-12-01', '2023-12-31'),
(2, 'Educateur', '2024-10-29', '2025-10-29'),
(3, 'Guide', '2024-01-01', '2024-04-01'),
(4, 'Encadrant', '2023-12-15', '2023-12-22');

-- --------------------------------------------------------

--
-- Structure de la table `participe`
--

DROP TABLE IF EXISTS `participe`;
CREATE TABLE IF NOT EXISTS `participe` (
  `numParticipation` int NOT NULL AUTO_INCREMENT,
  `nss` varchar(32) NOT NULL,
  `numR` int NOT NULL,
  `statut` varchar(32) NOT NULL,
  `role` varchar(32) NOT NULL,
  PRIMARY KEY (`numParticipation`),
  KEY `numR` (`numR`),
  KEY `nss` (`nss`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `participe`
--

INSERT INTO `participe` (`numParticipation`, `nss`, `numR`, `statut`, `role`) VALUES
(1, '10', 6, 'Adhérant', 'Organisateur'),
(2, '10', 2, 'Adhérant', 'Organisateur'),
(3, '16', 5, 'Adherant', 'Organisateur'),
(4, '16', 4, 'Adhérant', 'Organisateur'),
(5, '11', 6, 'Adherant', 'Guide'),
(6, '12', 4, 'Adhérant', 'Baliseur'),
(7, '13', 4, 'Participant', 'Participant'),
(9, '13', 1, 'Participant', 'Participant'),
(10, '17', 3, 'Participant', 'Participant');

-- --------------------------------------------------------

--
-- Structure de la table `personne`
--

DROP TABLE IF EXISTS `personne`;
CREATE TABLE IF NOT EXISTS `personne` (
  `nss` varchar(32) NOT NULL,
  `nom` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `prenom` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `age` int NOT NULL,
  `adresse` varchar(255) NOT NULL,
  `telephone` decimal(10,0) NOT NULL,
  `email` varchar(255) NOT NULL,
  PRIMARY KEY (`nss`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `personne`
--

INSERT INTO `personne` (`nss`, `nom`, `prenom`, `age`, `adresse`, `telephone`, `email`) VALUES
('10', 'Mbangue', 'Patrice', 20, 'Troyes', '787175633', 'patrice.mbangue237@gmail.com'),
('11', 'Belaala ', 'Rayan', 22, 'Troyes', '1111111111', 'rayan.belaala@utt.fr'),
('12', 'Siaka', 'Audrey', 20, 'Yaounde', '655081175', 'siaka.maga.audrey@gmail.com'),
('13', 'Owona', 'Jordan ', 18, 'Troyes', '9999999999', 'jordan.owona@utt.fr'),
('14', 'Takam', 'Brayan', 19, 'Troyes', '67839745', 'brayan.takam@utt.fr'),
('15', 'Nguemo', 'Dora', 20, 'Troyes', '985475394', 'dora.nguemo@utt.fr'),
('16', 'Mengue', 'Jerry', 20, 'Eyang', '9999999999', 'jerry.devis@institutsaintjean.org'),
('17', 'Waffeu', 'Wilfried', 19, 'Eyang', '4987656789', 'wilfried.waffeu@institutsaintjean.org'),
('18', 'yemga', 'stacy', 22, 'Troyes', '6789047087', 'stacy.yemga@utt.fr'),
('19', 'Bopda', 'Loic', 22, 'Mimboman', '4567890', 'lafuite.mbole@gmail.com'),
('20', 'Boade', 'Greg', 21, 'Mimboman', '9999999999', 'greg.boade@soa.cm');

-- --------------------------------------------------------

--
-- Structure de la table `photo`
--

DROP TABLE IF EXISTS `photo`;
CREATE TABLE IF NOT EXISTS `photo` (
  `numPhoto` int NOT NULL AUTO_INCREMENT,
  `numR` int NOT NULL,
  `image` varchar(32) NOT NULL,
  PRIMARY KEY (`numPhoto`),
  KEY `numR` (`numR`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `photo`
--

INSERT INTO `photo` (`numPhoto`, `numR`, `image`) VALUES
(1, 1, 'MONTAGNE'),
(2, 2, 'FORET'),
(3, 3, 'RIVIERE'),
(4, 4, 'RIFF'),
(5, 5, 'RAVIN'),
(6, 6, 'CERF'),
(7, 10, 'LAC');

-- --------------------------------------------------------

--
-- Structure de la table `randonne`
--

DROP TABLE IF EXISTS `randonne`;
CREATE TABLE IF NOT EXISTS `randonne` (
  `numR` int NOT NULL AUTO_INCREMENT,
  `titre` varchar(32) NOT NULL,
  `lieu` varchar(32) NOT NULL,
  `date` date NOT NULL,
  `lieuDepart` varchar(32) NOT NULL,
  PRIMARY KEY (`numR`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `randonne`
--

INSERT INTO `randonne` (`numR`, `titre`, `lieu`, `date`, `lieuDepart`) VALUES
(1, 'Montagnes Majestueuses', 'Troyes', '2023-12-25', 'Rosiere'),
(2, 'Randonnée Extrême en Terre Sauva', 'Paris', '2024-01-01', 'Chatelet'),
(3, 'Croisière', 'Nancy', '2024-01-08', 'Essey'),
(4, 'Rando Challenge', 'Lyon', '2024-01-15', 'Grenoble'),
(5, 'Power Ranger', 'Marseille', '2024-01-22', 'Chambery'),
(6, 'Escapade Alpine', 'Reims', '2024-01-29', 'Saint-Étienne '),
(10, 'Tigi', 'Bruxelle', '2024-02-01', 'Mons');

-- --------------------------------------------------------

--
-- Structure de la table `randonne_valide`
--

DROP TABLE IF EXISTS `randonne_valide`;
CREATE TABLE IF NOT EXISTS `randonne_valide` (
  `id` int NOT NULL AUTO_INCREMENT,
  `numSgg` int NOT NULL,
  `idBureau` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `numSgg` (`numSgg`,`idBureau`),
  KEY `idBureau` (`idBureau`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `randonne_valide`
--

INSERT INTO `randonne_valide` (`id`, `numSgg`, `idBureau`) VALUES
(2, 2, 2),
(5, 5, 2),
(1, 6, 1),
(4, 6, 2),
(3, 8, 1),
(6, 8, 2);

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `retard_adherent`
-- (Voir ci-dessous la vue réelle)
--
DROP VIEW IF EXISTS `retard_adherent`;
CREATE TABLE IF NOT EXISTS `retard_adherent` (
`nss` varchar(32)
,`nom` varchar(32)
,`prenom` varchar(32)
);

-- --------------------------------------------------------

--
-- Structure de la table `retard_adherent_cotisation`
--

DROP TABLE IF EXISTS `retard_adherent_cotisation`;
CREATE TABLE IF NOT EXISTS `retard_adherent_cotisation` (
  `nss` varchar(32) NOT NULL,
  `etatCivil` enum('Celibataire','Marié') NOT NULL,
  `cathegorie` float NOT NULL,
  `certificatMedical` varchar(32) NOT NULL,
  `dateCertificat` date NOT NULL,
  `dateEcheance` date NOT NULL,
  PRIMARY KEY (`nss`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `retard_adherent_cotisation`
--

INSERT INTO `retard_adherent_cotisation` (`nss`, `etatCivil`, `cathegorie`, `certificatMedical`, `dateCertificat`, `dateEcheance`) VALUES
('10', 'Marié', 0.75, '0389', '2024-12-31', '2023-12-14');

-- --------------------------------------------------------

--
-- Structure de la table `reunion`
--

DROP TABLE IF EXISTS `reunion`;
CREATE TABLE IF NOT EXISTS `reunion` (
  `numReunion` int NOT NULL AUTO_INCREMENT,
  `compteRendu` varchar(32) NOT NULL,
  PRIMARY KEY (`numReunion`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `reunion`
--

INSERT INTO `reunion` (`numReunion`, `compteRendu`) VALUES
(1, '2732'),
(2, '2382'),
(3, '3728'),
(4, '1632');

-- --------------------------------------------------------

--
-- Structure de la table `revenu_adherent`
--

DROP TABLE IF EXISTS `revenu_adherent`;
CREATE TABLE IF NOT EXISTS `revenu_adherent` (
  `idRevenu` int NOT NULL AUTO_INCREMENT,
  `nss` varchar(32) NOT NULL,
  `montant` int NOT NULL,
  `date` date NOT NULL,
  PRIMARY KEY (`idRevenu`),
  KEY `nss` (`nss`)
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `revenu_adherent`
--

INSERT INTO `revenu_adherent` (`idRevenu`, `nss`, `montant`, `date`) VALUES
(41, '11', 12, '2023-12-15'),
(42, '12', 25, '2023-12-15'),
(43, '16', 0, '2023-12-15'),
(44, '20', 25, '2023-12-15'),
(45, '11', 12, '2023-12-15'),
(46, '10', 12, '2023-12-15'),
(47, '11', 25, '2023-12-15');

-- --------------------------------------------------------

--
-- Structure de la table `revenu_randonné`
--

DROP TABLE IF EXISTS `revenu_randonné`;
CREATE TABLE IF NOT EXISTS `revenu_randonné` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nss` varchar(32) NOT NULL,
  `numR` int NOT NULL,
  `montant` int NOT NULL,
  `date` date NOT NULL,
  PRIMARY KEY (`id`),
  KEY `nss` (`nss`),
  KEY `numR` (`numR`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `revenu_randonné`
--

INSERT INTO `revenu_randonné` (`id`, `nss`, `numR`, `montant`, `date`) VALUES
(1, '17', 3, 15, '2023-12-15');

--
-- Déclencheurs `revenu_randonné`
--
DROP TRIGGER IF EXISTS `Enregistrer_Participation_Personne`;
DELIMITER $$
CREATE TRIGGER `Enregistrer_Participation_Personne` AFTER INSERT ON `revenu_randonné` FOR EACH ROW -- Insérer un nouveau tuple dans la table Participe
    INSERT INTO participe (nss, numR, statut, role)
    VALUES (NEW.nss, NEW.numR, 'Participant', 'Participant')
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `suggestion`
--

DROP TABLE IF EXISTS `suggestion`;
CREATE TABLE IF NOT EXISTS `suggestion` (
  `numSgg` int NOT NULL AUTO_INCREMENT,
  `nss` varchar(32) NOT NULL,
  `lieu` varchar(32) NOT NULL,
  `date` date NOT NULL,
  `nombrekm` int NOT NULL,
  `niveaudiff` enum('noir','vert','bleu','rouge') NOT NULL,
  PRIMARY KEY (`numSgg`),
  KEY `nss` (`nss`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `suggestion`
--

INSERT INTO `suggestion` (`numSgg`, `nss`, `lieu`, `date`, `nombrekm`, `niveaudiff`) VALUES
(2, '16', 'Grenoble', '2024-01-17', 8, 'vert'),
(5, '20', 'Grenoble', '2024-03-18', 15, 'bleu'),
(6, '16', 'Grenoble', '2024-02-19', 5, 'bleu'),
(7, '12', 'Ormont-Dessous', '2024-11-20', 8, 'rouge'),
(8, '16', 'Grenoble', '2024-07-09', 9, 'noir');

-- --------------------------------------------------------

--
-- Structure de la vue `retard_adherent`
--
DROP TABLE IF EXISTS `retard_adherent`;

DROP VIEW IF EXISTS `retard_adherent`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `retard_adherent`  AS SELECT `a`.`nss` AS `nss`, `p`.`nom` AS `nom`, `p`.`prenom` AS `prenom` FROM (`adherent` `a` join `personne` `p`) WHERE ((`a`.`nss` = `p`.`nss`) AND (`a`.`dateEcheance` < (curdate() - interval 1 week)))  ;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `adherent`
--
ALTER TABLE `adherent`
  ADD CONSTRAINT `adherent_ibfk_1` FOREIGN KEY (`nss`) REFERENCES `personne` (`nss`);

--
-- Contraintes pour la table `asuivi`
--
ALTER TABLE `asuivi`
  ADD CONSTRAINT `asuivi_ibfk_2` FOREIGN KEY (`numFormation`) REFERENCES `formation` (`numFormation`),
  ADD CONSTRAINT `asuivi_ibfk_3` FOREIGN KEY (`nss`) REFERENCES `adherent` (`nss`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `bureau`
--
ALTER TABLE `bureau`
  ADD CONSTRAINT `bureau_ibfk_1` FOREIGN KEY (`nssResponsable`) REFERENCES `personne` (`nss`);

--
-- Contraintes pour la table `bureau_reunion`
--
ALTER TABLE `bureau_reunion`
  ADD CONSTRAINT `bureau_reunion_ibfk_1` FOREIGN KEY (`numReunion`) REFERENCES `reunion` (`numReunion`),
  ADD CONSTRAINT `bureau_reunion_ibfk_2` FOREIGN KEY (`idBureau`) REFERENCES `bureau` (`idBureau`);

--
-- Contraintes pour la table `estmembre`
--
ALTER TABLE `estmembre`
  ADD CONSTRAINT `estmembre_ibfk_1` FOREIGN KEY (`nssAdherent`) REFERENCES `adherent` (`nss`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `estmembre_ibfk_2` FOREIGN KEY (`idBureau`) REFERENCES `bureau` (`idBureau`);

--
-- Contraintes pour la table `participe`
--
ALTER TABLE `participe`
  ADD CONSTRAINT `participe_ibfk_2` FOREIGN KEY (`numR`) REFERENCES `randonne` (`numR`),
  ADD CONSTRAINT `participe_ibfk_3` FOREIGN KEY (`nss`) REFERENCES `personne` (`nss`);

--
-- Contraintes pour la table `photo`
--
ALTER TABLE `photo`
  ADD CONSTRAINT `photo_ibfk_1` FOREIGN KEY (`numR`) REFERENCES `randonne` (`numR`);

--
-- Contraintes pour la table `randonne_valide`
--
ALTER TABLE `randonne_valide`
  ADD CONSTRAINT `randonne_valide_ibfk_1` FOREIGN KEY (`numSgg`) REFERENCES `suggestion` (`numSgg`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `randonne_valide_ibfk_2` FOREIGN KEY (`idBureau`) REFERENCES `bureau` (`idBureau`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `revenu_adherent`
--
ALTER TABLE `revenu_adherent`
  ADD CONSTRAINT `revenu_adherent_ibfk_1` FOREIGN KEY (`nss`) REFERENCES `personne` (`nss`);

--
-- Contraintes pour la table `revenu_randonné`
--
ALTER TABLE `revenu_randonné`
  ADD CONSTRAINT `revenu_randonné_ibfk_1` FOREIGN KEY (`nss`) REFERENCES `personne` (`nss`);

--
-- Contraintes pour la table `suggestion`
--
ALTER TABLE `suggestion`
  ADD CONSTRAINT `suggestion_ibfk_1` FOREIGN KEY (`nss`) REFERENCES `adherent` (`nss`) ON DELETE CASCADE ON UPDATE CASCADE;

DELIMITER $$
--
-- Évènements
--
DROP EVENT IF EXISTS `fonctionnalité2`$$
CREATE DEFINER=`root`@`localhost` EVENT `fonctionnalité2` ON SCHEDULE EVERY 1 DAY STARTS '2023-12-22 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL Absence_Reglement_Adherent()$$

DROP EVENT IF EXISTS `fonctionnalité4`$$
CREATE DEFINER=`root`@`localhost` EVENT `fonctionnalité4` ON SCHEDULE EVERY 1 MONTH STARTS '2023-12-14 05:37:26' ON COMPLETION NOT PRESERVE ENABLE DO CALL detecter_retardataire()$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
