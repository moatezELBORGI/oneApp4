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
    private final ApartmentRoomRepository apartmentRoomRepository;
    private final LeaseContractArticleRepository leaseContractArticleRepository;
     @Override
    @Transactional
    public void run(String... args) {
        log.info("Initializing application data...");

        initializeCountries();
        initializeSuperAdmin();
        initializeTestData();
         initFaqData();
        initializeOwnerTenantData();

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
        if (buildingRepository.count() == 0) {
            log.info("Creating test buildings and residents...");

            Country belgium = countryRepository.findByCodeIso3("BEL");
            if (belgium == null) {
                belgium = countryRepository.findAll().get(0);
            }

            // ==================== BUILDING 1: DELOMID DM LIEGE ====================

            Address addressLiege = Address.builder()
                    .address("Rue de la Régence 1")
                    .codePostal("4000")
                    .ville("Liège")
                    .pays(belgium)
                    .build();

            Building buildingLiege = Building.builder()
                    .buildingId("BEL-2024-DM-LIEGE")
                    .buildingLabel("Delomid DM Liège")
                    .buildingNumber("1")
                    .yearOfConstruction(2020)
                    .address(addressLiege)
                    .build();

            buildingLiege = buildingRepository.save(buildingLiege);
            log.info("Building 1 created: Delomid DM Liège");

            // Créer 3 appartements pour Liège
            Apartment aptLiege1 = Apartment.builder()
                    .idApartment("BEL-2024-DM-LIEGE-A101")
                    .apartmentLabel("Appartement 101")
                    .apartmentNumber("101")
                    .apartmentFloor(1)
                    .livingAreaSurface(new BigDecimal("75.0"))
                    .numberOfRooms(3)
                    .numberOfBedrooms(2)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(false)
                    .building(buildingLiege)
                    .build();

            Apartment aptLiege2 = Apartment.builder()
                    .idApartment("BEL-2024-DM-LIEGE-A102")
                    .apartmentLabel("Appartement 102")
                    .apartmentNumber("102")
                    .apartmentFloor(1)
                    .livingAreaSurface(new BigDecimal("65.0"))
                    .numberOfRooms(2)
                    .numberOfBedrooms(1)
                    .haveBalconyOrTerrace(false)
                    .isFurnished(true)
                    .building(buildingLiege)
                    .build();

            Apartment aptLiege3 = Apartment.builder()
                    .idApartment("BEL-2024-DM-LIEGE-A201")
                    .apartmentLabel("Appartement 201")
                    .apartmentNumber("201")
                    .apartmentFloor(2)
                    .livingAreaSurface(new BigDecimal("80.0"))
                    .numberOfRooms(4)
                    .numberOfBedrooms(3)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(false)
                    .building(buildingLiege)
                    .build();

            aptLiege1 = apartmentRepository.save(aptLiege1);
            aptLiege2 = apartmentRepository.save(aptLiege2);
            aptLiege3 = apartmentRepository.save(aptLiege3);
            log.info("3 apartments created for Delomid DM Liège");

            // Créer les résidents pour Liège
            Resident siamak = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Siamak")
                    .lname("Miandarbandi")
                    .email("siamak.miandarbandi@delomid.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+32470123456")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            Resident moatezLiege = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Moatez")
                    .lname("Borgi")
                    .email("moatez@delomid-it.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+32470234567")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            Resident farzanehLiege = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Farzaneh")
                    .lname("Hajjel")
                    .email("farzaneh.hajjel@delomid.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+32470345678")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            siamak = residentRepository.save(siamak);
            moatezLiege = residentRepository.save(moatezLiege);
            farzanehLiege = residentRepository.save(farzanehLiege);
            log.info("3 residents created for Delomid DM Liège");

            // Assigner les résidents aux appartements de Liège
            aptLiege1.setResident(siamak);
            aptLiege2.setResident(moatezLiege);
            aptLiege3.setResident(farzanehLiege);
            apartmentRepository.save(aptLiege1);
            apartmentRepository.save(aptLiege2);
            apartmentRepository.save(aptLiege3);

            // Créer les relations ResidentBuilding pour Liège (Siamak = ADMIN)
            ResidentBuilding rbSiamakLiege = ResidentBuilding.builder()
                    .resident(siamak)
                    .building(buildingLiege)
                    .apartment(aptLiege1)
                    .roleInBuilding(UserRole.BUILDING_ADMIN)
                    .build();

            ResidentBuilding rbMoatezLiege = ResidentBuilding.builder()
                    .resident(moatezLiege)
                    .building(buildingLiege)
                    .apartment(aptLiege2)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            ResidentBuilding rbFarzanehLiege = ResidentBuilding.builder()
                    .resident(farzanehLiege)
                    .building(buildingLiege)
                    .apartment(aptLiege3)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            residentBuildingRepository.save(rbSiamakLiege);
            residentBuildingRepository.save(rbMoatezLiege);
            residentBuildingRepository.save(rbFarzanehLiege);
            log.info("ResidentBuilding relations created for Liège (Siamak = ADMIN)");

            // ==================== BUILDING 2: DELOMID IT BRUXELLES ====================

            Address addressBruxelles = Address.builder()
                    .address("Avenue Louise 100")
                    .codePostal("1050")
                    .ville("Bruxelles")
                    .pays(belgium)
                    .build();

            Building buildingBruxelles = Building.builder()
                    .buildingId("BEL-2024-IT-BRUXELLES")
                    .buildingLabel("Delomid IT Bruxelles")
                    .buildingNumber("100")
                    .yearOfConstruction(2021)
                    .address(addressBruxelles)
                    .build();

            buildingBruxelles = buildingRepository.save(buildingBruxelles);
            log.info("Building 2 created: Delomid IT Bruxelles");

            // Créer 4 appartements pour Bruxelles
            Apartment aptBxl1 = Apartment.builder()
                    .idApartment("BEL-2024-IT-BRUXELLES-A101")
                    .apartmentLabel("Appartement 101")
                    .apartmentNumber("101")
                    .apartmentFloor(1)
                    .livingAreaSurface(new BigDecimal("70.0"))
                    .numberOfRooms(3)
                    .numberOfBedrooms(2)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(false)
                    .building(buildingBruxelles)
                    .build();

            Apartment aptBxl2 = Apartment.builder()
                    .idApartment("BEL-2024-IT-BRUXELLES-A102")
                    .apartmentLabel("Appartement 102")
                    .apartmentNumber("102")
                    .apartmentFloor(1)
                    .livingAreaSurface(new BigDecimal("65.0"))
                    .numberOfRooms(2)
                    .numberOfBedrooms(1)
                    .haveBalconyOrTerrace(false)
                    .isFurnished(true)
                    .building(buildingBruxelles)
                    .build();

            Apartment aptBxl3 = Apartment.builder()
                    .idApartment("BEL-2024-IT-BRUXELLES-A201")
                    .apartmentLabel("Appartement 201")
                    .apartmentNumber("201")
                    .apartmentFloor(2)
                    .livingAreaSurface(new BigDecimal("85.0"))
                    .numberOfRooms(4)
                    .numberOfBedrooms(3)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(false)
                    .building(buildingBruxelles)
                    .build();

            Apartment aptBxl4 = Apartment.builder()
                    .idApartment("BEL-2024-IT-BRUXELLES-A202")
                    .apartmentLabel("Appartement 202")
                    .apartmentNumber("202")
                    .apartmentFloor(2)
                    .livingAreaSurface(new BigDecimal("60.0"))
                    .numberOfRooms(2)
                    .numberOfBedrooms(1)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(true)
                    .building(buildingBruxelles)
                    .build();

            aptBxl1 = apartmentRepository.save(aptBxl1);
            aptBxl2 = apartmentRepository.save(aptBxl2);
            aptBxl3 = apartmentRepository.save(aptBxl3);
            aptBxl4 = apartmentRepository.save(aptBxl4);
            log.info("4 apartments created for Delomid IT Bruxelles");

            // Créer les résidents pour Bruxelles
            Resident amir = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Amir")
                    .lname("Miandarbandi")
                    .email("moatezelborgi@gmail.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+32470456789")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            Resident somayyeh = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Somayyeh")
                    .lname("Gholami")
                    .email("somayyeh.gholami@delomid.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+32470567890")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            amir = residentRepository.save(amir);
            somayyeh = residentRepository.save(somayyeh);
            log.info("2 new residents created for Delomid IT Bruxelles");

            // Assigner les résidents aux appartements de Bruxelles
            // Moatez et Farzaneh sont réutilisés de Liège
            aptBxl1.setResident(amir);
            aptBxl2.setResident(moatezLiege);
            aptBxl3.setResident(farzanehLiege);
            aptBxl4.setResident(somayyeh);
            apartmentRepository.save(aptBxl1);
            apartmentRepository.save(aptBxl2);
            apartmentRepository.save(aptBxl3);
            apartmentRepository.save(aptBxl4);

            // Créer les relations ResidentBuilding pour Bruxelles (Amir = ADMIN)
            ResidentBuilding rbAmirBxl = ResidentBuilding.builder()
                    .resident(amir)
                    .building(buildingBruxelles)
                    .apartment(aptBxl1)
                    .roleInBuilding(UserRole.BUILDING_ADMIN)
                    .build();

            ResidentBuilding rbMoatezBxl = ResidentBuilding.builder()
                    .resident(moatezLiege)
                    .building(buildingBruxelles)
                    .apartment(aptBxl2)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            ResidentBuilding rbFarzanehBxl = ResidentBuilding.builder()
                    .resident(farzanehLiege)
                    .building(buildingBruxelles)
                    .apartment(aptBxl3)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            ResidentBuilding rbSomayyehBxl = ResidentBuilding.builder()
                    .resident(somayyeh)
                    .building(buildingBruxelles)
                    .apartment(aptBxl4)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            ResidentBuilding rbSiamakBxl = ResidentBuilding.builder()
                    .resident(siamak)
                    .building(buildingBruxelles)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            residentBuildingRepository.save(rbAmirBxl);
            residentBuildingRepository.save(rbMoatezBxl);
            residentBuildingRepository.save(rbFarzanehBxl);
            residentBuildingRepository.save(rbSomayyehBxl);
            residentBuildingRepository.save(rbSiamakBxl);
            log.info("ResidentBuilding relations created for Bruxelles (Amir = ADMIN)");

            log.info("==================== INITIALIZATION COMPLETE ====================");
            log.info("Building 1: Delomid DM Liège - 3 apartments, 3 residents (Siamak = ADMIN)");
            log.info("  - Siamak Miandarbandi (ADMIN, apt 101)");
            log.info("  - Moatez Borgi (resident, apt 102)");
            log.info("  - Farzaneh Hajjel (resident, apt 201)");
            log.info("Building 2: Delomid IT Bruxelles - 4 apartments, 5 residents (Amir = ADMIN)");
            log.info("  - Amir Miandarbandi (ADMIN, apt 101)");
            log.info("  - Moatez Borgi (resident, apt 102) - same as Liège");
            log.info("  - Farzaneh Hajjel (resident, apt 201) - same as Liège");
            log.info("  - Somayyeh Gholami (resident, apt 202)");
            log.info("  - Siamak Miandarbandi (resident, no apt) - same as Liège ADMIN");
        }
    }
private void initFaqData()
{
    String buildingId = "BEL-2024-IT-BRUXELLES";

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

    private void initializeOwnerTenantData() {
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

            ApartmentRoom room1 = ApartmentRoom.builder()
                    .apartment(apt101)
                    .roomName("Salon")
                    .roomType("living_room")
                    .description("Grand salon lumineux avec baie vitrée")
                    .orderIndex(0)
                    .build();
            apartmentRoomRepository.save(room1);

            ApartmentRoom room2 = ApartmentRoom.builder()
                    .apartment(apt101)
                    .roomName("Chambre principale")
                    .roomType("bedroom")
                    .description("Chambre spacieuse avec placard intégré")
                    .orderIndex(1)
                    .build();
            apartmentRoomRepository.save(room2);

            ApartmentRoom room3 = ApartmentRoom.builder()
                    .apartment(apt101)
                    .roomName("Cuisine")
                    .roomType("kitchen")
                    .description("Cuisine équipée moderne")
                    .orderIndex(2)
                    .build();
            apartmentRoomRepository.save(room3);

            ApartmentRoom room4 = ApartmentRoom.builder()
                    .apartment(apt101)
                    .roomName("Salle de bain")
                    .roomType("bathroom")
                    .description("Salle de bain avec douche et baignoire")
                    .orderIndex(3)
                    .build();
            apartmentRoomRepository.save(room4);

            log.info("Created 4 rooms for apartment 101");

            LeaseContract contract1 = LeaseContract.builder()
                    .apartment(apt101)
                    .owner(owner1)
                    .tenant(tenant1)
                    .startDate(java.time.LocalDate.now())
                    .endDate(java.time.LocalDate.now().plusYears(1))
                    .initialRentAmount(new BigDecimal("950.00"))
                    .currentRentAmount(new BigDecimal("950.00"))
                    .depositAmount(new BigDecimal("1900.00"))
                    .chargesAmount(new BigDecimal("150.00"))
                    .regionCode("BE-BRU")
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
            LeaseContractArticle article1 = LeaseContractArticle.builder()
                    .regionCode("BE-BRU")
                    .articleNumber("1")
                    .articleTitle("Objet du contrat")
                    .articleContent("Le bailleur donne en location au preneur qui accepte, un bien immobilier situé à l'adresse mentionnée ci-dessus.")
                    .orderIndex(0)
                    .isMandatory(true)
                    .build();
            leaseContractArticleRepository.save(article1);

            LeaseContractArticle article2 = LeaseContractArticle.builder()
                    .regionCode("BE-BRU")
                    .articleNumber("2")
                    .articleTitle("Durée du contrat")
                    .articleContent("Le contrat est conclu pour une durée de 9 ans, renouvelable par tacite reconduction.")
                    .orderIndex(1)
                    .isMandatory(true)
                    .build();
            leaseContractArticleRepository.save(article2);

            LeaseContractArticle article3 = LeaseContractArticle.builder()
                    .regionCode("BE-BRU")
                    .articleNumber("3")
                    .articleTitle("Loyer et charges")
                    .articleContent("Le loyer mensuel est fixé au montant indiqué ci-dessus, payable le premier jour de chaque mois.")
                    .orderIndex(2)
                    .isMandatory(true)
                    .build();
            leaseContractArticleRepository.save(article3);

            log.info("Created standard lease contract articles for BE-BRU");
        }

        log.info("==================== OWNER/TENANT DATA INITIALIZED ====================");
        log.info("Test Owner: pierre.dupont@owner.com / owner123");
        log.info("Test Tenant: marie.martin@tenant.com / tenant123");
        log.info("Lease Contract created for apartment 101 (DRAFT status)");
        log.info("4 rooms created for apartment 101");
    }

}