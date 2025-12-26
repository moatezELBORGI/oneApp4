package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.config.AppConfig;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class DataInitializationService implements CommandLineRunner {

    private final CountryRepository countryRepository;
    private final ResidentRepository residentRepository;
    private final BuildingRepository buildingRepository;
    private final ApartmentRepository apartmentRepository;
    private final ResidentBuildingRepository residentBuildingRepository;
    private final PasswordEncoder passwordEncoder;
    private final AppConfig appConfig;
    private final FaqTopicRepository faqTopicRepository;
    private final LeaseContractRepository leaseContractRepository;
    private final ApartmentRoomLegacyRepository apartmentRoomLegacyRepository;
    private final LeaseContractArticleRepository leaseContractArticleRepository;
    private final RoomTypeRepository roomTypeRepository;
    private final RoomTypeFieldDefinitionRepository roomTypeFieldDefinitionRepository;
    @Override
    @Transactional
    public void run(String... args) {
        log.info("Initializing application data...");

        initializeCountries();
        initializeSuperAdmin();
        initializeTestData();
        initFaqData();
        initializeRoomTypes();
        initializeBrusselsLeaseArticles();

        log.info("Application data initialization completed");
    }

    private void initializeCountries() {
        if (countryRepository.count() == 0) {
            log.info("Initializing countries data...");

            List<Country> countries = Arrays.asList(
                    new Country(null, "France", "FR", "FRA", null),
                    new Country(null, "Belgique", "BE", "BEL", null),
                    new Country(null, "Suisse", "CH", "CHE", null),
                    new Country(null, "Canada", "CA", "CAN", null),
                    new Country(null, "Maroc", "MA", "MAR", null),
                    new Country(null, "Tunisie", "TN", "TUN", null),
                    new Country(null, "Algérie", "DZ", "DZA", null)
            );

            countryRepository.saveAll(countries);
            log.info("Countries initialized: {} countries added", countries.size());
        }
    }

    private void initializeSuperAdmin() {
        String adminEmail = appConfig.getAdmin().getDefaultSuperAdminEmail();
        String adminPassword = appConfig.getAdmin().getDefaultSuperAdminPassword();

        if (adminEmail != null && adminPassword != null &&
                residentRepository.findByEmail(adminEmail).isEmpty()) {

            log.info("Creating default super admin...");

            Resident superAdmin = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Super")
                    .lname("Admin")
                    .email(adminEmail)
                    .password(passwordEncoder.encode(adminPassword))
                    .role(UserRole.SUPER_ADMIN)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            residentRepository.save(superAdmin);
            log.info("Super admin created with email: {}", adminEmail);
        }
    }

    private void initializeTestData() {
        log.info("Cleaning existing data...");

        residentBuildingRepository.deleteAll();
        apartmentRepository.deleteAll();
        buildingRepository.deleteAll();
        residentRepository.deleteAll();

        log.info("Creating Delomid IT Immeuble and users...");

        Country belgium = countryRepository.findByCodeIso3("BEL");
        if (belgium == null) {
            belgium = countryRepository.findAll().get(0);
        }

            // ==================== IMMEUBLE: DELOMID IT IMMEUBLE ====================

            Address addressBruxelles = Address.builder()
                    .address("Avenue Louise 250")
                    .codePostal("1050")
                    .ville("Bruxelles")
                    .pays(belgium)
                    .build();

            Building building = Building.builder()
                    .buildingId("BEL-2025-IT-IMMEUBLE")
                    .buildingLabel("Delomid IT Immeuble")
                    .buildingNumber("250")
                    .yearOfConstruction(2024)
                    .numberOfFloors(5)
                    .address(addressBruxelles)
                    .build();

            building = buildingRepository.save(building);
            log.info("Building created: Delomid IT Immeuble");

            // ==================== ADMIN BUILDING 1 ====================
            Resident adminAmir = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Amir")
                    .lname("Admin")
                    .email("amir@delomid-it.com")
                    .password(passwordEncoder.encode("Delomid2019!"))
                    .phoneNumber("+32470111222")
                    .role(UserRole.BUILDING_ADMIN)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();
            adminAmir = residentRepository.save(adminAmir);
            log.info("Admin Building 1 created: amir@delomid-it.com / Delomid2019!");

            ResidentBuilding rbAdminAmir = ResidentBuilding.builder()
                    .resident(adminAmir)
                    .building(building)
                    .apartment(null)
                    .roleInBuilding(UserRole.BUILDING_ADMIN)
                    .build();
            residentBuildingRepository.save(rbAdminAmir);

            // ==================== ADMIN BUILDING 2 ====================
            Resident adminMoatez = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Moatez")
                    .lname("Admin")
                    .email("moatez@delomid-it.com")
                    .password(passwordEncoder.encode("Delomid2019!"))
                    .phoneNumber("+32470222333")
                    .role(UserRole.BUILDING_ADMIN)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();
            adminMoatez = residentRepository.save(adminMoatez);
            log.info("Admin Building 2 created: moatez@delomid-it.com / Delomid2019!");

            ResidentBuilding rbAdminMoatez = ResidentBuilding.builder()
                    .resident(adminMoatez)
                    .building(building)
                    .apartment(null)
                    .roleInBuilding(UserRole.BUILDING_ADMIN)
                    .build();
            residentBuildingRepository.save(rbAdminMoatez);

            // ==================== UTILISATEUR 1 (SANS APPARTEMENT) ====================
            Resident user1 = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Moatez")
                    .lname("El Borgi")
                    .email("moatezelborgi@gmail.com")
                    .password(passwordEncoder.encode("Delomid2019!"))
                    .phoneNumber("+32470333444")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();
            user1 = residentRepository.save(user1);
            log.info("User 1 created: moatezelborgi@gmail.com / Delomid2019!");

            ResidentBuilding rbUser1 = ResidentBuilding.builder()
                    .resident(user1)
                    .building(building)
                    .apartment(null)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();
            residentBuildingRepository.save(rbUser1);

            // ==================== UTILISATEUR 2 (SANS APPARTEMENT) ====================
            Resident user2 = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Moatez")
                    .lname("Borgi")
                    .email("moatezborgi@soft-verse.com")
                    .password(passwordEncoder.encode("Delomid2019!"))
                    .phoneNumber("+32470444555")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();
            user2 = residentRepository.save(user2);
            log.info("User 2 created: moatezborgi@soft-verse.com / Delomid2019!");

            ResidentBuilding rbUser2 = ResidentBuilding.builder()
                    .resident(user2)
                    .building(building)
                    .apartment(null)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();
            residentBuildingRepository.save(rbUser2);

            log.info("==================== INITIALIZATION COMPLETE ====================");
            log.info("Immeuble: Delomid IT Immeuble (Bruxelles, Belgique)");
            log.info("Admin Building 1: amir@delomid-it.com / Delomid2019!");
            log.info("Admin Building 2: moatez@delomid-it.com / Delomid2019!");
            log.info("User 1 (sans appartement): moatezelborgi@gmail.com / Delomid2019!");
            log.info("User 2 (sans appartement): moatezborgi@soft-verse.com / Delomid2019!");
    }
    private void initFaqData()
    {
        String buildingId = "BEL-2025-IT-IMMEUBLE";

        buildingRepository.findById(buildingId).ifPresent(building -> {

            // si ce building a déjà des FAQ, on ne refait rien
            if (!faqTopicRepository.findFaqTopicByBuilding(building).isEmpty()) {
                return;
            }
            // =======================
            //  Building Rules
            // =======================
            FaqTopic buildingRules = new FaqTopic();
            buildingRules.setName("Building Rules");
            buildingRules.setIcon("apartment_rounded");
            buildingRules.setBuilding(building);
            buildingRules.setQuestions(new ArrayList<>());

            FaqQuestion brQ1 = new FaqQuestion();
            brQ1.setQuestion("Puis-je avoir des animaux de compagnie ?");
            brQ1.setAnswer("Oui, sous conditions.");
            brQ1.setTopic(buildingRules);
            buildingRules.getQuestions().add(brQ1);

            FaqQuestion brQ2 = new FaqQuestion();
            brQ2.setQuestion("Y a-t-il des horaires de silence ?");
            brQ2.setAnswer("Oui, généralement entre 22h et 7h.");
            brQ2.setTopic(buildingRules);
            buildingRules.getQuestions().add(brQ2);

            faqTopicRepository.save(buildingRules);

            // =======================
            //  Rent & Payment
            // =======================
            FaqTopic rentPayment = new FaqTopic();
            rentPayment.setName("Rent & Payment");
            rentPayment.setIcon("payments_rounded");
            rentPayment.setBuilding(building);
            rentPayment.setQuestions(new ArrayList<>());

            FaqQuestion rpQ1 = new FaqQuestion();
            rpQ1.setQuestion("Moyens de paiement ?");
            rpQ1.setAnswer("Virement, carte, prélèvement.");
            rpQ1.setTopic(rentPayment);
            rentPayment.getQuestions().add(rpQ1);

            faqTopicRepository.save(rentPayment);

            // =======================
            //  Maintenance
            // =======================
            FaqTopic maintenance = new FaqTopic();
            maintenance.setName("Maintenance");
            maintenance.setIcon("build_rounded");
            maintenance.setBuilding(building);
            maintenance.setQuestions(new ArrayList<>());

            FaqQuestion mQ1 = new FaqQuestion();
            mQ1.setQuestion("Déclarer un problème ?");
            mQ1.setAnswer("Depuis l’app, section Maintenance.");
            mQ1.setTopic(maintenance);
            maintenance.getQuestions().add(mQ1);

            faqTopicRepository.save(maintenance);

            // =======================
            //  Documents
            // =======================
            FaqTopic documents = new FaqTopic();
            documents.setName("Documents");
            documents.setIcon("description_rounded");
            documents.setBuilding(building);
            documents.setQuestions(new ArrayList<>());

            FaqQuestion dQ1 = new FaqQuestion();
            dQ1.setQuestion("Où trouver mon contrat ?");
            dQ1.setAnswer("Dans Mes Documents.");
            dQ1.setTopic(documents);
            documents.getQuestions().add(dQ1);

            faqTopicRepository.save(documents);

            // =======================
            //  Community
            // =======================
            FaqTopic community = new FaqTopic();
            community.setName("Community");
            community.setIcon("groups_rounded");
            community.setBuilding(building);
            community.setQuestions(new ArrayList<>());

            FaqQuestion cQ1 = new FaqQuestion();
            cQ1.setQuestion("Comment sont prises les décisions ?");
            cQ1.setAnswer("Vote / AG.");
            cQ1.setTopic(community);
            community.getQuestions().add(cQ1);

            faqTopicRepository.save(community);

            // =======================
            //  General
            // =======================
            FaqTopic general = new FaqTopic();
            general.setName("General");
            general.setIcon("help_outline_rounded");
            general.setBuilding(building);
            general.setQuestions(new ArrayList<>());

            FaqQuestion gQ1 = new FaqQuestion();
            gQ1.setQuestion("Urgence ?");
            gQ1.setAnswer("Contactez le gardien ou le numéro affiché.");
            gQ1.setTopic(general);
            general.getQuestions().add(gQ1);

            faqTopicRepository.save(general);
        });
    }

    /*   private void initializeOwnerTenantData() {
           if (leaseContractRepository.count() > 0) {
               log.info("Owner/Tenant data already initialized, skipping...");
               return;
           }

           log.info("Initializing Owner/Tenant test data...");

           Building buildingLiege = buildingRepository.findById("BEL-2024-DM-LIEGE").orElse(null);
           if (buildingLiege == null) {
               log.warn("Building not found, skipping owner/tenant initialization");
               return;
           }

           Resident owner1 = Resident.builder()
                   .idUsers(UUID.randomUUID().toString())
                   .fname("Pierre")
                   .lname("Dupont")
                   .email("pierre.dupont@owner.com")
                   .password(passwordEncoder.encode("owner123"))
                   .phoneNumber("+32470111222")
                   .role(UserRole.OWNER)
                   .accountStatus(AccountStatus.ACTIVE)
                   .isEnabled(true)
                   .isAccountNonExpired(true)
                   .isAccountNonLocked(true)
                   .isCredentialsNonExpired(true)
                   .build();
           owner1 = residentRepository.save(owner1);
           log.info("Created owner: Pierre Dupont (pierre.dupont@owner.com / owner123)");

           ResidentBuilding rbOwner1 = ResidentBuilding.builder()
                   .resident(owner1)
                   .building(buildingLiege)
                   .roleInBuilding(UserRole.OWNER)
                   .build();
           residentBuildingRepository.save(rbOwner1);

           Resident tenant1 = Resident.builder()
                   .idUsers(UUID.randomUUID().toString())
                   .fname("Marie")
                   .lname("Martin")
                   .email("marie.martin@tenant.com")
                   .password(passwordEncoder.encode("tenant123"))
                   .phoneNumber("+32470333444")
                   .role(UserRole.RESIDENT)
                   .accountStatus(AccountStatus.ACTIVE)
                   .isEnabled(true)
                   .isAccountNonExpired(true)
                   .isAccountNonLocked(true)
                   .isCredentialsNonExpired(true)
                   .build();
           tenant1 = residentRepository.save(tenant1);
           log.info("Created tenant: Marie Martin (marie.martin@tenant.com / tenant123)");

           Apartment apt101 = apartmentRepository.findById("BEL-2024-DM-LIEGE-A101").orElse(null);
           if (apt101 != null) {
               apt101.setOwner(owner1);
               apt101.setTenant(tenant1);
               apartmentRepository.save(apt101);

               ApartmentRoomLegacy room1 = ApartmentRoom.builder()
                       .apartmentId(apt101.getIdApartment())
                       .roomName("Salon")
                      // .roomType("living_room")
                       //.description("Grand salon lumineux avec baie vitrée")
                       .orderIndex(0)
                       .build();
               apartmentRoomLegacyRepository.save(room1);

               ApartmentRoomLegacy room2 = ApartmentRoom.builder()
                       .apartment(apt101)
                       .roomName("Chambre principale")
                       .roomType("bedroom")
                       .description("Chambre spacieuse avec placard intégré")
                       .orderIndex(1)
                       .build();
               apartmentRoomLegacyRepository.save(room2);

               ApartmentRoomLegacy room3 = ApartmentRoom.builder()
                       .apartment(apt101)
                       .roomName("Cuisine")
                       .roomType("kitchen")
                       .description("Cuisine équipée moderne")
                       .orderIndex(2)
                       .build();
               apartmentRoomLegacyRepository.save(room3);

               ApartmentRoomLegacy room4 = ApartmentRoom.builder()
                       .apartment(apt101)
                       .roomName("Salle de bain")
                       .roomType("bathroom")
                       .description("Salle de bain avec douche et baignoire")
                       .orderIndex(3)
                       .build();
               apartmentRoomLegacyRepository.save(room4);

               log.info("Created 4 rooms for apartment 101");

               LeaseContract contract1 = LeaseContract.builder()
                       .apartment(apt101)
                       .owner(owner1)
                       .tenant(tenant1)
                       .startDate(java.time.LocalDate.now())
                       .endDate(java.time.LocalDate.now().plusYears(9))
                       .initialRentAmount(new BigDecimal("950.00"))
                       .currentRentAmount(new BigDecimal("950.00"))
                       .depositAmount(new BigDecimal("1900.00"))
                       .chargesAmount(new BigDecimal("150.00"))
                       .regionCode("BE-BXL")
                       .status(LeaseContractStatus.DRAFT)
                       .build();
               contract1 = leaseContractRepository.save(contract1);
               log.info("Created lease contract for apartment 101");
   //
               ResidentBuilding rbTenant1 = ResidentBuilding.builder()
                       .resident(tenant1)
                       .building(buildingLiege)
                       .apartment(apt101)
                       .roleInBuilding(UserRole.RESIDENT)
                       .build();
               residentBuildingRepository.save(rbTenant1);
           }

           if (leaseContractArticleRepository.count() == 0) {
               initializeBrusselsLeaseArticles();
               log.info("Created standard lease contract articles for BE-BXL (Brussels)");
           }

           log.info("==================== OWNER/TENANT DATA INITIALIZED ====================");
           log.info("Test Owner: pierre.dupont@owner.com / owner123");
           log.info("Test Tenant: marie.martin@tenant.com / tenant123");
           log.info("Lease Contract created for apartment 101 (DRAFT status)");
           log.info("4 rooms created for apartment 101");
       }
   */
    private void initializeBrusselsLeaseArticles() {
        List<LeaseContractArticle> articles = new ArrayList<>();

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("1")
                .articleTitle("Description du bien loué")
                .articleContent("Par le présent bail, le bailleur donne au preneur, qui l'accepte, le bien immeuble comprenant le type de bien, tous les locaux et parties d'immeuble faisant l'objet du bail, la superficie habitable (plancher), le nombre de pièces, de salles de bain, de chambres, la présence d'une cuisine (équipée ou non), l'année de construction si elle est connue du bailleur, la présence ou non d'un chauffage central, d'un système thermostatique, la présence ou non de doubles vitrages à toutes les fenêtres du logement, la présence ou non d'une cave, d'un grenier, d'un balcon, d'une terrasse ou d'un jardin, les espaces communs et privatifs.")
                .orderIndex(0)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("2")
                .articleTitle("Destination du bien loué")
                .articleContent("Les parties conviennent que le présent bail est destiné à usage de résidence principale. Il est interdit au preneur de modifier cette destination sans l'accord exprès, préalable et écrit du bailleur, qui ne refusera pas cet accord sans juste motif.")
                .orderIndex(1)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("3")
                .articleTitle("Durée du bail")
                .articleContent("Le bail est conclu pour un terme de neuf ans. Il prend fin à l'expiration de cette période de neuf années moyennant un congé notifié par écrit au moins six mois avant l'échéance. A défaut d'un congé notifié dans le délai prévu, le bail sera prorogé chaque fois pour une durée de trois ans, aux mêmes conditions, en ce compris le loyer, sans préjudice de l'indexation et des causes de révision.")
                .orderIndex(2)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("3.1")
                .articleTitle("Résiliation anticipée par le preneur")
                .articleContent("Le preneur peut mettre fin au bail à tout moment, moyennant un congé donné par écrit par lettre recommandée et un préavis de trois mois. Si le preneur met fin au bail au cours du premier triennat, le bailleur a droit à une indemnité. Cette indemnité est égale à trois mois, deux mois ou un mois de loyer selon que le bail prend fin au cours de la première, de la deuxième ou de la troisième année.")
                .orderIndex(3)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("4")
                .articleTitle("Loyer (hors charges)")
                .articleContent("Le bail est consenti et accepté moyennant le paiement d'un loyer initial de base défini dans les conditions financières. Le loyer doit être payé chaque mois, au plus tard le premier jour de chaque période.")
                .orderIndex(4)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("4.1")
                .articleTitle("Indexation du loyer")
                .articleContent("Chacune des parties pourra demander l'indexation du loyer au maximum une fois par an, à la date anniversaire de l'entrée en vigueur du bail et sur demande écrite de la partie intéressée, conformément à la formule suivante : loyer de base x indice nouveau / indice de base. L'indexation n'est possible que si le bailleur a préalablement enregistré le bail et fourni un certificat PEB au preneur.")
                .orderIndex(5)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("4.2")
                .articleTitle("Révision périodique du loyer")
                .articleContent("En cas de renouvellement ou de prorogation du bail, les parties pourront convenir de la révision du loyer entre le neuvième et le sixième mois précédant l'expiration de chaque triennat. A défaut d'accord entre les parties, le juge peut accorder la révision du loyer aux conditions prévues par le Code bruxellois du Logement.")
                .orderIndex(6)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("5")
                .articleTitle("Frais et charges")
                .articleContent("Les frais et charges imposés au preneur correspondent à des dépenses réelles. Seules les dépenses pour des postes qui sont libellés explicitement et énumérés limitativement dans le présent bail sont dues. Si les frais et charges sont des dépenses réelles, ils doivent être détaillés dans un décompte distinct du loyer. Le bailleur l'établit à chaque date anniversaire de l'entrée en vigueur du bail, qu'il communique au preneur dans les douze mois qui suivent.")
                .orderIndex(7)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("6")
                .articleTitle("Intérêts de retard")
                .articleContent("Pour toutes sommes dues par l'une des parties en vertu du présent contrat et à défaut de paiement à l'échéance, la partie en défaut sera redevable d'intérêts de retard sur les sommes restant dues jusqu'à apurement de ses arriérés. Le taux d'intérêts applicable correspond au taux d'intérêt légal.")
                .orderIndex(8)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("7")
                .articleTitle("Impôts et taxes")
                .articleContent("Le précompte immobilier ne peut être mis à charge du preneur. Les impôts et taxes relatifs à la jouissance du bien mis ou à mettre sur le bien loué par l'État, la Région, la Province, la Commune ou toute autre autorité publique, sont à charge du preneur ou du bailleur selon les modalités convenues.")
                .orderIndex(9)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("8")
                .articleTitle("Garantie locative")
                .articleContent("En vue d'assurer le respect de ses obligations, le preneur constitue une garantie locative avant l'entrée en vigueur du bail et avant la remise des clés. La garantie locative ne peut excéder un montant équivalent à deux mois de loyer. En cours de bail, il est interdit aux parties d'affecter la garantie au paiement des loyers ou des charges.")
                .orderIndex(10)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("9")
                .articleTitle("État des lieux")
                .articleContent("Les parties s'engagent, avant l'entrée en jouissance du preneur, à dresser contradictoirement un état des lieux détaillé, à l'amiable ou par un expert. Cet état des lieux est dressé, soit au cours de la période où les locaux sont inoccupés, soit au cours du premier mois d'occupation. Il est annexé au présent bail et doit être enregistré. A défaut d'état des lieux d'entrée, le preneur sera présumé, à l'issue du bail, avoir reçu le bien loué dans le même état que celui où il se trouve à la fin du bail.")
                .orderIndex(11)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("10")
                .articleTitle("Entretien et réparations")
                .articleContent("Le preneur est tenu d'effectuer les travaux de menu entretien ainsi que les réparations locatives qui ne sont pas occasionnées par vétusté ou force majeure. Le bailleur devra pour sa part effectuer, pendant la durée du bail, toutes les réparations qui peuvent devenir nécessaires, autres que les travaux de menu entretien et les réparations locatives ainsi que ceux qui résultent de la faute du preneur.")
                .orderIndex(12)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("11")
                .articleTitle("Travaux et modifications")
                .articleContent("Tous travaux, embellissements, améliorations, transformations du bien loué ne pourront être effectués qu'avec l'accord écrit, préalable et exprès du bailleur qui ne refusera pas son accord sans juste motif. En tout état de cause, ils seront effectués par le preneur à ses frais, risques et périls.")
                .orderIndex(13)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("12")
                .articleTitle("Cession du bail")
                .articleContent("La cession du bail est interdite sauf accord exprès, écrit et préalable du bailleur. Dans ce cas, le cédant est déchargé de toute obligation future, sauf convention contraire. Le bailleur communique son accord ou son refus sur la cession dans les trente jours de la réception du projet. Passé ce délai, la cession est réputée acceptée.")
                .orderIndex(14)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("13")
                .articleTitle("Sous-location")
                .articleContent("Le preneur ne peut sous-louer la totalité du bien. Le preneur peut sous-louer une partie du bien loué avec l'accord du bailleur et à condition que le reste du bien loué demeure affecté à sa résidence principale.")
                .orderIndex(15)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("14")
                .articleTitle("Droit d'information en cas de vente")
                .articleContent("En cas de mise en vente du logement, le preneur dispose d'un droit de préférence, à la condition qu'il soit domicilié dans ledit logement. Ce droit de préférence s'exerce selon les conditions prévues par le Code bruxellois du Logement.")
                .orderIndex(16)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("15")
                .articleTitle("Affichages et visites")
                .articleContent("Avant l'époque où finira le présent bail, ainsi qu'en cas de mise en vente du bien, le preneur devra tolérer, jusqu'au jour de sa sortie, que des placards soient apposés aux endroits les plus apparents, et que les amateurs puissent visiter librement et complètement les lieux selon les créneaux convenus entre les parties.")
                .orderIndex(17)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("16")
                .articleTitle("Assurance")
                .articleContent("Le preneur répond de l'incendie et du dégât des eaux, à moins qu'il ne prouve que celui-ci s'est déclaré sans sa faute. Sa responsabilité est couverte par une assurance conclue auprès d'un assureur autorisé. Le preneur contracte une assurance contre l'incendie et le dégât des eaux préalablement à l'entrée dans les lieux et doit apporter annuellement la preuve du paiement des primes.")
                .orderIndex(18)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("17")
                .articleTitle("Résolution")
                .articleContent("En cas de résolution judiciaire aux torts du preneur, celui-ci devra supporter tous les frais et payer une indemnité forfaitaire équivalente au loyer d'un trimestre. En cas de résolution judiciaire aux torts du bailleur, celui-ci devra supporter tous les frais et payer au preneur une indemnité forfaitaire équivalente au loyer d'un trimestre.")
                .orderIndex(19)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("18")
                .articleTitle("Enregistrement du bail")
                .articleContent("Les formalités de l'enregistrement et les frais éventuels qui y sont liés sont à charge du bailleur. Le bailleur s'engage à enregistrer le bail dans les deux mois de sa signature, de même que les annexes signées et l'état des lieux d'entrée. Il remet la preuve au preneur.")
                .orderIndex(20)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("19")
                .articleTitle("Droit applicable et litiges")
                .articleContent("Le présent contrat est régi par le droit belge et spécialement le Code bruxellois du Logement. Les juridictions de Bruxelles sont seules compétentes en cas de litige. Sans préjudice de la saisine d'une juridiction, les parties peuvent régler leur différend à l'amiable en recourant aux services d'un médiateur agréé.")
                .orderIndex(21)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("20")
                .articleTitle("Notification")
                .articleContent("Toutes les notifications faites par lettre recommandée sont censées faites à la date de dépôt à la poste, la date du récépissé faisant foi de l'envoi dans le délai imparti.")
                .orderIndex(22)
                .isMandatory(true)
                .build());

        articles.add(LeaseContractArticle.builder()
                .regionCode("BE-BXL")
                .articleNumber("21")
                .articleTitle("Élection de domicile")
                .articleContent("Le preneur déclare élire domicile dans le bien loué tant pour la durée de la location que pour toutes les suites du bail, sauf s'il a, après son départ, notifié au bailleur une nouvelle élection de domicile, obligatoirement en Belgique.")
                .orderIndex(23)
                .isMandatory(true)
                .build());

        leaseContractArticleRepository.saveAll(articles);
        log.info("Initialized {} standard articles for Brussels lease contracts (BE-BXL)", articles.size());
    }

    private void initializeRoomTypes() {
        if (roomTypeRepository.count() > 0) {
            log.info("Room types already initialized, skipping...");
            return;
        }

        log.info("Initializing room types...");

        RoomType cuisine = new RoomType();
        cuisine.setName("Cuisine");
        cuisine.setBuildingId(null);
        cuisine = roomTypeRepository.save(cuisine);

        RoomTypeFieldDefinition cuisineEquipements = new RoomTypeFieldDefinition();
        cuisineEquipements.setRoomType(cuisine);
        cuisineEquipements.setFieldName("Équipements");
        cuisineEquipements.setFieldType(FieldType.EQUIPMENT_LIST);
        cuisineEquipements.setIsRequired(false);
        cuisineEquipements.setDisplayOrder(1);
        roomTypeFieldDefinitionRepository.save(cuisineEquipements);

        log.info("Room type 'Cuisine' created with field 'Équipements'");

        RoomType chambre = new RoomType();
        chambre.setName("Chambre à coucher");
        chambre.setBuildingId(null);
        chambre = roomTypeRepository.save(chambre);

        RoomTypeFieldDefinition chambreSurface = new RoomTypeFieldDefinition();
        chambreSurface.setRoomType(chambre);
        chambreSurface.setFieldName("Surface");
        chambreSurface.setFieldType(FieldType.NUMBER);
        chambreSurface.setIsRequired(false);
        chambreSurface.setDisplayOrder(1);
        roomTypeFieldDefinitionRepository.save(chambreSurface);

        RoomTypeFieldDefinition chambreImages = new RoomTypeFieldDefinition();
        chambreImages.setRoomType(chambre);
        chambreImages.setFieldName("Images");
        chambreImages.setFieldType(FieldType.IMAGE_LIST);
        chambreImages.setIsRequired(false);
        chambreImages.setDisplayOrder(2);
        roomTypeFieldDefinitionRepository.save(chambreImages);

        log.info("Room type 'Chambre à coucher' created with fields 'Surface' and 'Images'");

        RoomType salleEau = new RoomType();
        salleEau.setName("Salle d'eau");
        salleEau.setBuildingId(null);
        salleEau = roomTypeRepository.save(salleEau);

        RoomTypeFieldDefinition salleEauEquipements = new RoomTypeFieldDefinition();
        salleEauEquipements.setRoomType(salleEau);
        salleEauEquipements.setFieldName("Équipements");
        salleEauEquipements.setFieldType(FieldType.EQUIPMENT_LIST);
        salleEauEquipements.setIsRequired(false);
        salleEauEquipements.setDisplayOrder(1);
        roomTypeFieldDefinitionRepository.save(salleEauEquipements);

        RoomTypeFieldDefinition salleEauImages = new RoomTypeFieldDefinition();
        salleEauImages.setRoomType(salleEau);
        salleEauImages.setFieldName("Images");
        salleEauImages.setFieldType(FieldType.IMAGE_LIST);
        salleEauImages.setIsRequired(false);
        salleEauImages.setDisplayOrder(2);
        roomTypeFieldDefinitionRepository.save(salleEauImages);

        log.info("Room type 'Salle d'eau' created with fields 'Équipements' and 'Images'");

        log.info("==================== ROOM TYPES INITIALIZATION COMPLETE ====================");
        log.info("3 room types initialized:");
        log.info("  - Cuisine (with Équipements)");
        log.info("  - Chambre à coucher (with Surface, Images)");
        log.info("  - Salle d'eau (with Équipements, Images)");
    }

}